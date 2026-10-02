"""
Report service (Spec Section 10).
SQL aggregates over token_events / eta_log.
No business logic — pure read queries.
"""

from datetime import date
from typing import Any

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession


async def get_summary_report(
    session: AsyncSession,
    office_id: str,
    report_date: date,
) -> dict[str, Any]:
    """
    Summary report: tokens served / cancelled / expired / no-show,
    average and P90 wait, service time per service, priority share.
    Spec Section 10.
    """
    result = await session.execute(
        text("""
        SELECT
            t.service_id,
            COUNT(*) FILTER (WHERE t.state = 'COMPLETED')                          AS served,
            COUNT(*) FILTER (WHERE t.state = 'CANCELLED')                          AS cancelled,
            COUNT(*) FILTER (WHERE t.state = 'EXPIRED')                            AS expired,
            COUNT(*) FILTER (WHERE t.state = 'NO_SHOW')                            AS no_show,
            COUNT(*) FILTER (WHERE t.state = 'WAITING')                            AS waiting,
            ROUND(
                (AVG(EXTRACT(EPOCH FROM (t.completed_at - t.created_at)) / 60.0)
                 FILTER (WHERE t.state = 'COMPLETED')
                )::numeric,
                1
            )                                                                        AS avg_wait_minutes,
            ROUND(
                (PERCENTILE_CONT(0.9) WITHIN GROUP (
                    ORDER BY EXTRACT(EPOCH FROM (t.completed_at - t.created_at)) / 60.0
                ) FILTER (WHERE t.state = 'COMPLETED')
                )::numeric,
                1
            )                                                                        AS p90_wait_minutes,
            ROUND(
                (AVG(EXTRACT(EPOCH FROM (t.completed_at - t.serving_started_at)) / 60.0)
                 FILTER (WHERE t.state = 'COMPLETED')
                )::numeric,
                1
            )                                                                        AS avg_service_minutes,
            COUNT(*) FILTER (WHERE t.category = 'PRIORITY')                        AS priority_count,
            COUNT(*) FILTER (
                WHERE t.category = 'PRIORITY' AND t.priority_status = 'REJECTED'
            )                                                                        AS priority_rejected
        FROM tokens t
        WHERE t.office_id = :office_id
          AND t.business_date = :report_date
        GROUP BY t.service_id
        ORDER BY t.service_id
        """),
        {"office_id": office_id, "report_date": report_date},
    )
    rows = result.mappings().all()

    return {
        "office_id": office_id,
        "date": report_date.isoformat(),
        "services": [dict(row) for row in rows],
    }


async def get_load_by_hour(
    session: AsyncSession,
    office_id: str,
    report_date: date,
) -> dict[str, Any]:
    """
    Load-by-hour: tokens booked per hour bucket, for each service.
    Spec Section 10.
    """
    result = await session.execute(
        text("""
        SELECT
            t.service_id,
            DATE_TRUNC('hour', t.created_at AT TIME ZONE 'UTC')  AS hour_bucket,
            COUNT(*)                                               AS tokens_booked,
            COUNT(*) FILTER (WHERE t.state = 'COMPLETED')        AS tokens_served
        FROM tokens t
        WHERE t.office_id = :office_id
          AND t.business_date = :report_date
        GROUP BY t.service_id, hour_bucket
        ORDER BY t.service_id, hour_bucket
        """),
        {"office_id": office_id, "report_date": report_date},
    )
    rows = result.mappings().all()

    hourly: list[dict[str, Any]] = []
    for row in rows:
        hourly.append({
            "service_id": row["service_id"],
            "hour_bucket": row["hour_bucket"].isoformat() if row["hour_bucket"] else None,
            "tokens_booked": row["tokens_booked"],
            "tokens_served": row["tokens_served"],
        })

    return {
        "office_id": office_id,
        "date": report_date.isoformat(),
        "hourly": hourly,
    }


async def get_eta_accuracy(
    session: AsyncSession,
    office_id: str,
    report_date: date,
) -> dict[str, Any]:
    """
    ETA accuracy report: MAE, % within predicted range, vs naive.
    Spec Section 10: 'ETA accuracy panel (MAE, within-range %, vs naive)'.
    Uses eta_log (booking-time prediction) vs actual_wait (called_at - created_at).
    """
    result = await session.execute(
        text("""
        SELECT
            el.engine,
            COUNT(*)                                                              AS n,
            ROUND(
                AVG(ABS(
                    EXTRACT(EPOCH FROM (t.called_at - t.created_at)) / 60.0
                    - el.predicted_p50
                ))::numeric,
                2
            )                                                                     AS mae_minutes,
            ROUND(
                (100.0 * COUNT(*) FILTER (
                    WHERE
                        EXTRACT(EPOCH FROM (t.called_at - t.created_at)) / 60.0
                            BETWEEN el.low AND el.high
                ) / NULLIF(COUNT(*), 0))::numeric,
                1
            )                                                                     AS within_range_pct
        FROM eta_log el
        JOIN tokens t ON t.id = el.token_id
        WHERE t.office_id = :office_id
          AND t.business_date = :report_date
          AND t.called_at IS NOT NULL
        GROUP BY el.engine
        ORDER BY el.engine
        """),
        {"office_id": office_id, "report_date": report_date},
    )
    rows = result.mappings().all()

    # Also compute naive MAE for comparison
    naive_result = await session.execute(
        text("""
        SELECT
            ROUND(
                AVG(ABS(
                    EXTRACT(EPOCH FROM (t.called_at - t.created_at)) / 60.0
                    - el.naive_p50
                ))::numeric,
                2
            ) AS naive_mae
        FROM eta_log el
        JOIN tokens t ON t.id = el.token_id
        WHERE t.office_id = :office_id
          AND t.business_date = :report_date
          AND t.called_at IS NOT NULL
          AND el.engine = 'live_adjusted'
        """),
        {"office_id": office_id, "report_date": report_date},
    )
    naive_row = naive_result.mappings().first()
    naive_mae = float(naive_row["naive_mae"]) if naive_row and naive_row["naive_mae"] else None

    engines_data = [dict(row) for row in rows]

    return {
        "office_id": office_id,
        "date": report_date.isoformat(),
        "engines": engines_data,
        "naive_mae": naive_mae,
    }
