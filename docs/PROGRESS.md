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
- **Date**: 2026-10-02
- **Built**:
  - `api/app/services/scheduler_service.py`: Full tick implementation:
    - `enqueue_notification()`: atomic INSERT with `ON CONFLICT (dedupe_key) DO NOTHING` for deduplication.
    - `run_tick()`: acquires `pg_try_advisory_xact_lock(424242)` — returns `SKIPPED/LOCK_HELD` if concurrent tick is running.
    - No-show sweep: CALLED tokens with `grace_deadline <= now` → NO_SHOW → WAITING (auto-requeue with sort_key bump) or CANCELLED, with REQUEUED/CANCELLED_BY_SYSTEM notifications.
    - Expiry sweep: per-office timezone-aware cutoff (close_time + close_grace_minutes) → WAITING → EXPIRED with EXPIRED notification.
    - ETA pass: loads queue snapshot per active queue, runs LiveAdjustedEngine, updates `last_eta_minutes`/`last_eta_reason`, fires GET_READY (p50 ≤ 15 min), LEAVE_NOW (eta - travel_minutes - 5 ≤ 0), ETA_CHANGED (|Δ| ≥ max(10, 25%·old), bucketed per 10-min window).
    - NO_SHOW_WARNING: CALLED tokens with `grace_deadline - now ≤ 2 min`.
    - Outbox flush: processes up to 50 PENDING rows, looks up user language from `devices`, renders localized text via templates, marks SENT.
  - `api/app/routers/internal.py`: `POST /internal/tick` protected by `X-Internal-Secret` header + advisory lock.
  - `api/app/notifications/templates.py`: Localized templates for TOKEN_CONFIRMED, GET_READY, LEAVE_NOW, YOUR_TURN, ETA_CHANGED, NO_SHOW_WARNING, REQUEUED, CANCELLED_BY_SYSTEM, EXPIRED in en/gu/hi (Core Rule 7).
  - `api/tests/scheduler/test_scheduler.py`: 6 test cases:
    - `test_tick_auth_guards`: 401 on missing/wrong secret, 200 on valid.
    - `test_tick_advisory_lock_idempotency`: second concurrent tick returns SKIPPED/LOCK_HELD.
    - `test_no_show_sweep_auto_requeue_and_cancel`: requeue_count < max → WAITING; ≥ max → CANCELLED.
    - `test_expiry_sweep`: office past cutoff → WAITING tokens become EXPIRED.
    - `test_notification_ladder_and_deduplication`: GET_READY/LEAVE_NOW fired; repeated tick produces no duplicates.
    - `test_localized_notification_templates`: en/gu/hi strings verified.
- **Files**:
  - `api/app/services/scheduler_service.py`
  - `api/app/routers/internal.py`
  - `api/app/notifications/templates.py`
  - `api/tests/scheduler/test_scheduler.py`
- **Commands & Results**:
  - `scripts/verify.ps1`: Exit code 0 (40 passed in 17.60s, Ruff: OK, OpenAPI: OK, Mypy: OK on 43 files, Web typecheck/build: OK).
- **Assumptions**:
  - Outbox delivery logs rendered text locally (simulating FCM); actual FCM push requires Firebase credentials (HUMAN_TODO).
  - Advisory lock is transaction-scoped (`pg_try_advisory_xact_lock`, not session); released automatically at commit.
- **Git Commit & Tag**: `632f63d`, tag `m4-done`.

---

## M5: Simulator and Reports
- **Date**: 2026-10-02
- **Built**:
  - `api/app/sim/scenario.py`: Dataclasses for `ServiceScenario`, `BreakEvent`, `RushEvent`, `SimScenario`; `default_ward_scenario()` pre-configured for ward office with peak arrival curve, breaks, and a rush injection.
  - `api/app/sim/runner.py`: `run_simulation()` — drives real domain services (book_token, call_next, start_serving, complete_serving, mark_no_show, run_tick) with an injected `VirtualClock` advancing one virtual minute per loop iteration. Safety guard refuses non-simulation offices unless `allow_real_office=True`. Computes MAE (live vs naive) and within-range-% from per-token records.
  - `api/app/services/report_service.py`: Three pure SQL aggregate functions — `get_summary_report()` (served/cancelled/expired/no-show, avg+P90 wait, priority share), `get_load_by_hour()` (tokens booked/served per hour bucket), `get_eta_accuracy()` (MAE, within-range-%, vs naive using `eta_log.naive_p50`). Fixed PostgreSQL `ROUND(float8)` by casting to `::numeric` after FILTER aggregates.
  - `api/app/routers/admin.py`: Added `POST /v1/admin/sim/{office_id}/start`, `GET /v1/admin/sim/{office_id}/status` (production-gated), and `GET /v1/admin/reports/{office_id}/{summary|load-by-hour|eta-accuracy}?report_date=` endpoints.
  - `api/tests/sim/test_sim_regression.py`: 3 tests:
    - `test_sim_regression_live_beats_naive`: runs seeded 60-min simulation; asserts live-adjusted MAE ≤ naive MAE (Spec Section 14 Rule 6).
    - `test_sim_scenario_config`: validates `default_ward_scenario()` structure.
    - `test_report_services_work`: exercises all three report service functions against test DB.
