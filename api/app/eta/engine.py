import abc
import heapq
from datetime import timedelta

from api.app.eta.models import EtaResult, QueueSnapshot, WaitingToken


class ETAEngine(abc.ABC):
    @abc.abstractmethod
    def compute_etas(self, snapshot: QueueSnapshot) -> dict[str, EtaResult]:
        """
        Pure function computing ETAs for all waiting tokens in snapshot.
        Core Rule 5: Pure function. No DB or network calls inside it.
        """
        raise NotImplementedError


class NaiveEngine(ETAEngine):
    """
    Naive baseline engine:
    ETA = (tokens_ahead * mean_service_time) / open_counters
    Used for benchmarking, fallback, and comparative evaluation.
    """

    def compute_etas(self, snapshot: QueueSnapshot) -> dict[str, EtaResult]:
        open_counters = sum(1 for c in snapshot.counters if c.status == "OPEN")
        mean = snapshot.service.ewma_mean if snapshot.service.ewma_mean > 0 else snapshot.service.prior_avg_minutes

        results: dict[str, EtaResult] = {}
        for idx, token in enumerate(snapshot.waiting_tokens):
            if open_counters == 0:
                p50 = 999.0
                reason = "COUNTER_DOWN"
            else:
                p50 = round(float(idx * mean) / float(open_counters), 1)
                reason = None

            low = round(max(0.0, p50 * 0.8), 1)
            high = round(p50 * 1.2, 1)
            predicted_start = snapshot.now + timedelta(minutes=p50)

            results[token.id] = EtaResult(
                token_id=token.id,
                p50_minutes=p50,
                low_minutes=low,
                high_minutes=high,
                reason=reason,
                engine="naive",
                predicted_start_time=predicted_start,
            )
        return results


class LiveAdjustedEngine(ETAEngine):
    """
    Live-adjusted greedy schedule engine (P0 default):
    - Models each counter availability incorporating Section 19.3 overrun rule:
        remaining_i = max(mean - elapsed, 1 min) while elapsed <= mean
        remaining_i = 0.5 * mean when elapsed > mean
        emits SLOW_CASE when in-service token exceeds 1.5 * mean
    - Simulates dispatch order taking priority interleaving into account.
    - Greedily schedules tokens on earliest-free counter.
    """

    def compute_etas(self, snapshot: QueueSnapshot) -> dict[str, EtaResult]:
        open_counters = [c for c in snapshot.counters if c.status == "OPEN"]
        mean = snapshot.service.ewma_mean if snapshot.service.ewma_mean > 0 else snapshot.service.prior_avg_minutes

        # If no counters are open: queue is paused, reason COUNTER_DOWN
        if not open_counters:
            results: dict[str, EtaResult] = {}
            for token in snapshot.waiting_tokens:
                results[token.id] = EtaResult(
                    token_id=token.id,
                    p50_minutes=999.0,
                    low_minutes=999.0,
                    high_minutes=999.0,
                    reason="COUNTER_DOWN",
                    engine="live_adjusted",
                    predicted_start_time=snapshot.now + timedelta(minutes=999.0),
                )
            return results

        # 1. Determine counter free times (in minutes from snapshot.now)
        has_slow_case = False
        serving_by_counter = {st.counter_id: st for st in snapshot.serving_tokens}

        counter_free_times: list[float] = []
        for c in open_counters:
            if c.id in serving_by_counter:
                st = serving_by_counter[c.id]
                elapsed = max(0.0, st.elapsed_minutes)
                if elapsed > 1.5 * mean:
                    has_slow_case = True

                # Spec Section 19.3 Overrun Rule
                if elapsed <= mean:
                    rem = max(mean - elapsed, 1.0)
                else:
                    rem = 0.5 * mean
                counter_free_times.append(rem)
            else:
                # Open counter not currently serving is immediately available
                counter_free_times.append(0.0)

        # Min-heap of counter availability times
        heapq.heapify(counter_free_times)

        # 2. Simulate dispatch ordering of waiting tokens
        # Partition into priority and normal
        dispatch_order = self._simulate_dispatch_order(
            waiting_tokens=snapshot.waiting_tokens,
            calls_since_priority=snapshot.calls_since_priority,
            priority_every_n=snapshot.priority_every_n,
            dispatch_window=snapshot.dispatch_window,
            max_pass_overs=snapshot.max_pass_overs,
        )

        # 3. Greedy schedule assignment
        results = {}
        for token in dispatch_order:
            earliest_free = heapq.heappop(counter_free_times)
            p50 = round(earliest_free, 1)
            low = round(max(0.0, p50 * 0.8), 1)
            high = round(p50 * 1.2, 1)

            reason = "SLOW_CASE" if has_slow_case else None
            predicted_start = snapshot.now + timedelta(minutes=p50)

            results[token.id] = EtaResult(
                token_id=token.id,
                p50_minutes=p50,
                low_minutes=low,
                high_minutes=high,
                reason=reason,
                engine="live_adjusted",
                predicted_start_time=predicted_start,
            )

            # Counter serves this token and becomes free again after 'mean' minutes
            heapq.heappush(counter_free_times, earliest_free + mean)

        return results

    def _simulate_dispatch_order(
        self,
        waiting_tokens: list[WaitingToken],
        calls_since_priority: int,
        priority_every_n: int,
        dispatch_window: int,
        max_pass_overs: int,
    ) -> list[WaitingToken]:
        """
        Pure simulation of the dispatch order matching Section 6.5 & Section 19.2.
        """
        remaining = list(waiting_tokens)
        ordered: list[WaitingToken] = []
        curr_calls_since_p = calls_since_priority

        while remaining:
            # 1. Determine pool: PRIORITY or NORMAL
            has_priority = any(t.category == "PRIORITY" for t in remaining)
            has_normal = any(t.category == "NORMAL" for t in remaining)

            is_priority_turn = (curr_calls_since_p >= priority_every_n - 1 and has_priority) or (not has_normal and has_priority)
            chosen_category = "PRIORITY" if is_priority_turn else "NORMAL"

            pool = [t for t in remaining if t.category == chosen_category]
            if not pool:
                pool = remaining

            # 2. Arrived-first dispatch within dispatch_window
            candidates = pool[:dispatch_window]
            chosen: WaitingToken | None = None

            # Look for arrived token or token that reached max_pass_overs
            for cand in candidates:
                if cand.pass_over_count >= max_pass_overs or cand.arrived_at is not None:
                    chosen = cand
                    break

            if not chosen:
                chosen = candidates[0]

            ordered.append(chosen)
            remaining.remove(chosen)

            if chosen.category == "PRIORITY":
                curr_calls_since_p = 0
            else:
                curr_calls_since_p += 1

        return ordered
