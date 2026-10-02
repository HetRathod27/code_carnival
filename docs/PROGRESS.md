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
- **Date**: 2026-10-02
- **Built**:
  - `Clock` abstraction in `api/app/core/clock.py`: abstract base class `Clock`, production `SystemClock`, and controllable `VirtualClock` supporting virtual business dates, epoch timestamps, time advance, and time setting.
  - SQLAlchemy 2.x declarative models in `api/app/models/entities.py` for all 18 tables and relationships (`Office`, `OfficeSettings`, `Service`, `Counter`, `QueueState`, `Token`, `TokenEvent`, `IdempotencyKey`, `ServiceStats`, etc.).
  - State machine transition in `api/app/domain/state_machine.py`:
    - Full `ALLOWED_TRANSITIONS` lookup matching spec Section 5.
    - Pure atomic `transition()` updating `token.state`, recording `token_events`, and incrementing `queue_state.version`.
  - Token service in `api/app/services/token_service.py`:
    - `book_token`: atomic numbering with row-level locks on `queue_state`, one active token per phone per service guard, priority status handling, and `Idempotency-Key` deduplication.
    - `cancel_token`: citizen/desk/system/officer cancellation updating state and decrementing `waiting_count`.
  - Test suite in `api/tests/domain/test_domain_core.py`:
    - Full domain transition matrix covering all state pairs across all actor roles.
    - 200 parallel bookings yielding unique and gapless sequence numbers (1..200).
    - Double-submit idempotency returning identical responses without duplicate tokens.
    - One active token rule rejection (`ACTIVE_TOKEN_EXISTS`).
    - Cancel token functionality.
- **Files**:
  - `api/app/core/clock.py`
  - `api/app/models/entities.py`
  - `api/app/domain/state_machine.py`
  - `api/app/services/token_service.py`
  - `api/tests/domain/test_domain_core.py`
- **Commands & Results**:
  - `powershell -ExecutionPolicy Bypass -File scripts/verify.ps1`: Exit code 0 (13 passed in 5.45s, Ruff: OK, Mypy: OK, Web typecheck/build: OK).
- **Assumptions**:
  - Sequence generation handles legacy test records by syncing `queue_state.last_seq` with existing max token sequence if higher.
- **Git Commit & Tag**: `m2a-done`.

---

### M2b: Officer Operations
- **Date**: 2026-10-02
- **Built**:
  - Added models in `api/app/models/entities.py`: `PriorityCheck`, `CounterEvent`, `Device`.
  - Implemented officer domain service in `api/app/services/officer_service.py`:
    - `set_counter_status()` with rule O12 guard (cannot close counter with active serving token).
    - `call_next()`:
      - Spec 6.5 & Section 19.2 arrived-first dispatch within `dispatch_window`.
      - Priority 1-in-N interleaving based on `office_settings.priority_ratio` and `calls_since_priority`.
      - Increments `pass_over_count` on unarrived tokens up to `max_pass_overs`.
      - Strict DB row-level locking (`queue_state` -> `counters` -> `tokens` `FOR UPDATE SKIP LOCKED`).
      - Emits `YOUR_TURN` notification outbox record with deduplication.
    - `start_serving()` & `complete_serving()`: records `outcome_code`, service duration, and updates `counter_service_stats`.
    - `mark_no_show()`: transitions to `NO_SHOW`, emits `NO_SHOW` counter event.
    - `release_token()`: returns token to `WAITING` without sort penalty.
    - `transfer_token()`: transitions source token to `TRANSFERRED`, creates new target token carrying `sort_key`.
    - `priority_check()`: records officer check; if rejected, applies strike and converts category to NORMAL.
    - Strike limit enforcement in `book_token()`: blocks priority booking if user reached `strike_limit`.
    - `check_in_token()` and `generate_office_qr_payload()`: HMAC-signed QR arrival check-in.
  - Comprehensive test suite in `api/tests/domain/test_officer_operations.py`:
    - `test_counter_guards_and_status`: verifies O12 guard against closing busy counters.
    - `test_parallel_call_next_distinct_tokens`: verifies concurrency with `FOR UPDATE SKIP LOCKED`.
    - `test_priority_ratio_interleave`: validates 3:1 interleaving pattern.
    - `test_arrived_first_dispatch_and_pass_over`: verifies arrived-first dispatch and `pass_over_count` tracking.
    - `test_priority_check_and_strike_limit`: verifies strike application and subsequent priority blocking.
    - `test_signed_qr_checkin`: verifies cryptographic HMAC QR verification and arrival recording.
    - `test_release_and_transfer_token`: validates release and transfer semantics.
