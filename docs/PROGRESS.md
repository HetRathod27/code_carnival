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
- **Status**: Starting immediately per Autopilot Rules.
- **Plan**:
  1. Write M1 Alembic migration defining full schema per spec Section 4 & 19.5:
     - Enums: `token_state_enum`, `category_enum`, `priority_status_enum`, `counter_status_enum`, `actor_type_enum`, `outcome_code_enum`, `calendar_status_enum`.
     - Tables: `offices`, `office_settings`, `services`, `counters`, `counter_services`, `profiles`, `queue_state`, `tokens`, `token_events`, `allowed_transitions`, `service_stats`, `counter_service_stats`, `office_calendar`, `eta_log`, `priority_checks`, `devices`, `notification_outbox`, `idempotency_keys`, `counter_events`.
     - Constraints & partial unique index: `(phone, service_id) WHERE state IN ('WAITING','CALLED','SERVING')`.
     - Triggers: transition validation against `allowed_transitions`; append-only protection on `token_events`.
     - Seed `allowed_transitions` table.
  2. Implement idempotent demo seed script/migration for Municipal Ward Office (4 services, 3 counters, default settings).
  3. Create test suite in `api/tests/database/`:
     - 8x8 transition matrix test (valid transitions allowed, invalid rejected by DB trigger).
     - 50-parallel-transaction numbering test on `queue_state`.
     - `token_events` append-only trigger test (UPDATE/DELETE rejected).
  4. Run `scripts/verify.ps1`, verify gate passes, commit, and tag `m1-done`.