- **Files**:
  - `api/app/sim/scenario.py`, `api/app/sim/runner.py`, `api/app/sim/__init__.py`
  - `api/app/services/report_service.py`
  - `api/app/routers/admin.py`
  - `api/tests/sim/test_sim_regression.py`, `api/tests/sim/__init__.py`
- **Commands & Results**:
  - `scripts/verify.ps1`: Exit code 0 (43 passed in 17.93s, Ruff: OK, OpenAPI: OK, Mypy: OK on 49 files, Web typecheck/build: OK).
- **Assumptions**:
  - `allow_real_office=True` is only used in tests against `queueless_test`; production sim endpoints check `is_simulation=True`.
  - MAE comparison uses `last_eta_minutes` from book_token response as proxy for live-adjusted p50; naive_p50 is stored identically at booking time in `eta_features`.
- **Git Commit & Tag**: `9d6a3eb`, tag `m5-done`.

---

## M6a: Web Foundation & Officer Screens
- **Date**: 2026-10-02
- **Built**:
  - `web/src/api/client.ts`: Typed fetch API client connecting to backend endpoints (`/internal/dev-token`, `/v1/officer/counters/{id}/queue`, `/status`, `/call-next`, `/tokens/{id}/start`, `/complete`, `/no-show`, `/release`, `/transfer`, `/priority-check`, `/v1/citizen/offices`, `/services`). Matches backend schemas without modifying backend.
  - `web/src/context/AuthContext.tsx`: `AuthProvider` fetching DevAuth personas from `/internal/dev-token` with local JWT caching and role assignment.
  - `web/src/i18n/`: Complete multilingual internationalization dictionary for English, Gujarati, and Hindi (`en.json`, `gu.json`, `hi.json`) with persistent language selection (`ql_lang`).
  - `web/src/index.css`: Comprehensive design system built directly on Google Stitch Civic Minimalist specifications (light/high-contrast institutional palette, 4px/8px rhythm, Noto Sans typography, tabular nums, accessible buttons and modals).
  - `web/src/components/AppShell.tsx`: Navigation header with office context, brand logo, user role badges, tab switches, and language picker.
  - `web/src/pages/LoginPage.tsx`: Dev persona picker card grid with role descriptions and instant login.
  - `web/src/pages/OfficerQueuePage.tsx`: Officer Live Queue with 5s polling, counter status toggle (OPEN/BREAK/CLOSED), prominent Call Next action, Now Serving card with live timer, outcome modal (SERVED, MISSING_DOCS, etc.), transfer modal, no-show modal, and priority verification.
  - `web/src/App.tsx`: Top-level app routing based on authentication state.
- **Files**:
  - `web/src/api/client.ts`
  - `web/src/context/AuthContext.tsx`
  - `web/src/i18n/index.ts`, `web/src/i18n/en.json`, `web/src/i18n/gu.json`, `web/src/i18n/hi.json`
  - `web/src/index.css`
  - `web/src/components/AppShell.tsx`
  - `web/src/pages/LoginPage.tsx`
  - `web/src/pages/OfficerQueuePage.tsx`
  - `web/src/App.tsx`, `web/src/main.tsx`, `web/index.html`
- **Commands & Results**:
  - `npm --prefix web run build`: Exit code 0 (vite build transformed 51 modules, zero errors).
  - `scripts/verify.ps1`: Exit code 0 (43 passed in 25.49s, Ruff: OK, OpenAPI: OK, Mypy: OK on 49 files, Web typecheck/build: OK).
- **Assumptions**:
  - DevAuth tokens via `/internal/dev-token` are used for frontend development.
  - Default counter used is `cnt-1` with option to toggle to `cnt-2` and `cnt-3`.
- **Git Commit & Tag**: `m6a-done`

---

## M5b: Backend Hardening
- **Date**: 2026-10-05
- **Built**:
  - Full-Day Simulation Regression Accuracy Proof: Evaluated 58 served tokens over an 8-hour day with rush events, breaks, and priority requests. Fixed `actual_wait` metric to `called_at - created_at` (Spec Section 8). Recorded: `MAE_Live = 50.397 min` strictly lower than `MAE_Naive = 50.840 min` (`test_full_day_sim_regression_strict_mae`). In background simulation API: `MAE_Live = 34.03 min` vs `MAE_Naive = 36.41 min`.
  - Core V1 Endpoints (`api/app/routers/v1_core.py`):
    - `POST /v1/devices` (C7): register FCM device token & language with upsert.
    - `PATCH /v1/me` (C11): update user language & profile.
    - `GET /v1/display/{office_id}`: public lobby board returning counter labels and active `now_serving` display codes without personal citizen data (no auth required).
    - `POST/DELETE /v1/queues/{service_id}/pause` (O10): pause/resume booking with required reason, mutating `queue_state.paused`.
  - Admin CRUD (`api/app/routers/admin.py`): Complete CRUD for `/v1/admin/services`, `/v1/admin/counters`, and `/v1/admin/counter-services` with validation and role guards.
  - Production Security Guard: Lifespan hook in `api/app/main.py` raising `RuntimeError` if `ENVIRONMENT=production` while DevAuth is enabled.
  - State Machine Correctness: `mark_no_show` in `officer_service.py` automatically requeues or cancels per `office_settings` (never leaves token stranded in `NO_SHOW`). Desk assisted booking supports `WALKIN` and `override_reason` logged in `token_events.meta["reason_code"]`.
  - Admission Control Enhancement: Modeled capacity in `check_admission` when counters are temporarily closed before opening hours or on break.
  - Technical Specification v3 (`docs/spec.md` & `docs/DECISIONS.md` D-006): Integrated superseding rule for fixed online appointment slots, physical tokens with live queue ETA, immediate physical dispatch on absent online users (no 3-missed prerequisite), double completion confirmation for online, and deadline cutoff controls.
  - Smoke Test Documentation (`docs/SMOKE_TEST.md`): PowerShell commands with real recorded outputs covering seed, dev tokens, lifecycle, simulation, and all 3 aggregate reports.
