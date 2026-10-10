import json
from datetime import datetime, timedelta
from typing import Any
from zoneinfo import ZoneInfo

from sqlalchemy import select, text
from sqlalchemy.ext.asyncio import AsyncSession

from api.app.core.clock import Clock
from api.app.domain.state_machine import transition
from api.app.eta.engine import LiveAdjustedEngine
from api.app.eta.loader import load_queue_snapshot
from api.app.models.entities import (
    Device,
    NotificationOutbox,
    Office,
    OfficeSettings,
    QueueState,
    Token,
)
from api.app.notifications.templates import render_notification


async def enqueue_notification(
    session: AsyncSession,
    token_id: str,
    user_id: str | None,
    kind: str,
    payload: dict[str, Any],
    dedupe_key: str,
    now: datetime,
) -> None:
    """Atomic notification enqueuing with ON CONFLICT DO NOTHING on dedupe_key."""
    await session.execute(
        text("""
        INSERT INTO notification_outbox (token_id, user_id, kind, payload, dedupe_key, status, attempts, send_after, created_at)
        VALUES (:token_id, :user_id, :kind, :payload, :dedupe_key, 'PENDING', 0, :now, :now)
        ON CONFLICT (dedupe_key) DO NOTHING;
        """),
        {
            "token_id": token_id,
            "user_id": user_id,
            "kind": kind,
            "payload": json.dumps(payload),
            "dedupe_key": dedupe_key,
            "now": now,
        },
    )


