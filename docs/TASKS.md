# QueueLess — Task Queue & Execution Plan

This document defines the formal task queue for QueueLess development, including scope, acceptance criteria, and gate requirements for each milestone.

---

## M0: Foundation (In Progress)
- **Scope**:
  - API skeleton (`api/app/main.py`), endpoints `/healthz` (process alive) and `/readyz` (DB reachable).
  - Async SQLAlchemy 2.x + asyncpg, Alembic configured for async migrations.
  - Web skeleton (React + TypeScript + Vite) in `web/`.
  - `_test` database safety guard (`assert_test_database`) in `api/app/core/safety.py`.
  - `.env` handling (`DATABASE_URL`, `TEST_DATABASE_URL`, etc.).
  - Verification of Alembic with an empty migration (`upgrade head`, `downgrade base`) and deletion.
  - **No `mobile/` creation in this task.**
- **Acceptance Criteria**:
  - `/healthz` returns `{"status": "ok"}`.
  - `/readyz` connects to DB and returns `{"status": "ready"}`.
  - Web skeleton builds cleanly with `npm run build` and runs typecheck with `npm run typecheck` (or `tsc`).
  - Empty Alembic migration upgrades and downgrades without error.
  - Safety guard blocks any drop/truncate/reset on non-`_test` DB.
- **Gate**:
  - `powershell -ExecutionPolicy Bypass -File scripts/verify.ps1` exits 0.

---

## M1: Database
- **Scope**:
  - Full schema per spec Section 4 + Section 19.5.
  - Tables: `offices`, `office_settings`, `services`, `counters`, `counter_services`, `profiles`, `queue_state`, `tokens`, `token_events`, `allowed_transitions`, `service_stats`, `counter_service_stats`, `office_calendar`, `eta_log`, `priority_checks`, `devices`, `notification_outbox`, `idempotency_keys`, `counter_events`.
  - Postgres ENUMs, partial unique indexes, constraints.
  - Trigger for transition validation against `allowed_transitions`.
  - Trigger making `token_events` append-only (blocks UPDATE/DELETE).
  - Seed for `allowed_transitions`.
  - Demo seed (Municipal Ward Office, 4 services, 3 counters, spec defaults).
  - Supabase-only SQL (RLS, Supabase Auth hook triggers) isolated in `api/supabase_only/`.
- **Acceptance Criteria**:
  - All migrations apply cleanly on dev and test databases.
  - Seed data loads idempotently.
  - Direct updates to `token_events` or invalid moves on `tokens` fail at DB level.
- **Gate**:
  - Full pytest suite passes including:
    - 8x8 state transition matrix test.
    - 50-parallel-transaction numbering test.
  - `scripts/verify.ps1` exits 0.

---

## M2a: Domain Core
- **Scope**:
  - `Clock` abstraction (SystemClock and VirtualClock).
  - SQLAlchemy models for core domain.
  - `transition()` domain function (validates against ALLOWED_TRANSITIONS, updates token, writes `token_events`, bumps `queue_state.version`).
  - Booking service with atomic numbering (`FOR UPDATE` on `queue_state`) and `Idempotency-Key` deduplication.
  - Cancellation service, one-active-token rule per phone per service, priority claim handling.
- **Acceptance Criteria**:
  - No direct SQL `now()` or Python `datetime.now()` in business logic.
  - Lock order strictly `queue_state` → `counters` → `tokens`.
- **Gate**:
  - 200 parallel bookings yield unique, gapless `seq` numbers.
  - Double-submit with same `Idempotency-Key` returns identical stored response without duplicate token.
  - Full transition matrix test via `transition()`.
  - `scripts/verify.ps1` exits 0.

---

## M2b: Officer Operations
- **Scope**:
  - `call-next` per spec 6.5 with Section 19.2 arrived-first dispatch, priority interleave (1-in-N), `FOR UPDATE SKIP LOCKED`.
  - Counter guards: cannot close counter with active serving token; counter status updates.
  - Token actions: `start`, `complete` (with Section 19.5 `outcome_code`), `no-show`, `release`, `transfer`.
  - Priority check with strikes (strike limit blocks priority claims).
  - Assisted and walk-in desk booking (`created_via=ASSISTED/WALKIN`, `arrived_at=created_at`).
  - Check-in with HMAC-signed QR verification.
- **Acceptance Criteria**:
  - Parallel `call-next` across counters returns distinct tokens without race conditions.
  - Arrived citizens within dispatch window prioritized; pass-over count tracked.
- **Gate**:
  - Parallel dispatch test, priority interleave test, pass-over test, strike limit test.
  - `scripts/verify.ps1` exits 0.

---

## M2c: HTTP Layer & API
- **Scope**:
  - All P0 citizen, officer, desk, and admin endpoints from spec Section 6 & 19.6.
  - `DevAuth` provider (locally signed JWTs with role and office claims) and role guards.
  - Office scoping: officer can only see/act in their own office; citizen only their tokens.
  - Unified error schema with machine-readable codes.
  - Export OpenAPI schema to `openapi/openapi.json`.
- **Acceptance Criteria**:
  - Full route authorization matrix passes.
  - `openapi.json` is exported and up-to-date.