- **Files**:
  - `api/app/routers/v1_core.py`, `api/app/routers/admin.py`, `api/app/routers/desk.py`, `api/app/routers/citizen.py`
  - `api/app/services/token_service.py`, `api/app/services/officer_service.py`
  - `api/app/eta/admission.py`, `api/app/sim/runner.py`
  - `api/app/main.py`
  - `api/tests/api/test_m5b_hardening.py`, `api/tests/sim/test_sim_regression.py`
  - `docs/SMOKE_TEST.md`, `docs/spec.md`, `docs/DECISIONS.md`, `docs/PROGRESS.md`
- **Commands & Results**:
  - `scripts/verify.ps1`: Exit code 0 (51 passed in 40.74s, Ruff: OK, OpenAPI export: OK, Mypy: OK on 51 files, Web typecheck & build: OK).
- **Git Commit & Tag**: `m5b-done`

---

## M6b: Web Remainder & Polish
- **Date**: 2026-10-05
- **Built**:
  - `web/src/api/client.ts`: Typed API client methods and data types for Desk (`deskCreateToken`, `deskManualCheckIn`, `deskGetTokenSlip`), Display Board (`fetchDisplayBoard`), Admin (`fetchAdminOffices`, `fetchOfficeSettings`, `updateOfficeSettings`, `createAdminService`, `updateAdminService`, `deleteAdminService`, `pauseQueueBooking`, `resumeQueueBooking`, `createAdminCounter`, `updateAdminCounter`, `deleteAdminCounter`, `mapCounterService`, `unmapCounterService`, `generateEntranceQr`), Reports (`fetchReportSummary`, `fetchReportLoadByHour`, `fetchReportEtaAccuracy`), and Simulator (`startSimulation`, `getSimulationStatus`).
  - `web/src/pages/DeskPage.tsx`: Help Desk Assisted & Walk-in Booking with category/priority selection, capacity override checkbox + mandatory reason, quick manual arrival check-in tab, and Printable Physical Turn Slip preview modal formatted with estimated turn times, queue ahead count, and TV lobby guidance per Spec v3.
  - `web/src/pages/DisplayPage.tsx`: Public Lobby Display Board route `/display/:officeId` with live digital clock, high-contrast dark civic theme, auto-polling every 3s, fullscreen toggle, displaying counter labels and active `now_serving` token codes only with zero citizen personal data (Spec 14.2 & 35.9).
  - `web/src/pages/AdminPage.tsx`: Office Settings editor, Services manager with pause/resume booking controls and mandatory reason logging (O10), and Daily Entrance Signed QR generator.
  - `web/src/pages/ReportsPage.tsx`: Analytics dashboard with date picker, KPI summary metrics (served, cancelled, no-show, expired, avg/p90 wait), responsive SVG hourly load chart (booked vs served), and ETA Accuracy Benchmark panel confirming Live-Adjusted Engine superiority over Naive baseline.
  - `web/src/pages/SimPage.tsx`: Simulation control panel to trigger full-day 8-hour virtual runs (`POST /v1/admin/sim/{office_id}/start`), poll progress, and inspect final metrics and MAE accuracy.
  - `web/src/components/AppShell.tsx` & `web/src/App.tsx`: Role-based navigation for Officer, Desk, Admin, Reports, and Sim tabs, unauthenticated public routing for `/display/:officeId`, and multilingual localization dictionary support across English, Gujarati, and Hindi (`en.json`, `gu.json`, `hi.json`).
  - Backend Enhancement: Added `GET /v1/desk/tokens/{id}/slip` in `api/app/routers/desk.py` and test in `api/tests/api/test_routes.py` allowing physical turn slip retrieval and reprints per Spec Section 31.
- **Files**:
  - `web/src/api/client.ts`, `web/src/App.tsx`, `web/src/components/AppShell.tsx`
  - `web/src/pages/DeskPage.tsx`, `web/src/pages/DisplayPage.tsx`, `web/src/pages/AdminPage.tsx`, `web/src/pages/ReportsPage.tsx`, `web/src/pages/SimPage.tsx`
  - `web/src/i18n/en.json`, `web/src/i18n/gu.json`, `web/src/i18n/hi.json`
  - `api/app/routers/desk.py`, `api/tests/api/test_routes.py`, `openapi/openapi.json`
  - `docs/PROGRESS.md`
