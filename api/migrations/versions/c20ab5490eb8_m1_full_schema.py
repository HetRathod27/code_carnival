"""m1_full_schema

Revision ID: c20ab5490eb8
Revises:
Create Date: 2026-10-02

Full schema per spec Section 4 + Section 19.5, triggers, enums,
constraints, allowed_transitions seed, and demo office seed.
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = 'c20ab5490eb8'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Enums
    token_state_enum = postgresql.ENUM(
        'WAITING', 'CALLED', 'SERVING', 'COMPLETED', 'CANCELLED', 'EXPIRED', 'NO_SHOW', 'TRANSFERRED',
        name='token_state_enum'
    )
    token_state_enum.create(op.get_bind(), checkfirst=True)

    category_enum = postgresql.ENUM('NORMAL', 'PRIORITY', name='category_enum')
    category_enum.create(op.get_bind(), checkfirst=True)

    priority_status_enum = postgresql.ENUM('PENDING', 'VERIFIED', 'REJECTED', name='priority_status_enum')
    priority_status_enum.create(op.get_bind(), checkfirst=True)

    counter_status_enum = postgresql.ENUM('OPEN', 'BREAK', 'CLOSED', name='counter_status_enum')
    counter_status_enum.create(op.get_bind(), checkfirst=True)

    actor_type_enum = postgresql.ENUM('CITIZEN', 'OFFICER', 'DESK', 'ADMIN', 'SYSTEM', name='actor_type_enum')
    actor_type_enum.create(op.get_bind(), checkfirst=True)

    outcome_code_enum = postgresql.ENUM(
        'SERVED', 'MISSING_DOCS', 'WRONG_SERVICE', 'WRONG_OFFICE', 'CITIZEN_LEFT', 'OTHER',
        name='outcome_code_enum'
    )
    outcome_code_enum.create(op.get_bind(), checkfirst=True)

    calendar_status_enum = postgresql.ENUM('CLOSED', 'CUSTOM_HOURS', name='calendar_status_enum')
    calendar_status_enum.create(op.get_bind(), checkfirst=True)

    # 2. Tables
    op.create_table(
        'offices',
        sa.Column('id', sa.String(64), primary_key=True),
        sa.Column('name', sa.String(255), nullable=False),
        sa.Column('address', sa.Text(), nullable=False),
        sa.Column('timezone', sa.String(64), nullable=False, server_default='Asia/Kolkata'),
        sa.Column('open_time', sa.Time(), nullable=False),
        sa.Column('close_time', sa.Time(), nullable=False),
        sa.Column('qr_secret', sa.String(255), nullable=False),
        sa.Column('is_simulation', sa.Boolean(), nullable=False, server_default=sa.text('false')),
        sa.Column('active', sa.Boolean(), nullable=False, server_default=sa.text('true')),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )

    op.create_table(
        'office_settings',
        sa.Column('office_id', sa.String(64), sa.ForeignKey('offices.id', ondelete='CASCADE'), primary_key=True),
        sa.Column('grace_minutes', sa.Integer(), nullable=False, server_default='5'),
        sa.Column('priority_every_n', sa.Integer(), nullable=False, server_default='3'),
        sa.Column('requeue_offset', sa.Integer(), nullable=False, server_default='5'),
        sa.Column('max_requeues', sa.Integer(), nullable=False, server_default='1'),
        sa.Column('close_grace_minutes', sa.Integer(), nullable=False, server_default='15'),
        sa.Column('max_active_tokens_per_phone', sa.Integer(), nullable=False, server_default='1'),
        sa.Column('strike_limit', sa.Integer(), nullable=False, server_default='3'),
        sa.Column('dispatch_window', sa.Integer(), nullable=False, server_default='3'),
        sa.Column('max_pass_overs', sa.Integer(), nullable=False, server_default='2'),
        sa.Column('max_waiting_per_service', sa.Integer(), nullable=False, server_default='100'),
        sa.Column('max_on_behalf_tokens', sa.Integer(), nullable=False, server_default='3'),
        sa.Column('on_my_way_extension_minutes', sa.Integer(), nullable=False, server_default='5'),
        sa.Column('retention_days', sa.Integer(), nullable=False, server_default='90'),
    )

    op.create_table(
        'services',
        sa.Column('id', sa.String(64), primary_key=True),
        sa.Column('office_id', sa.String(64), sa.ForeignKey('offices.id', ondelete='CASCADE'), nullable=False),
        sa.Column('code', sa.String(16), nullable=False),
        sa.Column('names', postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column('prior_avg_minutes', sa.Float(), nullable=False),
        sa.Column('required_docs', postgresql.JSONB(astext_type=sa.Text()), nullable=False, server_default='[]'),
        sa.Column('priority_allowed', sa.Boolean(), nullable=False, server_default=sa.text('true')),
        sa.Column('active', sa.Boolean(), nullable=False, server_default=sa.text('true')),
        sa.Column('requires_physical_visit', sa.Boolean(), nullable=False, server_default=sa.text('true')),
        sa.Column('online_alternative_url', sa.String(512), nullable=True),
        sa.Column('location_hint', postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.UniqueConstraint('office_id', 'code', name='uq_service_office_code'),
    )

    op.create_table(
        'counters',
        sa.Column('id', sa.String(64), primary_key=True),
        sa.Column('office_id', sa.String(64), sa.ForeignKey('offices.id', ondelete='CASCADE'), nullable=False),
        sa.Column('label', sa.String(64), nullable=False),
        sa.Column('status', sa.Enum('OPEN', 'BREAK', 'CLOSED', name='counter_status_enum', create_type=False), nullable=False, server_default='CLOSED'),
        sa.Column('officer_id', sa.String(64), nullable=True),
    )

    op.create_table(
        'counter_services',
        sa.Column('counter_id', sa.String(64), sa.ForeignKey('counters.id', ondelete='CASCADE'), primary_key=True),
        sa.Column('service_id', sa.String(64), sa.ForeignKey('services.id', ondelete='CASCADE'), primary_key=True),
    )

    op.create_table(
        'profiles',
        sa.Column('id', sa.String(64), primary_key=True),
        sa.Column('role', sa.Enum('CITIZEN', 'OFFICER', 'DESK', 'ADMIN', 'SYSTEM', name='actor_type_enum', create_type=False), nullable=False, server_default='CITIZEN'),
        sa.Column('office_id', sa.String(64), sa.ForeignKey('offices.id', ondelete='SET NULL'), nullable=True),
        sa.Column('phone', sa.String(32), nullable=True),
        sa.Column('name', sa.String(255), nullable=True),
        sa.Column('language', sa.String(8), nullable=False, server_default='en'),
        sa.Column('priority_strikes', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('priority_blocked_until', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )

    op.create_table(
        'queue_state',
        sa.Column('office_id', sa.String(64), sa.ForeignKey('offices.id', ondelete='CASCADE'), nullable=False),
        sa.Column('service_id', sa.String(64), sa.ForeignKey('services.id', ondelete='CASCADE'), nullable=False),
        sa.Column('business_date', sa.Date(), nullable=False),
        sa.Column('last_seq', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('calls_since_priority', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('now_serving', sa.String(32), nullable=True),
        sa.Column('waiting_count', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('paused', sa.Boolean(), nullable=False, server_default=sa.text('false')),
        sa.Column('version', sa.BigInteger(), nullable=False, server_default='1'),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.PrimaryKeyConstraint('office_id', 'service_id', 'business_date', name='pk_queue_state'),
    )

    op.create_table(
        'tokens',
        sa.Column('id', sa.String(64), primary_key=True),
        sa.Column('office_id', sa.String(64), sa.ForeignKey('offices.id', ondelete='CASCADE'), nullable=False),
        sa.Column('service_id', sa.String(64), sa.ForeignKey('services.id', ondelete='CASCADE'), nullable=False),
        sa.Column('business_date', sa.Date(), nullable=False),
        sa.Column('seq', sa.Integer(), nullable=False),
        sa.Column('display_code', sa.String(32), nullable=False),
        sa.Column('citizen_id', sa.String(64), nullable=True),
        sa.Column('phone', sa.String(32), nullable=True),
        sa.Column('beneficiary_name', sa.String(255), nullable=True),
        sa.Column('beneficiary_key', sa.String(255), nullable=True),
        sa.Column('category', sa.Enum('NORMAL', 'PRIORITY', name='category_enum', create_type=False), nullable=False, server_default='NORMAL'),
        sa.Column('priority_status', sa.Enum('PENDING', 'VERIFIED', 'REJECTED', name='priority_status_enum', create_type=False), nullable=False, server_default='PENDING'),
        sa.Column('created_via', sa.String(32), nullable=False, server_default='APP'),
        sa.Column('state', sa.Enum('WAITING', 'CALLED', 'SERVING', 'COMPLETED', 'CANCELLED', 'EXPIRED', 'NO_SHOW', 'TRANSFERRED', name='token_state_enum', create_type=False), nullable=False, server_default='WAITING'),
        sa.Column('sort_key', sa.Numeric(precision=18, scale=6), nullable=False),
        sa.Column('travel_minutes', sa.Integer(), nullable=False, server_default='15'),
        sa.Column('counter_id', sa.String(64), sa.ForeignKey('counters.id', ondelete='SET NULL'), nullable=True),
        sa.Column('pass_over_count', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('outcome_code', sa.Enum('SERVED', 'MISSING_DOCS', 'WRONG_SERVICE', 'WRONG_OFFICE', 'CITIZEN_LEFT', 'OTHER', name='outcome_code_enum', create_type=False), nullable=True),
        sa.Column('arrived_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('on_my_way_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('called_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('grace_deadline', sa.DateTime(timezone=True), nullable=True),
        sa.Column('serving_started_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('completed_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('requeue_count', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('parent_token_id', sa.String(64), nullable=True),
        sa.Column('last_eta_minutes', sa.Integer(), nullable=True),
        sa.Column('last_eta_reason', sa.String(64), nullable=True),
        sa.Column('eta_features', postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.UniqueConstraint('office_id', 'service_id', 'business_date', 'seq', name='uq_tokens_office_service_date_seq'),
    )

    # Partial unique index per spec: one active token per phone per service
    op.create_index(
        'idx_tokens_phone_service_active',
        'tokens',
        ['phone', 'service_id'],
        unique=True,
        postgresql_where=sa.text("state IN ('WAITING', 'CALLED', 'SERVING') AND phone IS NOT NULL")
    )

    # Index for fast next waiting queries: (office_id, service_id, business_date, state, sort_key)
    op.create_index(
        'idx_tokens_next_waiting',
        'tokens',
        ['office_id', 'service_id', 'business_date', 'state', 'sort_key']
    )

    op.create_table(
        'token_events',
        sa.Column('id', sa.BigInteger(), sa.Identity(always=False), primary_key=True),
        sa.Column('token_id', sa.String(64), sa.ForeignKey('tokens.id', ondelete='CASCADE'), nullable=False),
        sa.Column('from_state', sa.Enum('WAITING', 'CALLED', 'SERVING', 'COMPLETED', 'CANCELLED', 'EXPIRED', 'NO_SHOW', 'TRANSFERRED', name='token_state_enum', create_type=False), nullable=True),
        sa.Column('to_state', sa.Enum('WAITING', 'CALLED', 'SERVING', 'COMPLETED', 'CANCELLED', 'EXPIRED', 'NO_SHOW', 'TRANSFERRED', name='token_state_enum', create_type=False), nullable=False),
        sa.Column('actor_type', sa.Enum('CITIZEN', 'OFFICER', 'DESK', 'ADMIN', 'SYSTEM', name='actor_type_enum', create_type=False), nullable=False),
        sa.Column('actor_id', sa.String(64), nullable=True),
        sa.Column('counter_id', sa.String(64), nullable=True),
        sa.Column('at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column('meta', postgresql.JSONB(astext_type=sa.Text()), nullable=False, server_default='{}'),
    )

    op.create_table(
        'allowed_transitions',
        sa.Column('from_state', sa.Enum('WAITING', 'CALLED', 'SERVING', 'COMPLETED', 'CANCELLED', 'EXPIRED', 'NO_SHOW', 'TRANSFERRED', name='token_state_enum', create_type=False), nullable=True),
        sa.Column('to_state', sa.Enum('WAITING', 'CALLED', 'SERVING', 'COMPLETED', 'CANCELLED', 'EXPIRED', 'NO_SHOW', 'TRANSFERRED', name='token_state_enum', create_type=False), nullable=False),
        sa.Column('actor_type', sa.Enum('CITIZEN', 'OFFICER', 'DESK', 'ADMIN', 'SYSTEM', name='actor_type_enum', create_type=False), nullable=False),
    )
    op.create_index('idx_allowed_transitions', 'allowed_transitions', ['from_state', 'to_state', 'actor_type'], unique=True)

    op.create_table(
        'service_stats',
        sa.Column('service_id', sa.String(64), sa.ForeignKey('services.id', ondelete='CASCADE'), nullable=False),
        sa.Column('hour_bucket', sa.Integer(), nullable=False),
        sa.Column('ewma_minutes', sa.Float(), nullable=False),
        sa.Column('ewma_var', sa.Float(), nullable=False, server_default='0.0'),
        sa.Column('n', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.PrimaryKeyConstraint('service_id', 'hour_bucket', name='pk_service_stats'),
    )

    op.create_table(
        'counter_service_stats',
        sa.Column('counter_id', sa.String(64), sa.ForeignKey('counters.id', ondelete='CASCADE'), nullable=False),
        sa.Column('service_id', sa.String(64), sa.ForeignKey('services.id', ondelete='CASCADE'), nullable=False),
        sa.Column('hour_bucket', sa.Integer(), nullable=False),
        sa.Column('ewma_minutes', sa.Float(), nullable=False),
        sa.Column('n', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.PrimaryKeyConstraint('counter_id', 'service_id', 'hour_bucket', name='pk_counter_service_stats'),
    )

    op.create_table(
        'office_calendar',
        sa.Column('id', sa.BigInteger(), sa.Identity(always=False), primary_key=True),
        sa.Column('office_id', sa.String(64), sa.ForeignKey('offices.id', ondelete='CASCADE'), nullable=False),
        sa.Column('date', sa.Date(), nullable=False),
        sa.Column('status', sa.Enum('CLOSED', 'CUSTOM_HOURS', name='calendar_status_enum', create_type=False), nullable=False),
        sa.Column('open_time', sa.Time(), nullable=True),
        sa.Column('close_time', sa.Time(), nullable=True),
        sa.Column('note', sa.String(255), nullable=True),
        sa.UniqueConstraint('office_id', 'date', name='uq_office_calendar_office_date'),
    )

    op.create_table(
        'eta_log',
        sa.Column('id', sa.BigInteger(), sa.Identity(always=False), primary_key=True),
        sa.Column('token_id', sa.String(64), sa.ForeignKey('tokens.id', ondelete='CASCADE'), nullable=False),
        sa.Column('at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column('engine', sa.String(32), nullable=False),
        sa.Column('predicted_p50', sa.Float(), nullable=False),
        sa.Column('low', sa.Float(), nullable=False),
        sa.Column('high', sa.Float(), nullable=False),
        sa.Column('naive_p50', sa.Float(), nullable=False),
    )

    op.create_table(
        'priority_checks',
        sa.Column('id', sa.BigInteger(), sa.Identity(always=False), primary_key=True),
        sa.Column('token_id', sa.String(64), sa.ForeignKey('tokens.id', ondelete='CASCADE'), nullable=False),
        sa.Column('officer_id', sa.String(64), nullable=False),
        sa.Column('doc_type', sa.String(64), nullable=False),
        sa.Column('result', sa.Enum('PENDING', 'VERIFIED', 'REJECTED', name='priority_status_enum', create_type=False), nullable=False),
        sa.Column('at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )

    op.create_table(
        'devices',
        sa.Column('user_id', sa.String(64), primary_key=True),
        sa.Column('fcm_token', sa.String(512), nullable=False),
        sa.Column('platform', sa.String(32), nullable=False, server_default='android'),
        sa.Column('language', sa.String(8), nullable=False, server_default='en'),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )

    op.create_table(
        'notification_outbox',
        sa.Column('id', sa.BigInteger(), sa.Identity(always=False), primary_key=True),
        sa.Column('token_id', sa.String(64), sa.ForeignKey('tokens.id', ondelete='CASCADE'), nullable=False),
        sa.Column('user_id', sa.String(64), nullable=True),
        sa.Column('kind', sa.String(64), nullable=False),
        sa.Column('payload', postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column('dedupe_key', sa.String(255), nullable=False, unique=True),
        sa.Column('status', sa.String(32), nullable=False, server_default='PENDING'),
        sa.Column('attempts', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('send_after', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )

    op.create_table(
        'idempotency_keys',
        sa.Column('key', sa.String(128), primary_key=True),
        sa.Column('user_id', sa.String(64), nullable=False),
        sa.Column('endpoint', sa.String(128), nullable=False),
        sa.Column('response', postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )

    op.create_table(
        'counter_events',
        sa.Column('id', sa.BigInteger(), sa.Identity(always=False), primary_key=True),
        sa.Column('counter_id', sa.String(64), sa.ForeignKey('counters.id', ondelete='CASCADE'), nullable=False),
        sa.Column('status', sa.Enum('OPEN', 'BREAK', 'CLOSED', name='counter_status_enum', create_type=False), nullable=False),
        sa.Column('at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column('actor', sa.String(64), nullable=False),
    )

    # 3. Database Triggers
    # 3.1 Append-only token_events trigger
    op.execute("""
    CREATE OR REPLACE FUNCTION trg_token_events_append_only()
    RETURNS TRIGGER AS $$
    BEGIN
        RAISE EXCEPTION 'token_events is append-only. UPDATE and DELETE are strictly forbidden.';
    END;
    $$ LANGUAGE plpgsql;
    """)

    op.execute("""
    CREATE TRIGGER trg_token_events_no_update_delete
    BEFORE UPDATE OR DELETE ON token_events
    FOR EACH ROW EXECUTE FUNCTION trg_token_events_append_only();
    """)

    # 3.2 Transition validation trigger on tokens
    op.execute("""
    CREATE OR REPLACE FUNCTION trg_validate_token_transition()
    RETURNS TRIGGER AS $$
    BEGIN
        IF TG_OP = 'UPDATE' THEN
            IF OLD.state IS DISTINCT FROM NEW.state THEN
                IF NOT EXISTS (
                    SELECT 1 FROM allowed_transitions
                    WHERE from_state = OLD.state AND to_state = NEW.state
                ) THEN
                    RAISE EXCEPTION 'Invalid token state transition from % to %', OLD.state, NEW.state;
                END IF;
            END IF;
        END IF;
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    """)

    op.execute("""
    CREATE TRIGGER trg_tokens_check_state_transition
    BEFORE UPDATE ON tokens
    FOR EACH ROW EXECUTE FUNCTION trg_validate_token_transition();
    """)

    # 4. Seed allowed_transitions per Section 5 table
    transitions = [
        (None, 'WAITING', 'CITIZEN'),
        (None, 'WAITING', 'DESK'),
        ('WAITING', 'CALLED', 'OFFICER'),
        ('CALLED', 'SERVING', 'OFFICER'),
        ('SERVING', 'COMPLETED', 'OFFICER'),
        ('WAITING', 'CANCELLED', 'CITIZEN'),
        ('WAITING', 'CANCELLED', 'DESK'),
        ('CALLED', 'CANCELLED', 'CITIZEN'),
        ('CALLED', 'CANCELLED', 'OFFICER'),
        ('WAITING', 'EXPIRED', 'SYSTEM'),
        ('CALLED', 'NO_SHOW', 'SYSTEM'),
        ('CALLED', 'NO_SHOW', 'OFFICER'),
        ('NO_SHOW', 'WAITING', 'SYSTEM'),
        ('NO_SHOW', 'CANCELLED', 'SYSTEM'),
        ('CALLED', 'WAITING', 'OFFICER'),
        ('CALLED', 'TRANSFERRED', 'OFFICER'),
        ('SERVING', 'TRANSFERRED', 'OFFICER'),
    ]
    for from_s, to_s, actor in transitions:
        from_val = f"'{from_s}'" if from_s else "NULL"
        op.execute(
            f"INSERT INTO allowed_transitions (from_state, to_state, actor_type) "
            f"VALUES ({from_val}, '{to_s}', '{actor}') ON CONFLICT DO NOTHING;"
        )

    # 5. Idempotent Demo Seed: Municipal Ward Office, 4 services, 3 counters
    op.execute("""
    INSERT INTO offices (id, name, address, timezone, open_time, close_time, qr_secret, is_simulation, active)
    VALUES (
        'ward-central-01',
        'Central Municipal Ward Office',
        'Opposite City Square, Sector 4, Gandhinagar',
        'Asia/Kolkata',
        '09:00:00',
        '17:00:00',
        'demo_qr_secret_key_123',
        false,
        true
    ) ON CONFLICT (id) DO NOTHING;
    """)

    op.execute("""
    INSERT INTO office_settings (
        office_id, grace_minutes, priority_every_n, requeue_offset, max_requeues,
        close_grace_minutes, max_active_tokens_per_phone, strike_limit,
        dispatch_window, max_pass_overs, max_waiting_per_service, max_on_behalf_tokens,
        on_my_way_extension_minutes, retention_days
    ) VALUES (
        'ward-central-01', 5, 3, 5, 1, 15, 1, 3, 3, 2, 100, 3, 5, 90
    ) ON CONFLICT (office_id) DO NOTHING;
    """)

    # 4 Services
    op.execute("""
    INSERT INTO services (id, office_id, code, names, prior_avg_minutes, required_docs, priority_allowed, active, requires_physical_visit, location_hint)
    VALUES (
        'srv-bc', 'ward-central-01', 'BC',
        '{"en": "Birth & Death Certificate", "gu": "\\u0a9c\\u0aa8\\u0acd\\u0aae \\u0a85\\u0aa8\\u0ac7 \\u0aae\\u0ab0\\u0aa3 \\u0aaa\\u0acd\\u0ab0\\u0aae\\u0abe\\u0aa3\\u0aaa\\u0aa4\\u0acd\\u0ab0", "hi": "\\u091c\\u0928\\u094d\\u092e \\u0914\\u0930 \\u092e\\u0943\\u0924\\u094d\\u092f\\u0941 \\u092a\\u094d\\u0930\\u092e\\u093e\\u0923 \\u092a\\u0924\\u094d\\u0930"}',
        8.0,
        '[{"id": "hospital_slip", "name_en": "Hospital Discharge Slip", "name_gu": "\\u0ab9\\u0acb\\u0ab8\\u0acd\\u0aaa\\u0abf\\u0a9f\\u0ab2 \\u0aa1\\u0abf\\u0ab8\\u0acd\\u0a9a\\u0abe\\u0ab0\\u0acd\\u0a9c \\u0ab8\\u0acd\\u0ab2\\u0abf\\u0aaa", "name_hi": "\\u0905\\u0938\\u094d\\u092a\\u0924\\u093e\\u0932 \\u0921\\u093f\\u0938\\u094d\\u091a\\u093e\\u0930\\u094d\\u091c \\u092a\\u0930\\u094d\\u091a\\u0940"}, {"id": "id_proof", "name_en": "Parent ID Proof", "name_gu": "\\u0ab5\\u0abe\\u0ab2\\u0ac0\\u0aa8\\u0ac1\\u0a82 \\u0a93\\u0ab3\\u0a96 \\u0aaa\\u0ac1\\u0ab0\\u0abe\\u0ab5\\u0acb", "name_hi": "\\u092e\\u093e\\u0924\\u093e-\\u092a\\u093f\\u0924\\u093e \\u0915\\u093e \\u092a\\u0939\\u091a\\u093e\\u0928 \\u092a\\u094d\\u0930\\u092e\\u093e\\u0923"}]',
        true, true, true, '{"en": "Ground Floor, Hall A", "gu": "\\u0a97\\u0acd\\u0ab0\\u0abe\\u0a89\\u0aa8\\u0acd\\u0aa1 \\u0aab\\u0acd\\u0ab2\\u0acb\\u0ab0, \\u0ab9\\u0acb\\u0ab2 \\u0a8f", "hi": "\\u092d\\u0942-\\u0924\\u0932, \\u0939\\u0949\\u0932 \\u090f"}'
    ) ON CONFLICT (id) DO NOTHING;
    """)

    op.execute("""
    INSERT INTO services (id, office_id, code, names, prior_avg_minutes, required_docs, priority_allowed, active, requires_physical_visit, location_hint)
    VALUES (
        'srv-prop', 'ward-central-01', 'PT',
        '{"en": "Property Tax Payment & Assessment", "gu": "\\u0aae\\u0abf\\u0ab2\\u0a95\\u0aa4 \\u0ab5\\u0ac7\\u0ab0\\u0acb \\u0a9a\\u0ac1\\u0a95\\u0ab5\\u0aa3\\u0ac0 \\u0a85\\u0aa8\\u0ac7 \\u0a86\\u0a95\\u0abe\\u0ab0\\u0aa3\\u0ac0", "hi": "\\u0938\\u0902\\u092a\\u0924\\u094d\\u0924\\u093f \\u0915\\u0930 \\u092d\\u0941\\u0917\\u0924\\u093e\\u0928 \\u0914\\u0930 \\u092e\\u0942\\u0932\\u094d\\u092f\\u093e\\u0902\\u0915\\u0928"}',
        12.0,
        '[{"id": "tax_bill", "name_en": "Previous Tax Receipt/Bill", "name_gu": "\\u0a85\\u0a97\\u0abe\\u0a89\\u0aa8\\u0ac0 \\u0ab5\\u0ac7\\u0ab0\\u0abe \\u0aaa\\u0abe\\u0ab5\\u0aa4\\u0ac0/\\u0aac\\u0abf\\u0ab2", "name_hi": "\\u092a\\u093f\\u091b\\u0932\\u093e \\u0915\\u0930 \\u0930\\u0938\\u0940\\u0926/\\u092c\\u093f\\u0932"}, {"id": "property_deed", "name_en": "Property Deed / Index II", "name_gu": "\\u0aa6\\u0ab8\\u0acd\\u0aa4\\u0abe\\u0ab5\\u0ac7\\u0a9c / \\u0a87\\u0aa8\\u0acd\\u0aa1\\u0ac7\\u0a95\\u0acd\\u0ab8 \\u0ae8", "name_hi": "\\u0926\\u0938\\u094d\\u0924\\u093e\\u0935\\u0947\\u091c\\u093c / \\u0907\\u0902\\u0921\\u0947\\u0915\\u094d\\u0938 \\u0968"}]',
        true, true, true, '{"en": "Ground Floor, Counter 2", "gu": "\\u0a97\\u0acd\\u0ab0\\u0abe\\u0a89\\u0aa8\\u0acd\\u0aa1 \\u0aab\\u0acd\\u0ab2\\u0acb\\u0ab0, \\u0a95\\u0abe\\u0a89\\u0aa8\\u0acd\\u0a9f\\u0ab0 \\u0ae8", "hi": "\\u092d\\u0942-\\u0924\\u0932, \\u0915\\u093e\\u0909\\u0902\\u091f\\u0930 \\u0968"}'
    ) ON CONFLICT (id) DO NOTHING;
    """)

    op.execute("""
    INSERT INTO services (id, office_id, code, names, prior_avg_minutes, required_docs, priority_allowed, active, requires_physical_visit, location_hint)
    VALUES (
        'srv-trade', 'ward-central-01', 'TL',
        '{"en": "Trade License & Shop Registration", "gu": "\\u0a9f\\u0acd\\u0ab0\\u0ac7\\u0aa1 \\u0ab2\\u0abe\\u0aaf\\u0ab8\\u0aa8\\u0acd\\u0ab8 \\u0a85\\u0aa8\\u0ac7 \\u0aa6\\u0ac1\\u0a95\\u0abe\\u0aa8 \\u0aa8\\u0acb\\u0a82\\u0aa7\\u0aa3\\u0ac0", "hi": "\\u091f\\u094d\\u0930\\u0947\\u0921 \\u0932\\u093e\\u0907\\u0938\\u0947\\u0902\\u0938 \\u0914\\u0930 \\u0926\\u0941\\u0915\\u093e\\u0928 \\u092a\\u0902\\u091c\\u0940\\u0915\\u0930\\u0923"}',
        15.0,
        '[{"id": "rent_agreement", "name_en": "Shop Rent/Ownership Agreement", "name_gu": "\\u0aa6\\u0ac1\\u0a95\\u0abe\\u0aa8 \\u0aad\\u0abe\\u0aa1\\u0abe \\u0a95\\u0ab0\\u0abe\\u0ab0 / \\u0aae\\u0abe\\u0ab2\\u0abf\\u0a95\\u0ac0 \\u0aaa\\u0ac1\\u0ab0\\u0abe\\u0ab5\\u0acb", "name_hi": "\\u0926\\u0941\\u0915\\u093e\\u0928 \\u0915\\u093f\\u0930\\u093e\\u092f\\u093e/\\u0938\\u094d\\u0935\\u093e\\u092e\\u093f\\u0924\\u094d\\u0935 \\u0905\\u0928\\u0941\\u092c\\u0902\\u0927"}, {"id": "pan_card", "name_en": "Proprietor PAN Card", "name_gu": "\\u0aaa\\u0abe\\u0aa8 \\u0a95\\u0abe\\u0ab0\\u0acd\\u0aa1", "name_hi": "\\u092a\\u0948\\u0928 \\u0915\\u093e\\u0930\\u094d\\u0921"}]',
        false, true, true, '{"en": "First Floor, Room 102", "gu": "\\u0aaa\\u0ab9\\u0ac7\\u0ab2\\u0acb \\u0aae\\u0abe\\u0ab3, \\u0ab0\\u0ac2\\u0aae \\u0ae7\\u0ae6\\u0ae8", "hi": "\\u092a\\u094d\\u0930\\u0925\\u092e \\u0924\\u0932, \\u0915\\u092e\\u0930\\u093e \\u0967\\u0966\\u0968"}'
    ) ON CONFLICT (id) DO NOTHING;
    """)

    op.execute("""
    INSERT INTO services (id, office_id, code, names, prior_avg_minutes, required_docs, priority_allowed, active, requires_physical_visit, location_hint)
    VALUES (
        'srv-rti', 'ward-central-01', 'RTI',
        '{"en": "RTI Application & Civic Grievances", "gu": "\\u0aae\\u0abe\\u0ab9\\u0abf\\u0aa4\\u0ac0 \\u0a85\\u0aa7\\u0abf\\u0a95\\u0abe\\u0ab0 (RTI) \\u0a85\\u0aa8\\u0ac7 \\u0aa8\\u0abe\\u0a97\\u0ab0\\u0abf\\u0a95 \\u0aab\\u0ab0\\u0abf\\u0aaf\\u0abe\\u0aa6", "hi": "\\u0938\\u0942\\u091a\\u0928\\u093e \\u0915\\u093e \\u0905\\u0927\\u093f\\u0915\\u093e\\u0930 (RTI) \\u0914\\u0930 \\u0928\\u093e\\u0917\\u0930\\u093f\\u0915 \\u0936\\u093f\\u0915\\u093e\\u092f\\u0924\\u0947\\u0902"}',
        10.0,
        '[{"id": "application_form", "name_en": "Written Application / Form", "name_gu": "\\u0ab2\\u0ac7\\u0a96\\u0abf\\u0aa4 \\u0a85\\u0ab0\\u0a9c\\u0ac0 / \\u0aab\\u0acb\\u0ab0\\u0acd\\u0aae", "name_hi": "\\u0932\\u093f\\u0916\\u093f\\u0924 \\u0906\\u0935\\u0947\\u0926\\u0928 / \\u092b\\u0949\\u0930\\u094d\\u092e"}]',
        true, true, true, '{"en": "First Floor, Room 105", "gu": "\\u0aaa\\u0ab9\\u0ac7\\u0ab2\\u0acb \\u0aae\\u0abe\\u0ab3, \\u0ab0\\u0ac2\\u0aae \\u0ae7\\u0ae6\\u0aeb", "hi": "\\u092a\\u094d\\u0930\\u0925\\u092e \\u0924\\u0932, \\u0915\\u092e\\u0930\\u093e \\u0967\\u0966\\u09aeb"}'
    ) ON CONFLICT (id) DO NOTHING;
    """)

    # 3 Counters
    op.execute("""
    INSERT INTO counters (id, office_id, label, status)
    VALUES
    ('cnt-1', 'ward-central-01', 'Counter 1 (Certificates & Civic)', 'CLOSED'),
    ('cnt-2', 'ward-central-01', 'Counter 2 (Property Tax & Assessment)', 'CLOSED'),
    ('cnt-3', 'ward-central-01', 'Counter 3 (Trade License & RTI)', 'CLOSED')
    ON CONFLICT (id) DO NOTHING;
    """)

    # Counter service mappings
    op.execute("""
    INSERT INTO counter_services (counter_id, service_id)
    VALUES
    ('cnt-1', 'srv-bc'),
    ('cnt-1', 'srv-rti'),
    ('cnt-2', 'srv-prop'),
    ('cnt-2', 'srv-bc'),
    ('cnt-3', 'srv-trade'),
    ('cnt-3', 'srv-rti')
    ON CONFLICT (counter_id, service_id) DO NOTHING;
    """)


def downgrade() -> None:
    # Drop triggers
    op.execute("DROP TRIGGER IF EXISTS trg_tokens_check_state_transition ON tokens;")
    op.execute("DROP FUNCTION IF EXISTS trg_validate_token_transition();")
    op.execute("DROP TRIGGER IF EXISTS trg_token_events_no_update_delete ON token_events;")
    op.execute("DROP FUNCTION IF EXISTS trg_token_events_append_only();")

    # Drop tables in reverse dependency order
    op.drop_table('counter_events')
    op.drop_table('idempotency_keys')
    op.drop_table('notification_outbox')
    op.drop_table('devices')
    op.drop_table('priority_checks')
    op.drop_table('eta_log')
    op.drop_table('office_calendar')
    op.drop_table('counter_service_stats')
    op.drop_table('service_stats')
    op.drop_table('allowed_transitions')
    op.drop_table('token_events')
    op.drop_table('tokens')
    op.drop_table('queue_state')
    op.drop_table('profiles')
    op.drop_table('counter_services')
    op.drop_table('counters')
    op.drop_table('services')
    op.drop_table('office_settings')
    op.drop_table('offices')

    # Drop ENUM types
    op.execute("DROP TYPE IF EXISTS calendar_status_enum;")
    op.execute("DROP TYPE IF EXISTS outcome_code_enum;")
    op.execute("DROP TYPE IF EXISTS actor_type_enum;")
    op.execute("DROP TYPE IF EXISTS counter_status_enum;")
    op.execute("DROP TYPE IF EXISTS priority_status_enum;")
    op.execute("DROP TYPE IF EXISTS category_enum;")
    op.execute("DROP TYPE IF EXISTS token_state_enum;")