- **Gate**:
  - Auth matrix tests pass.
  - `scripts/verify.ps1` exits 0.

---

## M3: ETA Engine
- **Scope**:
  - Pure function `compute_etas(snapshot)`.
  - Naive engine (baseline).
  - Live-adjusted greedy schedule engine with Section 19.3 overrun rule (`remaining_i = 0.5 * mean` when `elapsed > mean`).
  - Prediction intervals (ranges) and counterfactual reason codes (`SLOW_CASE`, `COUNTER_DOWN`, etc.).
  - `eta_log` recording on booking.
  - Section 19.1 admission control (`409 QUEUE_FULL_FOR_TODAY`).
- **Acceptance Criteria**:
  - Zero DB or network calls inside `compute_etas`.
  - Property tests (Hypothesis) verify monotonicity and counter effects.
- **Gate**:
  - Hypothesis test suite passes; golden examples match.
  - `scripts/verify.ps1` exits 0.

---

## M4: Scheduler and Notifications
- **Scope**:
  - `POST /internal/tick` (guarded by secret + Postgres advisory lock, idempotent).
  - Sweeps: no-show sweep (with auto-requeue or cancel), office expiry sweep.
  - ETA pass over active queues.
  - Notification ladder (`TOKEN_CONFIRMED`, `GET_READY`, `LEAVE_NOW`, `YOUR_TURN`, `ETA_CHANGED`, `NO_SHOW_WARNING`).
  - `notification_outbox` with deduplication and log-based sender (simulating FCM delivery).
  - Localized templates in en, gu, hi.
- **Acceptance Criteria**:
  - Tick is fully idempotent when called repeatedly.
  - Notifications deduplicated by key.
- **Gate**:
  - Tick idempotency tests pass.
  - `scripts/verify.ps1` exits 0.

---

## M5: Simulator and Reports
- **Scope**:
  - Virtual-clock simulation runner (`app/sim/`) running against real domain services in an `is_simulation` office.
  - Scenario configuration (arrival curves, service times, priority %, breaks).
  - Admin simulation endpoints (`/v1/admin/sim/*`) disabled in production config.
  - Reporting endpoints: summary, load-by-hour, ETA accuracy (MAE, within-range %, vs naive).
- **Acceptance Criteria**:
  - Live-adjusted engine achieves lower MAE than naive on seeded simulated day.
- **Gate**:
  - Simulation regression test passes.
  - `scripts/verify.ps1` exits 0.

---

## M6a: Web Foundation & Officer Screens
- **Scope**:
  - Generated TypeScript client from `openapi/openapi.json`.
  - DevAuth login selector for rapid testing.
  - App shell, layout, `react-i18next` (en, gu, hi).
  - Officer queue screen with live actions (call-next, start, complete, no-show, release, transfer).
  - Counter status toggle.
- **Acceptance Criteria**:
  - Officer workflow executable in browser against local API.
- **Gate**:
  - Web typecheck and build pass.
  - `scripts/verify.ps1` exits 0.

---

## M6b: Web Remainder & Polish
- **Scope**:
  - Desk assisted booking with printable slip preview.
  - Priority check modal.
  - Admin CRUD for offices, services, counters, settings.
  - Reports dashboard with Recharts.
  - Simulation control panel.
  - Public lobby display board (`/display/:officeId`).
- **Acceptance Criteria**:
  - Complete end-to-end token lifecycle operable in browser.
- **Gate**:
  - Automated browser smoke test passes.
  - `scripts/verify.ps1` exits 0.

---

## D1: Supabase & Deploy Prep (Human Gate)
- **Scope**:
  - Setup instructions in `docs/HUMAN_TODO.md` for Supabase project creation.
  - Supabase-only SQL applied to Supabase project.
  - `SupabaseAuth` provider implementation alongside `DevAuth`.
  - Realtime subscription setup on `queue_state`.
  - `pg_cron` + `pg_net` configuration.
  - API Dockerfile and deployment manifest.

---

## F0: Flutter Skeleton (Human Gate)
- **Scope**:
  - Flutter SDK & Android tooling guidance for beginner in `docs/HUMAN_TODO.md` and `PROGRESS.md`.
  - Project setup with Riverpod, go_router, generated Dart API client.
  - i18n setup with ARB files and bundled Gujarati/Devanagari fonts.

---

## F1: Citizen App A
- **Scope**:
  - Language picker on first run.
  - Auth flow (phone OTP).
  - Office and service browsing with document checklist and required confirmation tick.
  - Booking token.

---

## F2: Citizen App B
- **Scope**:
  - Live token screen (active token as home screen).
  - Realtime signal + refetch with 20s polling fallback.
  - ETA range and reasons display.
  - Cancel token, QR check-in, "I'm on my way" extension.

---

## F3: Push Notifications (Human Gate)
- **Scope**:
  - Firebase Cloud Messaging project configuration in `docs/HUMAN_TODO.md`.
  - Device token registration (`POST /v1/devices`).
  - Push handler and deep linking.

---

## PKG: Packaging & Final Deliverables
- **Scope**:
  - Demo seed and staff credentials page.
  - `README.md`, `demo-script.md`, architecture diagram.
  - Android APK build & Flutter web fallback build.
  - Final submission checklist.