- **Commands & Results**:
  - `powershell -ExecutionPolicy Bypass -File scripts/verify.ps1`: Exit code 0 (All 51 pytest tests passed in 45.01s, Ruff: OK, OpenAPI schema: OK, Mypy: OK on 51 source files, Web typecheck: OK, Vite build: OK).
- **Assumptions**:
  - Public display board at `/display/:officeId` operates without requiring login so it can run directly on lobby TV screens or browser monitors.
- **Git Commit & Tag**: `m6b-done`

---

## D1: Supabase & Deploy Prep (Human Gate)
- **Date**: 2026-10-05
- **Built**:
  - `api/app/core/auth.py`: Implemented `SupabaseAuth(AuthProvider)` capable of decoding and verifying Supabase JWT tokens via HMAC SHA256 (`SUPABASE_JWT_SECRET`), extracting `sub`, `role` (from `app_metadata`/`user_metadata`), `office_id`, `phone`, and `name`. Updated `get_auth_provider()` to dynamically switch between `DevAuth` and `SupabaseAuth` based on `settings.AUTH_PROVIDER`.
  - `api/app/core/config.py`: Added configuration attributes `AUTH_PROVIDER`, `JWT_SECRET`, `SUPABASE_URL`, and `SUPABASE_JWT_SECRET`.
  - `api/tests/unit/test_supabase_auth.py`: 6 comprehensive unit tests verifying valid token decoding, expired token rejection (401), tampered signature rejection (401), malformed token rejection, default role assignment, and provider switching.
  - `supabase/setup.sql`: Complete Supabase project configuration SQL:
    - Realtime publication on `queue_state` ONLY (Spec Rule 3 Realtime Exception).
    - RLS enabled across all tables with read-only public access to `queue_state`, `offices`, and `services`. Strict rejection of direct client inserts/updates/deletes on tokens or appointments (API owns all business logic).
    - `pg_cron` + `pg_net` background job executing `/internal/tick` every minute.
  - `api/Dockerfile`: Multi-stage production container build with non-root unprivileged `queueless` user, libpq runtime, healthcheck on `/healthz`, and uvicorn runner.
  - `deploy/k8s-deployment.yaml`: Kubernetes Deployment (2 replicas) and ClusterIP Service manifest with health probes and secret environment references.
  - `docs/HUMAN_TODO.md`: Exact step-by-step guidance for Supabase project creation, key retrieval, phone OTP setup, and SQL execution.
- **Files**:
  - `api/app/core/auth.py`, `api/app/core/config.py`, `api/tests/unit/test_supabase_auth.py`
  - `supabase/setup.sql`, `api/Dockerfile`, `deploy/k8s-deployment.yaml`
  - `docs/HUMAN_TODO.md`, `docs/PROGRESS.md`
- **Commands & Results**:
  - `powershell -ExecutionPolicy Bypass -File scripts/verify.ps1`: Exit code 0 (All 57 pytest tests passed in 42.05s, Ruff: OK, OpenAPI schema: OK, Mypy: OK on 52 source files, Web typecheck: OK, Vite build: OK).
- **Assumptions**:
  - `AUTH_PROVIDER="dev"` remains default for local development and offline test execution.
  - Setting `AUTH_PROVIDER="supabase"` enables live Supabase JWT verification.
- **Git Commit & Tag**: `d1-done`

---

## F0: Flutter Skeleton (Human Gate)
- **Date**: 2026-10-05
- **Built**:
  - `mobile/`: Complete Flutter mobile application skeleton initialized with package id `in.gov.queueless.mobile` (Flutter 3.44.8, Dart 3.12.2).
  - `mobile/lib/core/theme.dart`: Civic High-Legibility design system faithfully implementing the Google Stitch Mobile project (`projects/16142927226197796836`): Deep Civic Blue (`#0E5A8A`), Primary Soft (`#E3F0F8`), Saffron Accent (`#F4A21F`), Neutral Canvas (`#F6F8FA`), Surface (`#FFFFFF`), solid structural borders (`#D3DCE4`), elevated 18px body typography, and 56px minimum touch targets.
  - `mobile/lib/core/router.dart` & `mobile/lib/main.dart`: Declarative navigation using `go_router` (`/` language selection, `/auth` phone OTP sign-in, `/home` active token screen), wrapped in Riverpod `ProviderScope`.
  - `mobile/lib/api/client.dart`: Typed Dart HTTP client wrapping backend endpoints (`fetchOffices`, `fetchServices`, `bookToken`, `getActiveToken`, `checkIn`, `cancelToken`, `updateLanguage`, `getDevToken`).
  - `mobile/lib/l10n/`: Multilingual localization infrastructure supporting English (`app_en.arb`), Gujarati (`app_gu.arb`), and Hindi (`app_hi.arb`) configured with `l10n.yaml` and `flutter_localizations`.
  - Screens:
    - `LanguageScreen`: First-run language picker with persistent language preference storage in `SharedPreferences`.
    - `LoginScreen`: Phone number input and 6-digit OTP verification.
    - `HomeScreen`: Real-time display of active appointment token with queue position, estimated turn, and empty state.
  - `mobile/test/widget_test.dart`: Automated smoke test verifying application launch, civic branding, and multilingual language options.
  - Concurrency & DB hardening: Fixed date collision in `test_domain_transition_matrix` (`api/tests/domain/test_domain_core.py`) with per-run unique years and pre-cleanup.
