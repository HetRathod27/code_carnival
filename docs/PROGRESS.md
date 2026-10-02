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

### M2c: HTTP Layer & API
- **Date**: 2026-10-02
- **Built**:
  - `AuthProvider` and `DevAuth` in `api/app/core/auth.py` providing locally signed HS256 JWT creation, verification, `get_current_user`, `require_role`, and cross-office isolation checks.
  - Unified JSON error handling and machine-readable error codes (`ErrorCode`, `AppException`) in `api/app/core/errors.py`.
  - Functional API Routers:
    - Citizen router (`/v1/citizen/*`): browse offices, list services with indicative waits, book token with `Idempotency-Key` and phone limit, get active token, check in with signed HMAC QR, view token details, and cancel token.
    - Officer router (`/v1/officer/*`): view queue with masked phones, set counter status with O12 guard, call-next with arrived-first and priority interleaving, start serving, complete serving with outcome codes, mark no-show, release token, transfer token, and priority verification.
    - Desk router (`/v1/desk/*`): assisted and walk-in token issuance (auto-arrived at desk) and manual desk arrival check-in.
    - Admin router (`/v1/admin/*`): list offices, get and patch `office_settings`, generate entrance QR check-in code, and create staff profiles.
  - Export OpenAPI schema utility in `scripts/export_openapi.py` generating `openapi/openapi.json`.
  - Comprehensive API test suite in `api/tests/api/test_routes.py`:
    - Full role-based authorization matrix and cross-office isolation.
    - Citizen booking and lifecycle journey.
    - Officer full lifecycle, O12 guard, and outcome completion.
    - Desk assisted booking and admin settings management.
- **Files**:
  - `api/app/core/auth.py`, `api/app/core/errors.py`
  - `api/app/schemas/common.py`, `api/app/schemas/citizen.py`, `api/app/schemas/officer.py`, `api/app/schemas/desk.py`, `api/app/schemas/admin.py`
  - `api/app/routers/citizen.py`, `api/app/routers/officer.py`, `api/app/routers/desk.py`, `api/app/routers/admin.py`
  - `api/app/main.py`, `scripts/export_openapi.py`, `openapi/openapi.json`
  - `api/tests/api/test_routes.py`
  - `scripts/verify.ps1`, `pyproject.toml`
- **Commands & Results**:
  - `powershell -ExecutionPolicy Bypass -File scripts/verify.ps1`: Exit code 0 (25 passed in 8.41s, Ruff: OK, OpenAPI export: OK, Mypy: OK on 34 files, Web typecheck/build: OK).
- **Assumptions**:
  - JWT tokens encode `sub` (user_id), `role`, `office_id`, `phone`, `name`, and standard timestamps.
  - Office settings column `priority_every_n` mapped to API response schema.
- **Git Commit & Tag**: `m2c-done`.

---

### M3: ETA Engine
- **Date**: 2026-10-02
- **Built**:
  - api/app/eta/models.py: Dataclasses for WaitingToken, ServingToken, CounterInfo, ServiceInfo, QueueSnapshot, and EtaResult.
  - api/app/eta/engine.py:
    - ETAEngine ABC with pure function signature compute_etas(snapshot).
    - NaiveEngine: baseline engine (idx * mean) / open_counters.
    - LiveAdjustedEngine: greedy multi-counter simulation schedule incorporating Section 19.3 overrun rule (remaining_i = max(mean - elapsed, 1.0) when elapsed <= mean, 0.5 * mean when elapsed > mean), SLOW_CASE attribution (> 1.5 * mean), and COUNTER_DOWN pause code.
  - api/app/eta/admission.py: Section 19.1 admission control pure function predicting tail token wait time vs office close_time - close_grace and max_waiting_per_service, with DESK override support.
  - api/app/eta/loader.py: load_queue_snapshot async helper reconstructing in-memory queue snapshot from DB state.
  - api/app/services/token_service.py: Integrated admission control check prior to atomic sequence allocation, and compute/record EtaLog and token ETA interval (p50, low, high, reason) on booking.
  - api/app/models/entities.py: Added SQLAlchemy declarative models for EtaLog and ServiceStats.
  - api/app/schemas/citizen.py & api/app/routers/citizen.py: Exposed eta_low and eta_high bounds in citizen token responses.
  - api/tests/eta/test_eta_engine.py: 9 comprehensive test suites (pure function zero-DB guarantee, Section 19.3 overrun rule, counter-down pause, monotonicity, counter sensitivity, admission control capacity & cutoff, Hypothesis property tests across random distributions, and DB integration tests for eta_log).
- **Files**:
  - api/app/eta/models.py, api/app/eta/engine.py, api/app/eta/admission.py, api/app/eta/loader.py
  - api/app/models/entities.py, api/app/services/token_service.py
  - api/app/schemas/citizen.py, api/app/routers/citizen.py
  - openapi/openapi.json
  - api/tests/eta/test_eta_engine.py, api/tests/domain/test_domain_core.py
- **Commands & Results**:
  - scripts/verify.ps1: Exit code 0 (All 34 tests passed in 13.90s, Ruff: OK, OpenAPI export: OK, Mypy: OK on 39 source files, Web typecheck/build: OK).
- **Assumptions**:
  - Desk bookings (ASSISTED, DESK) override admission cutoff to allow emergency walk-ins.
  - Naive p50 logged side-by-side in eta_log for comparative benchmark evaluation per spec Section 8.
- **Git Commit & Tag**: m3-done.

---

## M4: Scheduler and Notifications
- **Status**: Starting immediately per Autopilot Rules.
- **Plan**:
  1. Scheduler Endpoint (/internal/tick):
     - Protected by shared internal secret header (X-Internal-Secret).
     - Guarded by PostgreSQL advisory lock (pg_try_advisory_xact_lock(424242)) to ensure strict single execution and idempotency across multiple simultaneous triggers.
  2. Sweeps:
     - No-show sweep: Find CALLED tokens where grace_deadline <= now and serving_started_at IS NULL -> transition to NO_SHOW.
       - If requeue_count < max_requeues: transition NO_SHOW -> WAITING with bumped requeue_count and new sort_key (requeue_offset positions behind head), append REQUEUED push notification.
       - Else: transition NO_SHOW -> CANCELLED, append CANCELLED_BY_SYSTEM push notification.
     - Expiry sweep: Offices past close_time + close_grace_minutes -> transition remaining WAITING tokens to EXPIRED.
     - ETA sweep & Notification ladder: For active queues, load snapshots, compute ETAs, update last_eta_minutes and evaluate:
       - GET_READY: ETA p50 <= 15 min.
       - LEAVE_NOW: now >= leave_at where leave_at = ETA_p50 - travel_minutes - 5.
       - ETA_CHANGED: when absolute delta >= max(10 min, 25%).
  3. Outbox delivery:
     - Process pending rows in notification_outbox with backoff retry and localized message templates (en, gu, hi).
  4. Tests:
     - Full idempotency tests when /internal/tick is called concurrently or repeatedly.
     - Sweeps transition tests and notification ladder deduplication tests.
  5. Verification & Gate:
     - Run scripts/verify.ps1 exit code 0, commit, and tag m4-done.