- **Files**:
  - `api/app/models/entities.py`
  - `api/app/services/officer_service.py`
  - `api/app/services/token_service.py`
  - `api/tests/domain/test_officer_operations.py`
- **Commands & Results**:
  - `powershell -ExecutionPolicy Bypass -File scripts/verify.ps1`: Exit code 0 (20 passed in 9.86s, Ruff: OK, Mypy: OK, Web typecheck/build: OK).
- **Assumptions**:
  - Counter events and stats track service durations in seconds.
  - Office QR check-in uses SHA256 HMAC over `office_id:date` with an office secret.
- **Git Commit & Tag**: `m2b-done`.

---

## M2c: HTTP Layer & API
- **Status**: Starting immediately per Autopilot Rules.
- **Plan**:
  1. Build `DevAuth` authentication & authorization dependencies:
     - Locally signed JWT tokens (`HS256`) encoding user claims (`user_id`, `phone`, `role`, `office_id`).
     - Dependency injection for `get_current_user`, `require_role(allowed_roles)`, and office tenancy checks.
  2. Implement unified API error responses per Spec Section 6.1:
     - Error format: `{ "error": { "code": "...", "message": "...", "details": {...} } }`.
     - Standard HTTP status mappings (400, 401, 403, 404, 409, 422).
  3. Implement API Routers:
     - **Citizen Router** (`/v1/citizen/*`):
       - `POST /v1/citizen/tokens` (book token with `Idempotency-Key`).
       - `GET /v1/citizen/tokens/{token_id}` (get token detail, ETA, position).
       - `POST /v1/citizen/tokens/{token_id}/cancel`.
       - `POST /v1/citizen/tokens/{token_id}/check-in` (signed QR check-in).
       - `GET /v1/citizen/offices/{office_id}/services` (list services).
     - **Officer Router** (`/v1/officer/*`):
       - `POST /v1/officer/counter/status` (open/close/pause counter).
       - `POST /v1/officer/call-next`.
       - `POST /v1/officer/tokens/{token_id}/start`.
       - `POST /v1/officer/tokens/{token_id}/complete` (with `outcome_code`).
       - `POST /v1/officer/tokens/{token_id}/no-show`.
       - `POST /v1/officer/tokens/{token_id}/release`.
       - `POST /v1/officer/tokens/{token_id}/transfer`.
       - `POST /v1/officer/tokens/{token_id}/priority-check`.
     - **Desk Router** (`/v1/desk/*`):
       - `POST /v1/desk/tokens` (assisted booking).
       - `POST /v1/desk/tokens/{token_id}/check-in`.
     - **Admin Router** (`/v1/admin/*`):
       - `GET /v1/admin/offices/{office_id}/settings`.
       - `PATCH /v1/admin/offices/{office_id}/settings`.
  4. Script / tool to export OpenAPI JSON:
     - `api/app/main.py` route or script dumping `openapi/openapi.json`.
  5. Auth and Route Matrix tests in `api/tests/api/test_routes.py`:
     - Test role-based access control (citizen cannot call officer routes, etc.).
     - Test cross-office boundary violations (officer cannot act on another office's counter/tokens).
  6. Run `scripts/verify.ps1`, verify gate passes, commit, and tag `m2c-done`.