- **Files**:
  - `mobile/pubspec.yaml`, `mobile/l10n.yaml`, `mobile/lib/main.dart`
  - `mobile/lib/core/theme.dart`, `mobile/lib/api/client.dart`
  - `mobile/lib/l10n/app_en.arb`, `mobile/lib/l10n/app_gu.arb`, `mobile/lib/l10n/app_hi.arb`
  - `mobile/lib/features/language/language_screen.dart`
  - `mobile/lib/features/auth/login_screen.dart`
  - `mobile/lib/features/home/home_screen.dart`
  - `mobile/test/widget_test.dart`
  - `api/tests/domain/test_domain_core.py`, `docs/PROGRESS.md`
- **Commands & Results**:
  - `flutter analyze` in `mobile/`: No issues found!
  - `flutter test` in `mobile/`: All tests passed!
  - `powershell -ExecutionPolicy Bypass -File scripts/verify.ps1`: Exit code 0 (All 57 pytest tests passed in 42.04s, Ruff: OK, OpenAPI schema: OK, Mypy: OK on 52 source files, Web typecheck & build: OK, Flutter analyze: OK).
- **Assumptions**:
  - Mobile citizen app runs against local FastAPI API with DevAuth persona credentials in development.
- **Git Commit & Tag**: `f0-done`

---

## F1: Citizen App A
- **Date**: 2026-10-05
- **Built**:
  - `mobile/lib/l10n/app_en.arb`, `app_gu.arb`, `app_hi.arb`: Added full localization support for civic centre browsing, service directory, document checklist, mandatory confirmation prompt, booking category selection (Normal vs Priority), and booking confirmation.
  - `mobile/lib/api/client.dart`:
    - Updated active token endpoint to `GET /v1/citizen/tokens/me/active`.
    - Added `priorityDocType`, `travelMinutes`, and `beneficiaryName` parameters to `bookToken`.
    - Added dependency injection support for test execution.
  - `mobile/lib/features/browse/offices_screen.dart`: Implemented civic centres listing screen with operating hours, full address, pull-to-refresh, error recovery, and forward navigation to services.
  - `mobile/lib/features/browse/services_screen.dart`: Implemented service browsing screen with localized titles, average duration chips, indicative queue wait estimates, priority eligibility tags, and online alternative alerts with links to official government portals.
  - `mobile/lib/features/book/book_screen.dart`:
    - Document checklist rendered per Spec Section 2.1 Principle 14 (`service.required_docs`).
    - Mandatory Confirmation Gating: Checkbox with prompt *"I confirm that I have all required original documents ready for this visit."* strictly gates the "Book Fixed Appointment" button (disabled until confirmed).
    - Booking Category Switcher: General vs Priority Access (senior citizens 60+, pregnant mothers, persons with disabilities) with eligibility document selector.
    - Token booking submission with client-generated RFC 4122 v4 UUID idempotency key, confirmation dialog, and redirection to home screen.
  - `mobile/lib/features/home/home_screen.dart`: Added "Book Appointment" CTA button when no active appointment exists, localized UI strings, and navigation.
  - `mobile/lib/main.dart`: Wired all citizen browsing and booking routes (`/offices`, `/offices/:officeId/services`, `/book/:officeId/:serviceId`).
  - `mobile/test/f1_citizen_test.dart`: 7 automated widget tests verifying office listing, service listing, Gujarati translations, document checklist, mandatory confirmation gating, priority mode switching, and Rule 11 touch target dimensions (>= 56px height).
- **Files**:
  - `mobile/lib/l10n/app_en.arb`, `mobile/lib/l10n/app_gu.arb`, `mobile/lib/l10n/app_hi.arb`
  - `mobile/lib/l10n/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_gu.dart`, `app_localizations_hi.dart`
  - `mobile/lib/api/client.dart`
  - `mobile/lib/features/browse/offices_screen.dart`, `mobile/lib/features/browse/services_screen.dart`
  - `mobile/lib/features/book/book_screen.dart`, `mobile/lib/features/home/home_screen.dart`, `mobile/lib/main.dart`
  - `mobile/test/f1_citizen_test.dart`
  - `docs/PROGRESS.md`
- **Commands & Results**:
  - `flutter analyze` in `mobile/`: No issues found!
  - `flutter test` in `mobile/`: All 7 tests passed!
  - `powershell -ExecutionPolicy Bypass -File scripts/verify.ps1`: Exit code 0 (All 57 pytest tests passed in 45.03s, Ruff: OK, OpenAPI schema: OK, Mypy: OK on 52 source files, Web typecheck & build: OK, Flutter analyze: OK).
- **Assumptions**:
  - Offline/Dev testing utilizes DevAuth credentials with fallback to citizen persona dev token.
  - Booking is gated until citizen explicitly confirms document readiness per Spec v3.
- **Git Commit & Tag**: `f1-done`

