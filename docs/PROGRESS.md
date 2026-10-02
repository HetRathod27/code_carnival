# QueueLess — Progress Log

Running log of milestones, completed tasks, verifications, and status.

---

## Log

### Step 0 & M0: Foundation
- **Date**: 2026-10-02
- **Built**:
  - Confirmed Section 19 and Section 20 exist in `docs/spec.md`.
  - Initialized git repository with strict `.gitignore` ignoring `.env`, caches, and build outputs.
  - Authored `docs/TASKS.md`, `docs/DECISIONS.md`, `docs/HUMAN_TODO.md`, and updated `AGENTS.md` and `.agents/rules/AGENTS.md` with Autopilot rules.
  - Implemented `api/app/core/safety.py` enforcing the `_test` DB name safety guard with unit tests.
  - Created FastAPI app (`/healthz` and `/readyz`) with test coverage.
  - Configured async SQLAlchemy engine and async Alembic migrations (`api/migrations/env.py`). Verified with throwaway migration upgrade head and downgrade base against `queueless_dev`.
  - Scaffolding web client with React 19, TypeScript, and Vite, adding typecheck script.
  - Created master automated verification harness `scripts/verify.ps1`.
- **Files**:
  - `AGENTS.md`, `.agents/rules/AGENTS.md`, `docs/TASKS.md`, `docs/PROGRESS.md`, `docs/DECISIONS.md`, `docs/HUMAN_TODO.md`
  - `api/app/main.py`, `api/app/core/config.py`, `api/app/core/db.py`, `api/app/core/safety.py`
  - `api/tests/api/test_health.py`, `api/tests/unit/test_safety.py`
  - `alembic.ini`, `api/migrations/env.py`, `pyproject.toml`, `scripts/verify.ps1`
  - `web/*` (React + TypeScript + Vite project)
- **Commands & Results**:
  - `powershell -ExecutionPolicy Bypass -File scripts/verify.ps1`: Exit code 0 (Ruff: OK, Mypy: OK, Pytest: 5 passed in 1.56s, Web typecheck: OK, Web build: OK).
  - Alembic throwaway test: upgrade head and downgrade base both exited 0.
- **Assumptions**:
  - Local PostgreSQL running on port 5432 with `queueless_dev` and `queueless_test` configured in `.env`.
- **Git Commit & Tag**: `a284545`, tag `m0-done`.

---

### M1: Database
- **Date**: 2026-10-02
- **Built**:
  - Full schema migration (`c20ab5490eb8_m1_full_schema.py`) covering spec Section 4 and Section 19.5:
    - Tables: `offices`, `office_settings`, `services`, `counters`, `counter_services`, `profiles`, `queue_state`, `tokens`, `token_events`, `allowed_transitions`, `service_stats`, `counter_service_stats`, `office_calendar`, `eta_log`, `priority_checks`, `devices`, `notification_outbox`, `idempotency_keys`, `counter_events`.
    - Enums: `token_state_enum`, `category_enum`, `priority_status_enum`, `counter_status_enum`, `actor_type_enum`, `outcome_code_enum`, `calendar_status_enum`.
    - Partial unique index: `idx_tokens_phone_service_active` on `(phone, service_id)` for active tokens.
    - Triggers: `trg_tokens_check_state_transition` (validates transitions against `allowed_transitions`), `trg_token_events_no_update_delete` (strict append-only protection on `token_events`).
    - Seed data: complete `allowed_transitions` matrix and idempotent demo seed (Central Municipal Ward Office, 4 services, 3 counters, spec default settings).
  - Supabase-only SQL (`api/supabase_only/rls_and_realtime.sql`) containing RLS policies, Realtime publication on `queue_state`, and auth user hook.
  - Comprehensive DB tests in `api/tests/database/test_schema_and_triggers.py`:
    - Full 8x8 state transition matrix test proving allowed moves pass and invalid moves are rejected by DB trigger.
    - Append-only trigger test proving `token_events` refuses `UPDATE` and `DELETE`.
    - 50 concurrent transactions testing atomic sequential numbering on `queue_state`.
- **Files**:
  - `api/migrations/versions/c20ab5490eb8_m1_full_schema.py`
  - `api/supabase_only/rls_and_realtime.sql`
  - `api/tests/database/test_schema_and_triggers.py`
  - `pyproject.toml`
- **Commands & Results**:
  - `alembic upgrade head` executed on both `queueless_dev` and `queueless_test` with exit code 0.
  - `powershell -ExecutionPolicy Bypass -File scripts/verify.ps1`: Exit code 0 (All 8 tests passed in 3.17s, Ruff: OK, Mypy: OK, Web typecheck/build: OK).
- **Assumptions**:
  - Asyncpg handles individual DDL/DML statements sequentially during Alembic migrations.
- **Git Commit & Tag**: `98af648`, tag `m1-done`.

---

### M2a: Domain Core
- **Status**: Starting immediately per Autopilot Rules.
- **Plan**:
  1. Clock abstraction in `api/app/core/clock.py` (`SystemClock`, `VirtualClock` implementing `Clock` interface with epoch support).
  2. SQLAlchemy 2.x ORM models in `api/app/models/` mirroring M1 schema.
  3. Domain state machine function in `api/app/domain/state_machine.py`:
     - `ALLOWED_TRANSITIONS` table.
     - `transition(token, to_state, actor, session, counter_id, meta)` executing atomic transitions, appending to `token_events`, and incrementing `queue_state.version`.
  4. Core services in `api/app/services/token_service.py` & `api/app/services/queue_service.py`:
     - Booking (`book_token`) implementing atomic numbering (`FOR UPDATE` on `queue_state`), one-active-token rule per phone per service, priority category handling, and `Idempotency-Key` deduplication.
     - Cancellation (`cancel_token`).
  5. Tests in `api/tests/domain/`:
     - 200 parallel bookings yielding unique, gapless sequence numbers.
     - Double-submit idempotency test.
     - Domain transition matrix test.
     - One active token constraint verification.
  6. Run `scripts/verify.ps1`, verify gate passes, commit, and tag `m2a-done`.
