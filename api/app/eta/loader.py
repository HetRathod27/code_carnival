from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from api.app.core.clock import Clock
from api.app.eta.models import (
    CounterInfo,
    QueueSnapshot,
    ServiceInfo,
    ServingToken,
    WaitingToken,
)
from api.app.models.entities import (
    Counter,
    CounterService,
    OfficeSettings,
    QueueState,
    Service,
    ServiceStats,
    Token,
)


async def load_queue_snapshot(
    session: AsyncSession,
    clock: Clock,
    office_id: str,
    service_id: str,
) -> QueueSnapshot:
    """
    Loads database state into a pure QueueSnapshot dataclass for ETA computation.
    """
    now = clock.now()
    b_date = clock.business_date()

    # 1. Service info
    stmt_svc = select(Service).where(Service.id == service_id, Service.office_id == office_id)
    res_svc = await session.execute(stmt_svc)
    service = res_svc.scalar_one_or_none()
    if not service:
        svc_info = ServiceInfo(
            id=service_id,
            code="UNK",
            prior_avg_minutes=10.0,
            ewma_mean=10.0,
            ewma_var=0.0,
        )
    else:
        # Check service_stats for current hour
        current_hour = now.hour
        stmt_stats = select(ServiceStats).where(
            ServiceStats.service_id == service_id,
            ServiceStats.hour_bucket == current_hour,
        )
        res_stats = await session.execute(stmt_stats)
        stats = res_stats.scalar_one_or_none()
        ewma_mean = stats.ewma_minutes if stats and stats.n > 0 else service.prior_avg_minutes
        ewma_var = stats.ewma_var if stats else 0.0

        svc_info = ServiceInfo(
            id=service.id,
            code=service.code,
            prior_avg_minutes=float(service.prior_avg_minutes),
            ewma_mean=float(ewma_mean),
            ewma_var=float(ewma_var),
        )

    # 2. Counters serving this service
    stmt_counters = (
        select(Counter)
        .join(CounterService, CounterService.counter_id == Counter.id)
        .where(
            Counter.office_id == office_id,
            CounterService.service_id == service_id,
        )
    )
    res_counters = await session.execute(stmt_counters)
    counters = list(res_counters.scalars().all())

    # Fallback if no explicit counter_services mapping
    if not counters:
        stmt_all_counters = select(Counter).where(Counter.office_id == office_id)
        res_all_counters = await session.execute(stmt_all_counters)
        counters = list(res_all_counters.scalars().all())

    # 3. Serving tokens
    stmt_serving = select(Token).where(
        Token.office_id == office_id,
        Token.service_id == service_id,
        Token.business_date == b_date,
        Token.state == "SERVING",
    )
    res_serving = await session.execute(stmt_serving)
    serving_tokens_db = list(res_serving.scalars().all())

    serving_by_counter: dict[str, str] = {}
    serving_list: list[ServingToken] = []
    for st in serving_tokens_db:
        if st.counter_id:
            serving_by_counter[st.counter_id] = st.id
            start_time = st.serving_started_at or st.called_at or st.created_at
            elapsed = max(0.0, (now - start_time).total_seconds() / 60.0)
            serving_list.append(
                ServingToken(
                    token_id=st.id,
                    counter_id=st.counter_id,
                    started_at=start_time,
                    elapsed_minutes=elapsed,
                )
            )

    counter_info_list = [
        CounterInfo(
            id=c.id,
            status=c.status,
            current_serving_token_id=serving_by_counter.get(c.id),
        )
        for c in counters
    ]

    # 4. Waiting tokens
    stmt_waiting = (
        select(Token)
        .where(
            Token.office_id == office_id,
            Token.service_id == service_id,
            Token.business_date == b_date,
            Token.state == "WAITING",
        )
        .order_by(Token.sort_key.asc())
    )
    res_waiting = await session.execute(stmt_waiting)
    waiting_tokens_db = list(res_waiting.scalars().all())

    waiting_list = [
        WaitingToken(
            id=wt.id,
            category=wt.category,
            sort_key=float(wt.sort_key),
            arrived_at=wt.arrived_at,
            pass_over_count=wt.pass_over_count,
        )
        for wt in waiting_tokens_db
    ]

    # 5. Queue state & office settings
    stmt_qs = select(QueueState).where(
        QueueState.office_id == office_id,
        QueueState.service_id == service_id,
        QueueState.business_date == b_date,
    )
    res_qs = await session.execute(stmt_qs)
    qs = res_qs.scalar_one_or_none()
    calls_since_priority = qs.calls_since_priority if qs else 0

    stmt_set = select(OfficeSettings).where(OfficeSettings.office_id == office_id)
    res_set = await session.execute(stmt_set)
    settings = res_set.scalar_one_or_none()
    priority_every_n = settings.priority_every_n if settings else 3
    dispatch_window = settings.dispatch_window if settings else 3
    max_pass_overs = settings.max_pass_overs if settings else 2

    return QueueSnapshot(
        now=now,
        service=svc_info,
        counters=counter_info_list,
        serving_tokens=serving_list,
        waiting_tokens=waiting_list,
        calls_since_priority=calls_since_priority,
        priority_every_n=priority_every_n,
        dispatch_window=dispatch_window,
        max_pass_overs=max_pass_overs,
    )