---

## F2: Citizen App B
- **Date**: 2026-10-05
- **Built**:
  - `mobile/lib/features/home/home_screen.dart`:
    - Full Active Token View: Displays 54px display code, status chip, queue metrics (citizens ahead, now serving token & counter), ETA estimate (`~18 minutes`), live ETA range (`14 – 22 minutes`), and live adjustment reason (`last_eta_reason`).
    - Presence Check-In: Interactive QR modal allowing entrance QR scan/entry and calling `POST /v1/citizen/tokens/{id}/check-in`, updating status to verified.
    - "I'm on My Way" (+5 min) extension: Prominent action button calling `POST /v1/citizen/tokens/{id}/on-my-way`, granting a 5-minute extension on the grace deadline (Spec Section 24), updating status pill to "Extension Claimed", and disabling repeated clicks.
    - Cancellation flow: Outlined cancel button with confirmation dialog calling `POST /v1/citizen/tokens/{id}/cancel` and clearing active view.
    - 20-second automatic polling fallback timer (`Timer.periodic`) per Spec Rule 8.
  - `api/app/routers/citizen.py` & `api/app/schemas/citizen.py`:
    - Added `POST /v1/citizen/tokens/{token_id}/on-my-way` endpoint with role/ownership check, state guard (CALLED/WAITING), single-claim enforcement, `on_my_way_extension_minutes` lookup from `office_settings`, `token_events` audit row logging, and `on_my_way_at` timestamp.
    - Updated `TokenOut` schema and `build_token_out` to include `on_my_way_at`.
  - `mobile/lib/api/client.dart`: Added `onMyWayAt`, `graceDeadline`, and `lastEtaReason` to `TokenModel`, and implemented `onMyWay(...)` client method.
  - `mobile/lib/l10n/app_en.arb`, `app_gu.arb`, `app_hi.arb`: Added localized strings for on-my-way action, extension claimed, arrival verification, cancel confirmation, and ETA window prefixes.
  - `mobile/test/f2_citizen_test.dart`: 4 comprehensive automated widget tests verifying active token metrics rendering, presence check-in lifecycle, on-my-way extension claim and disablement, and appointment cancellation.
  - `api/tests/api/test_routes.py`: Added unit tests for `POST /v1/citizen/tokens/{token_id}/on-my-way` (successful extension, duplicate claim rejection 409).
- **Files**:
  - `mobile/lib/features/home/home_screen.dart`, `mobile/lib/api/client.dart`
  - `mobile/lib/l10n/app_en.arb`, `mobile/lib/l10n/app_gu.arb`, `mobile/lib/l10n/app_hi.arb`
  - `mobile/lib/l10n/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_gu.dart`, `app_localizations_hi.dart`
  - `api/app/routers/citizen.py`, `api/app/schemas/citizen.py`, `api/tests/api/test_routes.py`
  - `openapi/openapi.json`
  - `mobile/test/f2_citizen_test.dart`
  - `docs/PROGRESS.md`
- **Commands & Results**:
  - `flutter analyze` in `mobile/`: No issues found!
  - `flutter test` in `mobile/`: All 11 tests passed!
  - `powershell -ExecutionPolicy Bypass -File scripts/verify.ps1`: Exit code 0 (All 57 pytest tests passed in 63.46s, Ruff: OK, OpenAPI schema: OK, Mypy: OK on 52 source files, Web typecheck & build: OK, Flutter analyze: OK).
- **Assumptions**:
  - "I'm on my way" extension is claimable once per token and extends `grace_deadline` by `on_my_way_extension_minutes` (default 5 min).
- **Git Commit & Tag**: `f2-done`

---

## F3: Push Notifications (Human Gate)
- **Date**: 2026-10-05
- **Built**:
  - `mobile/lib/core/notifications.dart`: Implemented `NotificationService` singleton managing device registration with the backend API, notification stream broadcasting, and mock FCM simulation for local development and offline test environments.
  - `mobile/lib/api/client.dart`: Added `registerDevice(...)` method invoking `POST /v1/devices` with device FCM token, platform, and language preference.
  - `mobile/lib/main.dart`: Initialized `NotificationService` in application lifecycle with notification listeners and in-app alerts with deep linking to active token view.
  - `docs/HUMAN_TODO.md`: Documented exact step-by-step instructions for Firebase project creation (`QueueLess`), Android app registration (`in.gov.queueless.mobile`), `google-services.json` placement, and service account key setup for the backend.
- **Files**:
  - `mobile/lib/core/notifications.dart`, `mobile/lib/api/client.dart`, `mobile/lib/main.dart`
  - `docs/HUMAN_TODO.md`, `docs/PROGRESS.md`
- **Commands & Results**:
  - `flutter analyze` in `mobile/`: No issues found!
  - `flutter test` in `mobile/`: All 11 tests passed!
  - `powershell -ExecutionPolicy Bypass -File scripts/verify.ps1`: Exit code 0 (All 57 pytest tests passed in 43.13s, Ruff: OK, OpenAPI schema: OK, Mypy: OK on 52 source files, Web typecheck & build: OK, Flutter analyze: OK).
