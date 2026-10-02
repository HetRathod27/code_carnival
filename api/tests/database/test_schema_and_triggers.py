import asyncio
from datetime import date

import pytest
from sqlalchemy import text
from sqlalchemy.exc import DBAPIError
from sqlalchemy.ext.asyncio import create_async_engine

from api.app.core.config import settings
from api.app.core.safety import assert_test_database

# Safety check: enforce test database name
assert_test_database(settings.TEST_DATABASE_URL)


@pytest.fixture
def test_engine():
    engine = create_async_engine(settings.TEST_DATABASE_URL, echo=False)
    yield engine
    # sync cleanup via loop or dispose
    asyncio.run(engine.dispose())


@pytest.mark.asyncio
async def test_append_only_token_events(test_engine):
    """Proves token_events trigger strictly refuses UPDATE and DELETE."""
    async with test_engine.connect() as conn:
        # Create a test token first
        token_id = "test-tok-events-01"
        await conn.execute(text(f"""
            INSERT INTO tokens (id, office_id, service_id, business_date, seq, display_code, sort_key, state)
            VALUES ('{token_id}', 'ward-central-01', 'srv-bc', CURRENT_DATE, 9999, 'BC-9999', 1.0, 'WAITING')
            ON CONFLICT (id) DO NOTHING;
        """))

        # Insert a token event
        result = await conn.execute(text(f"""
            INSERT INTO token_events (token_id, from_state, to_state, actor_type, meta)
            VALUES ('{token_id}', NULL, 'WAITING', 'CITIZEN', '{{}}')
            RETURNING id;
        """))
        event_id = result.scalar_one()
        await conn.commit()

        # Attempt to UPDATE token_events -> must fail
        with pytest.raises(DBAPIError) as exc_info:
            await conn.execute(text(f"UPDATE token_events SET to_state='CALLED' WHERE id={event_id}"))
            await conn.commit()
        assert "token_events is append-only" in str(exc_info.value)
        await conn.rollback()

        # Attempt to DELETE token_events -> must fail
        with pytest.raises(DBAPIError) as exc_info:
            await conn.execute(text(f"DELETE FROM token_events WHERE id={event_id}"))
            await conn.commit()
        assert "token_events is append-only" in str(exc_info.value)
        await conn.rollback()


@pytest.mark.asyncio
async def test_state_transition_matrix(test_engine):
    """
    Proves the 8x8 state transition matrix at the DB trigger level.
    Only the spec allowed moves succeed; all other 56 moves are rejected.
    """
    states = [
        'WAITING', 'CALLED', 'SERVING', 'COMPLETED',
        'CANCELLED', 'EXPIRED', 'NO_SHOW', 'TRANSFERRED'
    ]

    # Transitions allowed per spec Section 5
    allowed = {
        ('WAITING', 'CALLED'),
        ('CALLED', 'SERVING'),
        ('SERVING', 'COMPLETED'),
        ('WAITING', 'CANCELLED'),
        ('CALLED', 'CANCELLED'),
        ('WAITING', 'EXPIRED'),
        ('CALLED', 'NO_SHOW'),
        ('NO_SHOW', 'WAITING'),
        ('NO_SHOW', 'CANCELLED'),
        ('CALLED', 'WAITING'),
        ('CALLED', 'TRANSFERRED'),
        ('SERVING', 'TRANSFERRED'),
    }

    async with test_engine.connect() as conn:
        for from_s in states:
            for to_s in states:
                if from_s == to_s:
                    continue

                tok_id = f"tok-{from_s}-{to_s}".lower()
                # Ensure clean state for this test token
                await conn.execute(text(f"DELETE FROM tokens WHERE id='{tok_id}'"))
                await conn.commit()

                # Create fresh token in from_state via insert (allowed by trigger)
                await conn.execute(text(f"""
                    INSERT INTO tokens (id, office_id, service_id, business_date, seq, display_code, sort_key, state)
                    VALUES ('{tok_id}', 'ward-central-01', 'srv-bc', CURRENT_DATE, (SELECT COALESCE(MAX(seq), 0) + 1 FROM tokens), 'T-00', 1.0, '{from_s}');
                """))
                await conn.commit()

                if (from_s, to_s) in allowed:
                    # Must succeed
                    await conn.execute(text(f"UPDATE tokens SET state='{to_s}' WHERE id='{tok_id}'"))
                    await conn.commit()
                else:
                    # Must fail with invalid transition exception
                    with pytest.raises(DBAPIError) as exc_info:
                        await conn.execute(text(f"UPDATE tokens SET state='{to_s}' WHERE id='{tok_id}'"))
                        await conn.commit()
                    assert "Invalid token state transition" in str(exc_info.value)
                    await conn.rollback()


@pytest.mark.asyncio
async def test_parallel_50_transactions_numbering(test_engine):
    """
    Proves that 50 concurrent transactions incrementing last_seq on queue_state
    yield unique, gapless sequences without race conditions.
    """
    b_date = date.today()
    service_id = "srv-bc"
    office_id = "ward-central-01"

    # Reset or ensure queue_state row
    async with test_engine.connect() as conn:
        await conn.execute(text(f"""
            INSERT INTO queue_state (office_id, service_id, business_date, last_seq, waiting_count, version)
            VALUES ('{office_id}', '{service_id}', '{b_date}', 0, 0, 1)
            ON CONFLICT (office_id, service_id, business_date)
            DO UPDATE SET last_seq = 0, version = 1;
        """))
        await conn.commit()

    async def book_worker(worker_id: int):
        async with test_engine.connect() as conn:
            # Atomic booking pattern per spec 6.4
            async with conn.begin():
                row = await conn.execute(text(f"""
                    SELECT last_seq FROM queue_state
                    WHERE office_id='{office_id}' AND service_id='{service_id}' AND business_date='{b_date}'
                    FOR UPDATE;
                """))
                last_seq = row.scalar_one()
                new_seq = last_seq + 1
                await conn.execute(text(f"""
                    UPDATE queue_state
                    SET last_seq = {new_seq}, waiting_count = waiting_count + 1, version = version + 1
                    WHERE office_id='{office_id}' AND service_id='{service_id}' AND business_date='{b_date}';
                """))
                return new_seq

    results = await asyncio.gather(*(book_worker(i) for i in range(50)))
    seqs = sorted(results)

    # Must be 50 unique numbers from 1 to 50
    assert len(seqs) == 50
    assert len(set(seqs)) == 50
    assert seqs == list(range(1, 51))
