# AGENTS.md — Working Agreement & Architecture Spec

## Working Agreement
1. **Source of Truth**: [docs/spec.md](file:///d:/code_carnival/docs/spec.md) is the primary specification. Section 19 (v1.1 patches) overrides earlier sections. Any discrepancy or proposed deviation must be reported to the developer before proceeding.
2. **Flutter Guidance**: The developer does not know Flutter; explain Flutter commands and files in simple words.
3. **No Docker / Local-First**: PostgreSQL and Python run locally. Tests and reset scripts refuse execution unless database name ends in `_test`.
4. **Scope Control**: No `mobile/`, `api/Dockerfile`, `docker-compose.yml`, `architecture.png`, or `demo-script.md` unless explicitly requested.
5. **Rule 3 Exception**: Flutter and React may open a read-only Supabase Realtime subscription on `queue_state` only. No other direct database access.
6. **Secret Management**: Never commit `.env` or credentials.

---

## Autopilot Rules
A. **Per task**: write a brief plan in `PROGRESS.md`, implement ONLY that task, then run the GATE:
   1. `scripts/verify.ps1` exits 0 on the full suite, not just new tests;
   2. Spec compliance: for each requirement of the task and each relevant spec section, name the file and test that proves it. An unproven requirement means the gate fails;
   3. Run the task's manual check commands and record the real output.
B. **Gate passes**: git commit and tag (`m0-done`, `m1-done`, ...), append to `PROGRESS.md` (what was built, files, commands, results, assumptions), print a 5-line summary, and **START THE NEXT TASK IMMEDIATELY**.
C. **Gate fails**: fix and re-run. Same root cause: 3 attempts max, then STOP with a BLOCKED report (what fails, what you tried, 2 options).
D. Never weaken, delete, skip, or xfail a test to make it pass. Never mark a task done with skipped checks. If something cannot be verified in this environment, say so in `PROGRESS.md`; never claim it passed.
E. Spec conflict or ambiguity: choose the most conservative option consistent with the spec, log it in `DECISIONS.md`, continue. STOP only if the choice would change data integrity, security, or the architecture rules.
F. **HUMAN GATES**: when a task needs something only the developer can do (accounts, keys, SDK installs, a physical phone), do all preparation possible and write exact instructions in `docs/HUMAN_TODO.md`. If later tasks do not depend on it, continue with them. If everything depends on it, STOP and request guidance.
G. **Token discipline**: keep chat output terse. Never paste long logs; summarise counts and show only failing output. At the start of each task re-read `AGENTS.md`, `docs/TASKS.md`, `docs/PROGRESS.md` and ONLY the relevant spec sections, not the whole spec.
H. If context length increases, finish the current task cleanly (commit, update `PROGRESS.md`) and notify the user to start a fresh chat and paste the one-line RESUME prompt.
I. No future features. No unrequested libraries. Secrets never in git.
J. **Auth during development**: build an `AuthProvider` interface with:
   1. `DevAuth`: locally signed JWTs carrying role and office claims, used for all local work and tests;
   2. `SupabaseAuth`: verifies Supabase JWTs, written in task D1.
   Everything must work end to end locally with DevAuth first.

---

## Locked Architecture

```
 ┌──────────────────┐   ┌──────────────────────┐
 │ Flutter app      │   │ Web dashboard         │
 │ (citizens)       │   │ (officer / desk/admin)│
 └───────┬──────────┘   └──────────┬────────────┘
         │ REST (generated clients)│
         │  + realtime signal      │
         ▼                         ▼
 ┌────────────────────────────────────────────┐        ┌─────────────┐
 │ API service (FastAPI)                       │───────▶│ Firebase FCM │ push
 │  routers → services → domain (state machine,│        └──────────────┘
 │  dispatch, priority) → ETA engine → notifier│
 │  /internal/tick  (scheduler entry point)    │
 └───────────────┬────────────────────────────┘
                 │ SQL (transactions, row locks)
                 ▼
 ┌────────────────────────────────────────────┐
 │ Supabase: Postgres + Auth + Realtime + cron │
 │ tables: tokens, token_events, queue_state…  │
 └────────────────────────────────────────────┘
        ▲                 ▲
        │ pg_cron+pg_net  │ writes via same API functions
   every minute → tick    simulator (virtual clock)
```

Feedback loop: **counter events → event log → service-time stats → ETA engine → notifications → citizen arrival behaviour → queue.**

---

## The 13 Core Rules (System Instruction)
*(Adapted from Section 16 of docs/spec.md plus Rule 3 Realtime Exception)*

1. The API owns all business logic. Flutter and web only call generated API clients; never hand-write HTTP calls and never duplicate rules in a client.
2. Never update `tokens.state` directly. Use `transition(token, to_state, actor, ...)`, which validates against `ALLOWED_TRANSITIONS`, writes a `token_events` row, and bumps `queue_state.version`.
3. Every mutating endpoint is one DB transaction. Lock order: `queue_state` → `counters` → `tokens`. Use `FOR UPDATE SKIP LOCKED` for picking the next token. *(Exception: Flutter and React may open a read-only Supabase Realtime subscription on `queue_state` only. No other direct database access).*
4. No `datetime.now()` and no SQL `now()` in business logic. Inject `Clock`.
5. `compute_etas(snapshot)` is a pure function. No DB or network calls inside it.
6. AI/ML calls must have a 300 ms timeout and fall back to the live-adjusted engine. They must never raise into a request.
7. Every user-visible string comes from i18n files (en, gu, hi). Push text comes from server templates by the user's language.
8. Realtime carries only `queue_state` aggregates. Clients refetch their own state from the API.
9. All tunables come from `office_settings`; no magic numbers in code.
10. Write the state-machine, concurrency, and authorization tests before building any UI. After any API change, regenerate OpenAPI and both clients.
11. Citizen UI: big text, icon + label on every button, phone-OTP login only, stay logged in, language picker on first run.
12. Collect minimum data. No Aadhaar numbers anywhere.
13. Safety Rule: Tests and any operation dropping, truncating, or resetting tables must strictly refuse to run unless the database name ends in `_test`.

---

## Section 16 of docs/spec.md (Verbatim)

## 16. Rules to paste into your AI coding tool (system instruction)
1. The API owns all business logic. Flutter and web only call generated API clients; never hand-write HTTP calls and never duplicate rules in a client.
2. Never update `tokens.state` directly. Use `transition(token, to_state, actor, ...)`, which validates against `ALLOWED_TRANSITIONS`, writes a `token_events` row, and bumps `queue_state.version`.
3. Every mutating endpoint is one DB transaction. Lock order: `queue_state` → `counters` → `tokens`. Use `FOR UPDATE SKIP LOCKED` for picking the next token.
4. No `datetime.now()` and no SQL `now()` in business logic. Inject `Clock`.
5. `compute_etas(snapshot)` is a pure function. No DB or network calls inside it.
6. AI/ML calls must have a 300 ms timeout and fall back to the live-adjusted engine. They must never raise into a request.
7. Every user-visible string comes from i18n files (en, gu, hi). Push text comes from server templates by the user's language.
8. Realtime carries only `queue_state` aggregates. Clients refetch their own state from the API.
9. All tunables come from `office_settings`; no magic numbers in code.
10. Write the state-machine, concurrency, and authorization tests before building any UI. After any API change, regenerate OpenAPI and both clients.
11. Citizen UI: big text, icon + label on every button, phone-OTP login only, stay logged in, language picker on first run.
12. Collect minimum data. No Aadhaar numbers anywhere.