- **Assumptions**:
  - In development environments without physical Google Play Services or Firebase credentials, `NotificationService` utilizes simulated local push notifications while registering mock device tokens with the backend `POST /v1/devices` endpoint.
- **Git Commit & Tag**: `f3-done`

---

## PKG: Packaging & Final Deliverables
- **Date**: 2026-10-05
- **Built**:
  - `scripts/seed_demo.py`: Fixed `Counter` entity field (`status="OPEN"`), verified idempotent seeding of full demo office (`ward-central-01`), 4 services, 3 counters, office settings, and staff personas (Officer, Desk, Admin, Citizen).
  - Staff Credentials & Persona Switcher: Fully integrated in React Web login (`web/src/pages/LoginPage.tsx`) with quick-switch role personas and descriptions.
  - `README.md`: Comprehensive system overview, Technical Specification v3 feature summary, ASCII architecture diagram & feedback loop, complete tech stack, staff personas & credentials table, local setup instructions (Python/Postgres API, React Vite Web, Flutter Mobile/Web), automated verification suite guide, and the 13 Core Rules.
  - `demo-script.md`: Detailed live demonstration script and judge walkthrough organized into 5 acts (Citizen mobile onboarding, fixed slot booking with document confirmation gating, Help desk walk-in turn slip printing with thermal slip preview, Public TV lobby board with privacy preservation, Officer operations with dynamic walk-in dispatch and pause audit, and Admin simulation center proving `MAE_Live < MAE_Naive`).
  - Mobile Export Verification: Successfully executed `flutter build web --no-tree-shake-icons`, compiling citizen web fallback to `build\web` in 45.6s.
  - Verification Suite: Master gate `scripts/verify.ps1` runs clean with 0 errors across all 5 checks (Ruff, OpenAPI export, Mypy on 52 files, 57 Pytest tests, Web build, Flutter analyze). All 11 Flutter widget tests passing in `mobile/`.
- **Files**:
  - `scripts/seed_demo.py`
  - `README.md`
  - `demo-script.md`
  - `docs/PROGRESS.md`
- **Commands & Results**:
  - `.\venv\Scripts\python.exe scripts/seed_demo.py`: Exit code 0 (Seeded services, counters, staff personas, and queue state).
  - `flutter build web --no-tree-shake-icons`: Exit code 0 (Built `build\web` in 45.6s).
  - `flutter test`: Exit code 0 (All 11 tests passed).
  - `powershell -ExecutionPolicy Bypass -File scripts/verify.ps1`: Exit code 0 (All 57 pytest tests passed in 37.92s, Ruff: OK, OpenAPI schema: OK, Mypy: OK on 52 source files, Web typecheck & build: OK, Flutter analyze: OK).
- **Assumptions**:
  - Demo environment runs against PostgreSQL database `queueless_dev` with preconfigured mock credentials for evaluator walkthrough.
- **Git Commit & Tag**: `pkg-done`

---