async def run_tick(
    session: AsyncSession,
    clock: Clock,
) -> dict[str, Any]:
    """
    Scheduler Tick (POST /internal/tick) — Spec Section 6.6.
    Runs sweeps in one transaction guarded by a Postgres advisory xact lock.
    """
    now = clock.now()
    b_date = clock.business_date()

    # 0. Acquire Postgres advisory transaction lock (424242)
    res_lock = await session.execute(text("SELECT pg_try_advisory_xact_lock(424242)"))
    locked = res_lock.scalar()
    if not locked:
        return {"status": "SKIPPED", "reason": "LOCK_HELD"}

    stats: dict[str, Any] = {
        "status": "COMPLETED",
        "no_show_requeued": 0,
        "no_show_cancelled": 0,
        "expired": 0,
        "eta_evaluations": 0,
        "notifications_flushed": 0,
    }

    # 1. No-Show Sweep
    # CALLED tokens with grace_deadline <= now and no serving_started_at
    stmt_noshow = (
        select(Token)
        .where(
            Token.state == "CALLED",
            Token.grace_deadline <= now,
            Token.serving_started_at.is_(None),
        )
        .with_for_update(skip_locked=True)
    )
    res_noshow = await session.execute(stmt_noshow)
    noshow_tokens = list(res_noshow.scalars().all())

    for tok in noshow_tokens:
        stmt_set = select(OfficeSettings).where(OfficeSettings.office_id == tok.office_id)
        res_set = await session.execute(stmt_set)
        settings = res_set.scalar_one_or_none()
        max_requeues = settings.max_requeues if settings else 1
        requeue_offset = settings.requeue_offset if settings else 5

        # First transition: CALLED -> NO_SHOW
        await transition(
            token=tok,
            to_state="NO_SHOW",
            actor_type="SYSTEM",
            actor_id="system",
            session=session,
            clock=clock,
            meta={"reason_code": "GRACE_EXPIRED"},
        )

        if tok.requeue_count < max_requeues:
            # Requeue behind requeue_offset tokens
            tok.requeue_count += 1
            stmt_offset = (
                select(Token.sort_key)
                .where(
                    Token.office_id == tok.office_id,
                    Token.service_id == tok.service_id,
                    Token.business_date == tok.business_date,
                    Token.state == "WAITING",
                )
                .order_by(Token.sort_key.asc())
                .offset(requeue_offset)
                .limit(1)
            )
            res_offset = await session.execute(stmt_offset)
            offset_sort_key = res_offset.scalar_one_or_none()
            if offset_sort_key is not None:
                tok.sort_key = float(offset_sort_key) + 0.001
            else:
                tok.sort_key = clock.now_epoch() + 1.0

            # Second transition: NO_SHOW -> WAITING
            await transition(
                token=tok,
                to_state="WAITING",
                actor_type="SYSTEM",
                actor_id="system",
                session=session,
                clock=clock,
                meta={"reason_code": "AUTO_REQUEUE", "requeue_count": tok.requeue_count},
            )

            # Bump waiting count on queue_state
            stmt_qs = select(QueueState).where(
                QueueState.office_id == tok.office_id,
                QueueState.service_id == tok.service_id,
                QueueState.business_date == tok.business_date,
            ).with_for_update()
            res_qs = await session.execute(stmt_qs)
            qs = res_qs.scalar_one_or_none()
            if qs:
                qs.waiting_count += 1
                qs.version += 1

            dedupe_key = f"{tok.id}:REQUEUED:{tok.requeue_count}"
            await enqueue_notification(
                session=session,
                token_id=tok.id,
                user_id=tok.citizen_id,
                kind="REQUEUED",
                payload={"display_code": tok.display_code},
                dedupe_key=dedupe_key,
                now=now,
            )
            stats["no_show_requeued"] += 1
        else:
            # Requeue limit reached: NO_SHOW -> CANCELLED
            await transition(
                token=tok,
                to_state="CANCELLED",
                actor_type="SYSTEM",
                actor_id="system",
                session=session,
                clock=clock,
                meta={"reason_code": "REQUEUE_LIMIT_REACHED"},
            )
            dedupe_key = f"{tok.id}:CANCELLED_BY_SYSTEM"
            await enqueue_notification(
                session=session,
                token_id=tok.id,
                user_id=tok.citizen_id,
                kind="CANCELLED_BY_SYSTEM",
                payload={"display_code": tok.display_code},
                dedupe_key=dedupe_key,
                now=now,
            )
            stats["no_show_cancelled"] += 1

    # 2. Expiry Sweep
    # Offices past close_time + close_grace_minutes
    stmt_offices = select(Office, OfficeSettings).join(OfficeSettings, OfficeSettings.office_id == Office.id)
    res_offices = await session.execute(stmt_offices)

    for office, settings in res_offices.all():
        try:
            tz = ZoneInfo(office.timezone or "Asia/Kolkata")
        except Exception:
            tz = ZoneInfo("Asia/Kolkata")
        now_in_office_tz = now.astimezone(tz)
        office_b_date = now_in_office_tz.date()

        office_close_dt = datetime.combine(office_b_date, office.close_time, tzinfo=tz)
        cutoff_dt = office_close_dt + timedelta(minutes=settings.close_grace_minutes)

        if now_in_office_tz > cutoff_dt:
            stmt_expired = (
                select(Token)
                .where(
                    Token.office_id == office.id,
                    Token.business_date <= office_b_date,
                    Token.state == "WAITING",
                )
                .with_for_update(skip_locked=True)
            )
            res_expired = await session.execute(stmt_expired)
            for exp_tok in res_expired.scalars().all():
                await transition(
                    token=exp_tok,
                    to_state="EXPIRED",
                    actor_type="SYSTEM",
                    actor_id="system",
                    session=session,
                    clock=clock,
                    meta={"reason_code": "OFFICE_CLOSED"},
                )
                dedupe_key = f"{exp_tok.id}:EXPIRED"
                await enqueue_notification(
                    session=session,
                    token_id=exp_tok.id,
                    user_id=exp_tok.citizen_id,
                    kind="EXPIRED",
                    payload={"display_code": exp_tok.display_code},
                    dedupe_key=dedupe_key,
                    now=now,
                )
                stats["expired"] += 1

    # 3. ETA Pass & Notification Ladder
    stmt_active_queues = select(QueueState).where(
        QueueState.business_date == b_date,
        QueueState.waiting_count > 0,
    )
    res_active_queues = await session.execute(stmt_active_queues)
    active_queues = list(res_active_queues.scalars().all())

    engine = LiveAdjustedEngine()

    for qs in active_queues:
        snapshot = await load_queue_snapshot(session, clock, qs.office_id, qs.service_id)
        etas = engine.compute_etas(snapshot)

        token_ids = list(etas.keys())
        if not token_ids:
            continue

        stmt_tokens = select(Token).where(Token.id.in_(token_ids)).with_for_update(skip_locked=True)
        res_tokens = await session.execute(stmt_tokens)
        tokens_map = {t.id: t for t in res_tokens.scalars().all()}

        for tok_id, eta in etas.items():
            waiting_tok = tokens_map.get(tok_id)
            if not waiting_tok:
                continue

            prev_eta = waiting_tok.last_eta_minutes
            waiting_tok.last_eta_minutes = int(eta.p50_minutes)
            waiting_tok.last_eta_reason = eta.reason
            existing_meta = dict(waiting_tok.eta_features or {})
            existing_meta["low"] = eta.low_minutes
            existing_meta["high"] = eta.high_minutes
            existing_meta["reason"] = eta.reason
            waiting_tok.eta_features = existing_meta
            stats["eta_evaluations"] += 1

            # A. GET_READY: p50 <= 15 min
            if eta.p50_minutes <= 15.0:
                await enqueue_notification(
                    session=session,
                    token_id=waiting_tok.id,
                    user_id=waiting_tok.citizen_id,
                    kind="GET_READY",
                    payload={"display_code": waiting_tok.display_code, "wait_minutes": int(eta.p50_minutes)},
                    dedupe_key=f"{waiting_tok.id}:GET_READY",
                    now=now,
                )

            # B. LEAVE_NOW: now >= leave_at (leave_at = eta - travel_minutes - 5)
            leave_at_minutes = eta.p50_minutes - waiting_tok.travel_minutes - 5
            if leave_at_minutes <= 0.0:
                await enqueue_notification(
                    session=session,
                    token_id=waiting_tok.id,
                    user_id=waiting_tok.citizen_id,
                    kind="LEAVE_NOW",
                    payload={"display_code": waiting_tok.display_code, "wait_minutes": int(eta.p50_minutes)},
                    dedupe_key=f"{waiting_tok.id}:LEAVE_NOW",
                    now=now,
                )

            # C. ETA_CHANGED: |Δ| >= max(10, 0.25 * old_eta), max one per 10m
            if prev_eta is not None and prev_eta > 0:
                delta = abs(int(eta.p50_minutes) - prev_eta)
                threshold = max(10, int(0.25 * prev_eta))
                if delta >= threshold:
                    bucket = int(clock.now_epoch() // 600)
                    await enqueue_notification(
                        session=session,
                        token_id=waiting_tok.id,
                        user_id=waiting_tok.citizen_id,
                        kind="ETA_CHANGED",
                        payload={"display_code": waiting_tok.display_code, "wait_minutes": int(eta.p50_minutes)},
                        dedupe_key=f"{waiting_tok.id}:ETA_CHANGED:{bucket}",
                        now=now,
                    )

    # D. NO_SHOW_WARNING: CALLED tokens where grace_deadline - now <= 2 minutes and > now
    stmt_warning = (
        select(Token)
        .where(
            Token.state == "CALLED",
            Token.grace_deadline > now,
            Token.grace_deadline <= now + timedelta(minutes=2),
            Token.serving_started_at.is_(None),
        )
        .with_for_update(skip_locked=True)
    )
    res_warning = await session.execute(stmt_warning)
    for tok in res_warning.scalars().all():
        await enqueue_notification(
            session=session,
            token_id=tok.id,
            user_id=tok.citizen_id,
            kind="NO_SHOW_WARNING",
            payload={"display_code": tok.display_code},
            dedupe_key=f"{tok.id}:NO_SHOW_WARNING",
            now=now,
        )

    # 4. Flush Outbox (simulate FCM sender delivery)
    stmt_outbox = (
        select(NotificationOutbox)
        .where(
            NotificationOutbox.status == "PENDING",
            NotificationOutbox.send_after <= now,
        )
        .order_by(NotificationOutbox.created_at.asc())
        .limit(50)
        .with_for_update(skip_locked=True)
    )
    res_outbox = await session.execute(stmt_outbox)
    outbox_items = list(res_outbox.scalars().all())

    for item in outbox_items:
        user_lang = "en"
        if item.user_id:
            stmt_dev = select(Device.language).where(Device.user_id == item.user_id).limit(1)
            res_dev = await session.execute(stmt_dev)
            lang_res = res_dev.scalar_one_or_none()
            if lang_res:
                user_lang = lang_res

        # Render message text from localized server templates
        payload_dict = item.payload if isinstance(item.payload, dict) else {}
        _ = render_notification(
            kind=item.kind,
            language=user_lang,
            display_code=payload_dict.get("display_code", ""),
            wait_minutes=payload_dict.get("wait_minutes", 0),
            counter_label=payload_dict.get("counter_label", "1"),
        )
        # Mark as SENT
        item.status = "SENT"
        item.attempts += 1
        stats["notifications_flushed"] += 1

    return stats