## UI-REDESIGN: Staff Web Dashboard Civic Government-Portal Redesign (Officer Role & App Shell)
- **Date**: 2026-10-09
- **Built**:
  - **1. Shared App Shell (`web/src/components/AppShell.tsx`, `navConfig.ts`, `CivicCrest.tsx`, `officeNames.ts`)**:
    - 260px wide institutional left sidebar on a light background (`var(--color-surface)`), 1px solid border (`var(--color-border)`), with zero dark sidebar styling, no gradients, and no drop shadows. Collapsible to icon-only view below 1280px and sliding off-canvas drawer with backdrop overlay below 1024px.
    - Neutral `CivicCrest` placeholder component (shield, civic columns motif, neutral civic star) easy to customize; displays "QueueLess" and human office name (e.g. "Central Municipal Civic Centre (Sector 11)"), never technical internal IDs like `ward-central-01`.
    - Navigation driven from central configuration (`ROLE_NAVIGATION`) grouped under small uppercase section labels (`WORKSPACE`, `ACTIVITY`, `TOOLS`, `ACCOUNT`). Active item highlighted with `var(--color-primary-soft)` background and a 4px primary left border (`var(--color-primary)`).
    - Compact bottom user card displaying name, role badge, and human office name that navigates directly to My Account; tripartite language switcher (EN, ગુજરાતી, हिन्दी); and sign-out button with a modal confirmation dialog.
    - 4px primary strip across the top edge. Slim top bar with breadcrumb path on the left (`QueueLess / Officer Portal / My queue`); office location chip, live date & clock, and sync pulse indicator on the right. Slim footer displaying civic help desk hotline (`1800-233-0000 · support@queueless.gov.in`), application version (`v1.4.0`), and last sync timestamp.
  - **2. My Queue Screen (`web/src/pages/OfficerQueuePage.tsx`)**:
    - Header with page title, plain descriptive counter selector (e.g. "Counter 1 · Birth certificate, Civic documents"), Open/Break/Closed control requiring mandatory reason selection (Lunch, Official work, System problem, Other) before entering Break or Closed, Report a problem incident modal, and keyboard shortcuts popover.
    - **Single Primary Action Rule**: Header "Call next" is the sole primary action when the counter is idle; disabled with tooltip when a token is Called or Serving. When Called, "Start service" becomes primary. When Serving, "Complete service" becomes primary. All duplicate "Call next" buttons removed.
    - "Next up" strip: displays the recommended token, reason badge (Arrived first, Priority, Appointment time), "Choose another" dialog with mandatory logged override reason, and online appointment buffer indicator.
    - Waiting Card: filter tabs with dynamic count badges (All, Priority, Arrived, Online appointments, Walk-ins); instant search input; interactive rows with priority, arrival, online/walk-in, and pass-over chips; clicking any row opens a slide-over details drawer showing beneficiary details, document checklist with interactive checkboxes, and event timeline.
    - Now Serving Card: Idle state, Called state (live grace period countdown, Start service as primary, Call again, Did not arrive, Release, and priority document check), Serving state (live elapsed timer with 10-minute benchmark, Complete service opening outcome modal with per-person count for group bookings, Transfer, and Check document).
    - Counter check-in: barcode/QR wedge input supporting USB hardware scanners and "Scan with camera" webcam scanner with live targeting viewport.
    - Keyboard shortcuts: `N` (Call next), `S` (Start service), `C` (Complete service), with synthesizer audio chime via Web Audio API.
  - **3. Today's Activity Screen (`web/src/pages/TodayActivityPage.tsx`)**:
    - Audit log of tokens served at the officer's counter today with summary KPI tiles (Tokens Served, Average Service Time, No-Shows), instant search input, outcome filtering (All, SERVED, NO_SHOW, MISSING_DOCS), and read-only audit table with durations and notes.
  - **4. My Account Screen (`web/src/pages/MyAccountPage.tsx`)**:
    - Official profile card with name, designation, department, human office name, shift timing, official email, masked phone, session status, and administrative notice ("Managed by your office admin.").
    - Workstation preferences: language switcher, text size toggle (Normal 15px / Large 17px), acoustic arrival chime toggle with live preview button, and remembered default counter saved to local storage.
    - Security: change password (disabled with dev notice) and sign out with confirmation modal.
  - **5. Route Guards & Automated Tests (`web/src/App.tsx`, `web/tests/portal_layout.test.mjs`)**:
    - Role-based route guards: Officers attempting to access `/admin` or `/desk` are greeted with a clear Access Restricted screen with a single action to return to their portal.
    - Automated unit tests covering navigation per role, human office name formatting without internal IDs, single primary action logic, and route guard matrix.
- **Files**:
  - `web/src/components/CivicCrest.tsx`
  - `web/src/components/navConfig.ts`
  - `web/src/utils/officeNames.ts`
  - `web/src/utils/audio.ts`
  - `web/src/components/AppShell.tsx`
  - `web/src/pages/OfficerQueuePage.tsx`
  - `web/src/pages/TodayActivityPage.tsx`
  - `web/src/pages/MyAccountPage.tsx`
  - `web/src/App.tsx`
  - `web/src/index.css`
  - `web/src/i18n/en.json`
  - `web/src/i18n/gu.json`
  - `web/src/i18n/hi.json`
  - `web/tests/portal_layout.test.mjs`
  - `web/package.json`
  - `api/app/routers/officer.py`
  - `api/app/services/token_service.py`
  - `docs/PROGRESS.md`
- **Commands & Results**:
  - `node --test web/tests/portal_layout.test.mjs`: 4/4 tests passed (navigation config, human office names, single primary action rule, role route guards).
  - `npm run typecheck` in `web/`: Exit code 0 (0 errors).
  - `npm run build` in `web/`: Exit code 0 (Built cleanly in 171ms).
  - `powershell -ExecutionPolicy Bypass -File scripts/verify.ps1`: Exit code 0 (All 57 pytest tests passed in 52.31s, Ruff: OK, OpenAPI schema: OK, Mypy: OK on 52 source files, Web typecheck & build: OK, Flutter analyze: OK).
- **Assumptions**:
  - Web Audio API synthesizer is utilized for audio feedback, avoiding external audio asset dependencies.
- **Git Commit & Tag**: `officer-redesign-done`

---

## UI-ENHANCEMENT: Collapsible/Expandable Left Sidebar with Dedicated User Controls
- **Date**: 2026-10-09
- **Built**:
  - `web/src/components/AppShell.tsx`: Added `sidebarOpen` state persisted in `localStorage` (`ql_sidebar_open`); integrated a universal toggle button (`.btn-sidebar-toggle`) in the top bar with dynamic icon (`menu` / `menu_open`), and a close button (`.btn-sidebar-toggle-close`) in the sidebar header. Users can seamlessly open and close the sidebar whenever desired.
  - `web/src/index.css`: Styled smooth cubic-bezier width and opacity transition for `.gov-sidebar.closed`, expanding the workplace area to 100% full width when closed, while maintaining drawer behavior on viewports below 1024px.
- **Verification**:
  - `npm run typecheck` in `web/`: 0 errors.
  - `npm run build` in `web/`: Built in 166ms.
  - `npm test` in `web/`: 4/4 tests passed.
  - `scripts/verify.ps1`: Exit 0 (All 57 pytest tests passed, Ruff: OK, Mypy: OK, Flutter: OK).
- **Git Commit & Tag**: `sidebar-toggle-done`






