# QueueLess — Technical Specification v1
PS-02: predict waiting time at government offices + remote virtual tokens.
Purpose of this file: (1) the architecture to show mentors, (2) the spec you feed your AI coding tool. Phases: **P0** = needed for the ~70% prototype, **P1** = after prototype, **P2** = stretch / post-funding.

---

## 1. Design principles (the rules everything else follows)

1. **One API owns all business rules.** Flutter app and web dashboard are thin clients. No queue logic in any UI.
2. **Postgres is the source of truth and the backstop.** The API enforces rules; the database also refuses invalid data (constraints, transition table), so a bug cannot corrupt the queue.
3. **Every state change goes through one function** (`transition()`), which validates the move, writes an event row, and bumps the queue version. Nothing updates `tokens.state` directly.
4. **AI never sits in the critical path.** ETA ML, voice, document check are optional modules with timeouts and fallbacks. If all AI is down, the queue still works on the baseline ETA.
5. **Time is injected, never read directly.** All code uses a `Clock` object; SQL business logic never uses `now()`. This makes the fast-forward simulation use the *real* code.
6. **ETA is a pure function of a snapshot.** `compute_etas(snapshot) → results`. Testable, replayable, shared by production and simulation.
7. **Signal + refetch for live updates.** Realtime only says "queue X changed". Clients then fetch their own authoritative state from the API. No personal data travels over realtime.
8. **Config over code.** Grace minutes, priority ratio, requeue offset, etc. live in settings tables.

---

## 2. Architecture

```
 ┌──────────────────┐   ┌──────────────────────┐
 │ Flutter app      │   │ Web dashboard         │
 │ (citizens)       │   │ (officer / desk/admin)│
 └───────┬──────────┘   └──────────┬────────────┘
         │ REST (generated clients)│
         │  + realtime signal      │
         ▼                         ▼
 ┌────────────────────────────────────────────┐        ┌──────────────┐
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

Feedback loop to explain to mentors: **counter events → event log → service-time stats → ETA engine → notifications → citizen arrival behaviour → queue.**

---

## 3. Final tech stack, per component

### 3.1 Citizen app — Flutter (Dart 3)
| Concern | Choice | Why |
|---|---|---|
| UI framework | Flutter, Android first (APK) + Flutter web build as demo fallback | One codebase; judges can open the web build if they can't install the APK |
| State mgmt | Riverpod | Predictable, AI generates it reliably |
| Navigation | go_router | Declarative, deep links from push notifications |
| API client | Generated from the API's OpenAPI spec (`openapi-generator`, dart-dio) | Contract-first; no hand-written HTTP |
| Auth + realtime | `supabase_flutter` (phone OTP session, subscribe to `queue_state`) | Session persistence, one SDK |
| Push | `firebase_messaging` + `flutter_local_notifications` | Reliable background delivery on Android; free |
| QR check-in | `mobile_scanner` | Camera scan of office QR |
| Local storage | `flutter_secure_storage`, `shared_preferences` | Session + language + last token cache |
| Languages | `intl` + gen-l10n (ARB files: en, gu, hi); bundle Noto Sans Gujarati / Devanagari fonts | Correct script rendering on low-end phones |
| Connectivity | `connectivity_plus` | Show "last updated X min ago" offline |

UX rules for this audience: language picker on first launch; ≥18sp body text; icon + word on every button; max 3 taps from app open to token; token screen is the home screen when a token is active; login by phone OTP only (no Google/email); stay logged in.

### 3.2 Officer / Desk / Admin dashboard — React + TypeScript (Vite SPA)
| Concern | Choice | Why |
|---|---|---|
| Framework | React 18 + TypeScript + Vite (SPA, not Next.js) | Internal tool behind login; no SEO or SSR needed; simplest to deploy as static files |
| UI | Tailwind + shadcn/ui | Fast, consistent, AI-friendly |
| Data fetching | TanStack Query | Caching, refetch-on-signal, retries |
| API client | `openapi-typescript` + `openapi-fetch` (generated types) | Contract-first |
| Auth + realtime | `supabase-js` (email/password for staff, subscribe to `queue_state`) | Same signal mechanism as the app |
| Charts | Recharts | Wait-time and accuracy charts |
| i18n | react-i18next (en, gu, hi) | Officers may prefer Gujarati |
| Hosting | Any static host (Cloudflare Pages / Vercel / Netlify free tiers — verify current limits) | |

### 3.3 API service — Python 3.12 + FastAPI
| Concern | Choice | Why |
|---|---|---|
| Framework | FastAPI + Pydantic v2 | Auto OpenAPI → generated typed clients for Dart and TS |
| DB access | SQLAlchemy 2.x (async) + asyncpg; raw SQL allowed for the hot queries | `FOR UPDATE SKIP LOCKED`, explicit transactions |
| Migrations | Alembic (includes RLS, triggers, constraints) | One versioned source of truth for schema |
| Auth | Verify Supabase JWT in a dependency; role + office_id read from `app_metadata` claims | Roles can't be edited by users |
| Push | `firebase-admin` (FCM) | Free |
| ML | scikit-learn / LightGBM, model file loaded at startup | Python-native, small artifact |
| Tests | pytest, pytest-asyncio, httpx; Hypothesis for ETA properties | Concurrency + transition-matrix tests |
| Lint/types | ruff, mypy | Keeps AI-generated code consistent |
| Packaging | Docker image | Host is swappable (Cloud Run / Render / etc.; verify free limits and cold-start behaviour before the demo) |

Connection gotcha: use Supabase's pooler connection string (direct connections are IPv6-only on many hosts). If you use the transaction-mode pooler, disable asyncpg's prepared-statement cache (`statement_cache_size=0`).

### 3.4 Database + auth + realtime + scheduler — Supabase (Postgres)
- **Postgres:** all data, constraints, triggers.
- **Auth:** citizens = phone OTP; staff = email + password created by admin through the API (service role). Roles: `CITIZEN`, `OFFICER`, `DESK`, `ADMIN` stored in `app_metadata`.
- **OTP in demo:** use Supabase's configured test phone numbers with a fixed OTP. Real SMS needs a paid provider (in India, DLT sender/template registration applies) → P2. **Plan B** if phone auth blocks you: own `otp_codes` table + API-issued JWT.
- **Realtime:** only the `queue_state` table is published (aggregate numbers, no personal data).
- **Scheduler:** `pg_cron` every minute calls the API's `/internal/tick` via `pg_net` with a shared secret. This also wakes a sleeping free-tier API. Fallback: external free pinger hitting `/internal/tick`.
- **Free plan facts (checked 2026 sources):** 500 MB DB, 200 concurrent realtime connections, 2M realtime messages/month, **projects pause after 7 days of inactivity** → open the dashboard before every demo and keep the tick running. Scale path: Pro plan ($25/mo, no pausing, 500 realtime connections), later bigger managed Postgres.

### 3.5 Push notifications — Firebase Cloud Messaging only
Firebase is used **only** for push. Device tokens stored in `devices`. Android OEM battery-saver can delay push → in-app prompt to allow background activity, plus the in-app inbox and 20-second polling fallback while the app is open. SMS fallback = P2.

### 3.6 ETA / ML — module inside the API (`app/eta/`), splittable later
Three engines behind one interface (see §8). Offline training script in `ml/` using simulator + logged data.

### 3.7 Simulator — module inside the API (`app/sim/`)
Runs against the real service layer with a virtual clock, in a flagged simulation office. See §9.

### 3.8 DevOps
Monorepo, GitHub Actions (ruff, mypy, pytest, export OpenAPI, fail if generated clients are stale), `.env` files never committed, Supabase service-role key only on the API server.

---

## 4. Data model

All times are `timestamptz`; `business_date` is the date in the office's timezone (default Asia/Kolkata).

| Table | Key columns | Notes |
|---|---|---|
| `offices` | id, name, address, timezone, open_time, close_time, qr_secret, is_simulation, active | `qr_secret` signs check-in QR |
| `office_settings` | office_id, grace_minutes (5), priority_every_n (3), requeue_offset (5), max_requeues (1), close_grace_minutes, max_active_tokens_per_phone (1), strike_limit (3) | All tunables here |
| `services` | id, office_id, code ("BC"), names jsonb {en,gu,hi}, prior_avg_minutes, required_docs jsonb, priority_allowed, active | `prior_avg_minutes` seeds stats |
| `counters` | id, office_id, label, status (`OPEN`/`BREAK`/`CLOSED`), officer_id | |
| `counter_services` | counter_id, service_id | many-to-many |
| `profiles` | id (= auth user), role, office_id (staff), phone, name?, language, priority_strikes, priority_blocked_until | Created by DB trigger on signup (role CITIZEN) |
| `queue_state` | office_id, service_id, business_date, last_seq, calls_since_priority, now_serving, waiting_count, version, updated_at | **One row per queue per day.** Lock row for numbering/dispatch + realtime signal. PK (office, service, date) |
| `tokens` | id, office_id, service_id, business_date, seq, display_code, citizen_id?, phone?, category, priority_status, created_via, state, sort_key, travel_minutes, counter_id, arrived_at, called_at, grace_deadline, serving_started_at, completed_at, requeue_count, parent_token_id, last_eta_minutes, last_eta_reason, eta_features jsonb | See constraints below |
| `token_events` | id, token_id, from_state, to_state, actor_type, actor_id, counter_id, at, meta jsonb | Append-only (trigger blocks UPDATE/DELETE). Audit trail + ML training data |
| `allowed_transitions` | from_state, to_state, actor_type | Backstop; trigger on `tokens` rejects moves not listed |
| `service_stats` | service_id, hour_bucket, ewma_minutes, ewma_var, n | Updated on every COMPLETED |
| `eta_log` | token_id, at, engine, predicted_p50, low, high, naive_p50 | For accuracy report (predicted vs actual) |
| `priority_checks` | token_id, officer_id, doc_type, result (`VERIFIED`/`REJECTED`), at | |
| `devices` | user_id, fcm_token, platform, language | |
| `notification_outbox` | id, token_id, user_id, kind, payload, dedupe_key UNIQUE, status, attempts, send_after | Reliable, de-duplicated sending |
| `idempotency_keys` | key, user_id, endpoint, response jsonb, created_at | Double-tap protection |
| `counter_events` | counter_id, status, at, actor | Feeds ETA reasons + analytics |

**Constraints that carry the guarantees**
- `UNIQUE (office_id, service_id, business_date, seq)` → no duplicate token numbers.
- Partial unique index `(phone, service_id) WHERE state IN ('WAITING','CALLED','SERVING')` → one active token per phone per service.
- `state`, `category`, `priority_status` are Postgres ENUMs.
- Trigger on `tokens`: `(OLD.state, NEW.state)` must exist in `allowed_transitions`.
- Index `(office_id, service_id, business_date, state, sort_key)` for fast "next waiting" queries.
- RLS enabled on every table; **no policies** except `SELECT` on `queue_state` for `authenticated`. The API uses a server-side connection, so *authorization lives in the API* and is covered by tests.

**`sort_key`** = creation time as epoch seconds (numeric). Normal order = ascending `sort_key`. Requeue/postpone assign a value between two neighbours. Rejected priority claims keep their original `sort_key` (they land where they'd have been as a normal booking).

Display code = `service.code + zero-padded seq` (e.g. `BC-047`). Priority tokens look identical to the citizen and others; officers see a flag.

---

## 5. Token state machine

States: `WAITING, CALLED, SERVING, COMPLETED, CANCELLED, EXPIRED, NO_SHOW, TRANSFERRED`.
`arrived_at` is a timestamp, **not** a state (a remote citizen can be called before arriving). "Approaching" is a notification flag, not a state.

| From → To | Trigger | Actor | Side effects |
|---|---|---|---|
| (new) → WAITING | Book token | CITIZEN / DESK | seq assigned, ETA stored, `TOKEN_CONFIRMED` push |
| WAITING → CALLED | Call next | OFFICER | counter set, `grace_deadline = now + grace`, `YOUR_TURN` push |
| CALLED → SERVING | Start | OFFICER | `serving_started_at` |
| SERVING → COMPLETED | Complete | OFFICER | `completed_at`, update `service_stats`, close event |
| WAITING → CANCELLED | Cancel | CITIZEN / DESK | waiting_count−1, ETAs refresh |
| CALLED → CANCELLED | Cancel | CITIZEN / OFFICER | same |
| WAITING → EXPIRED | Office closed | SYSTEM (tick) | `EXPIRED` push ("please book again") |
| CALLED → NO_SHOW | Grace passed or officer marks | SYSTEM / OFFICER | logged |
| NO_SHOW → WAITING | Requeue (if `requeue_count < max_requeues`) | SYSTEM | `requeue_count+1`, `sort_key` = `requeue_offset` positions behind head, `REQUEUED` push |
| NO_SHOW → CANCELLED | Requeue limit reached | SYSTEM | `CANCELLED` push |
| CALLED → WAITING | Release (counter problem) | OFFICER | keeps `sort_key` (no penalty) |
| CALLED/SERVING → TRANSFERRED | Wrong counter/service/docs | OFFICER | creates new token in target service (`parent_token_id`), optionally carrying the original `sort_key` |

Any other move is rejected by `transition()` and by the DB trigger.

---

## 6. Function catalogue — how every function is managed

Conventions: every mutating endpoint runs in **one DB transaction**. **Lock order (always): `queue_state` row → `counters` row → `tokens` rows**, to avoid deadlocks. Time comes from `Clock`. All POST bodies are Pydantic-validated; all errors use one error schema with a machine-readable `code`.

### 6.1 Citizen functions
| # | Function | Endpoint | How it is managed | Phase |
|---|---|---|---|---|
| C1 | Login | Supabase phone OTP | JWT → API verifies; first login creates profile | P0 |
| C2 | Browse offices/services | `GET /v1/offices`, `/offices/{id}/services` | Returns each service with an *indicative* wait (engine run for a hypothetical tail token) and the document checklist | P0 |
| C3 | Book token | `POST /v1/tokens` (+ `Idempotency-Key` header) | See §6.4 | P0 |
| C4 | View live token | `GET /v1/tokens/{id}`, `/tokens/me/active` | Returns state, position, ETA {low,p50,high}, reason, leave_at, now_serving, counter, `server_time`. Realtime signal triggers refetch (debounced ~1 s); poll every 20 s as fallback | P0 |
| C5 | Cancel token | `POST /v1/tokens/{id}/cancel` | Owner check → lock queue_state, token → `transition()` → waiting_count−1, version+1 | P0 |
| C6 | Check in | `POST /v1/tokens/{id}/check-in` | Verifies signed office QR; sets `arrived_at`; no state change; officer sees "arrived" flag | P0 |
| C7 | Register device for push | `POST /v1/devices` | Upserts FCM token + language | P0 |
| C8 | Postpone ("let others go first") | `POST /v1/tokens/{id}/postpone {positions}` | New `sort_key` behind N tokens; max 2 times | P1 |
| C9 | History | `GET /v1/tokens/me/history` | Paginated | P1 |
| C10 | Book on behalf of family | `POST /v1/tokens` with `on_behalf_of` | Notifications go to booker; beneficiary name on token | P1 |
| C11 | Change language | `PATCH /v1/me` | Server notification templates follow it | P0 |

### 6.2 Officer / desk functions
| # | Function | Endpoint | How it is managed | Phase |
|---|---|---|---|---|
| O1 | View my queue | `GET /v1/counters/{id}/queue` | Scoped to officer's office; shows category, priority status, arrived flag, wait so far | P0 |
| O2 | Set counter status | `POST /v1/counters/{id}/status` | Writes `counter_events`; changes `effective_counters` → ETAs recalc with reason `COUNTER_DOWN/UP` | P0 |
| O3 | Call next | `POST /v1/counters/{id}/call-next` | See §6.5 | P0 |
| O4 | Start / Complete | `POST /v1/tokens/{id}/start`, `/complete` | `transition()`; complete feeds `service_stats` | P0 |
| O5 | No-show / Release | `POST /v1/tokens/{id}/no-show`, `/release` | Manual version of the tick sweep | P0 |
| O6 | Priority check | `POST /v1/tokens/{id}/priority-check {doc_type, result}` | `VERIFIED` stays priority. `REJECTED` → category NORMAL, strike added; at `strike_limit` priority claims are blocked for that phone for a period | P0 |
| O7 | Assisted / walk-in booking | `POST /v1/desk/tokens {name?, phone?, service_id, category}` | Same booking path with `created_via=ASSISTED/WALKIN`; phone optional; returns printable slip data (code + QR). Covers no-smartphone citizens | P0 |
| O8 | Transfer | `POST /v1/tokens/{id}/transfer {to_service_id, carry_over}` | Old → TRANSFERRED, new token created in same transaction | P1 |
| O9 | Re-announce | `POST /v1/tokens/{id}/recall` | Resend `YOUR_TURN`, extend grace once | P1 |

### 6.3 Admin functions
| # | Function | Endpoint | How it is managed | Phase |
|---|---|---|---|---|
| A1 | Office / service / counter CRUD, counter↔service mapping | `/v1/admin/...` | Validated; services need `prior_avg_minutes`; audit log | P0 |
| A2 | Create officer/desk accounts | `POST /v1/admin/staff` | Service-role call creates auth user, sets `app_metadata {role, office_id}` | P0 |
| A3 | Office settings | `PUT /v1/admin/offices/{id}/settings` | Grace, priority ratio, requeue offset, close rules | P0 |
| A4 | Reports | `GET /v1/admin/reports/summary`, `/eta-accuracy`, `/load-by-hour` | SQL aggregates over `token_events` and `eta_log` (see §10) | P0 |
| A5 | Doc checklists | in service CRUD | Shown in app at booking | P1 |

### 6.4 Booking (C3, O7) — atomic numbering, one transaction
```
BEGIN
  if Idempotency-Key seen -> return stored response
  validate: office open?, service active?, category allowed?,
            priority not blocked?, phone under active-token limit?
  INSERT queue_state ... ON CONFLICT DO NOTHING;          -- ensure row exists
  SELECT ... FROM queue_state WHERE (office,service,date) FOR UPDATE;
  seq = last_seq + 1
  INSERT tokens (..., seq, display_code, sort_key = clock.now_epoch, state='WAITING')
        -- partial unique index -> 409 if phone already has an active token here
  UPDATE queue_state SET last_seq=seq, waiting_count+=1, version+=1
  INSERT token_events; INSERT notification_outbox(TOKEN_CONFIRMED);
  snapshot = load_snapshot(); eta = compute_etas(snapshot)[token]; INSERT eta_log
  INSERT idempotency_keys(response)
COMMIT
```
Two people booking at the same moment serialize on the `queue_state` row → different numbers, always. Double tap → same stored response, one token.

### 6.5 Call next (O3) — no double-assignment, priority interleave
```
BEGIN
  svc = chosen service (officer param, else the mapped service whose head token has waited longest)
  SELECT ... FROM queue_state WHERE ... FOR UPDATE;
  SELECT counter FOR UPDATE;
  require counter.status = OPEN and no token CALLED/SERVING at this counter else 409
  pool = PRIORITY if (calls_since_priority >= priority_every_n - 1 and priority waiting)
         or (no normal waiting and priority waiting)
         else NORMAL
  token = SELECT ... WHERE state='WAITING' AND pool matches
          ORDER BY sort_key LIMIT 1 FOR UPDATE SKIP LOCKED
  transition(token, CALLED, counter, grace_deadline = now + grace)
  calls_since_priority = 0 if pool=PRIORITY else +1
  UPDATE queue_state SET now_serving, waiting_count-=1, version+=1
  INSERT outbox(YOUR_TURN)
COMMIT
-- after commit: re-evaluate notification ladder for the next 15 waiting tokens
```
Priority claim counts as priority *immediately* (so a pregnant woman is not delayed waiting for a check); the document is verified at arrival/counter (O6). "Priority first" vs "1 in N" is a setting; an optional reserved priority counter is P1.

### 6.6 Scheduler tick (`POST /internal/tick`, every minute, idempotent)
Guarded by a Postgres advisory lock so only one tick runs. Uses `SKIP LOCKED` in sweeps.
1. **No-show sweep:** CALLED tokens with `grace_deadline <= now` and no `serving_started_at` → NO_SHOW → requeue or cancel (two logged transitions in one transaction).
2. **Expiry sweep:** offices past `close_time + close_grace` → WAITING → EXPIRED.
3. **Counter schedule:** apply scheduled breaks.
4. **ETA pass:** per active queue, one snapshot → `compute_etas` for all waiting tokens → notification ladder (§7) → write `last_eta_*`.
5. **Flush outbox:** send via FCM; mark sent/failed; retry up to 3 times with backoff.
6. **Stats housekeeping.**
Resolution is one minute, which is fine for 5-minute grace periods.

### 6.7 Check-in QR
Payload = `{office_id, window, hmac}` where `hmac = HMAC(office.qr_secret, office_id + window)`. MVP: static window. P1: window rotates every 5 minutes and the QR is shown on a lobby/officer screen, so a photo of the QR can't be used from home. P2: optional geofence.

---

## 7. Notifications

| Kind | When | Dedupe key |
|---|---|---|
| `TOKEN_CONFIRMED` | on booking | token+kind |
| `GET_READY` | ETA p50 ≤ 15 min | token+kind |
| `LEAVE_NOW` | `now ≥ leave_at`, where `leave_at = ETA_p50 − travel_minutes − 5` | token+kind |
| `YOUR_TURN` | on call | token+kind+call_count |
| `ETA_CHANGED` | `|Δ| ≥ max(10 min, 25%)`; at most one per 10 min per token | token+kind+10-min bucket |
| `NO_SHOW_WARNING` | grace running out | token+kind |
| `REQUEUED` / `CANCELLED_BY_SYSTEM` / `EXPIRED` | on those transitions | token+kind |

- Written to `notification_outbox` inside the same transaction as the state change (no lost or duplicate messages).
- Text comes from server-side templates in en/gu/hi chosen by `devices.language`; no hardcoded strings anywhere.
- `travel_minutes` is picked in the app as a bucket (<10, 10–20, 20–40, 40+). Location-based travel time = P2.
- In-app inbox shows the same messages so nothing is lost if push is delayed.

---

## 8. ETA engine (`app/eta/`)

**Interface:** `compute_etas(snapshot) -> {token_id: EtaResult(p50, low, high, reason, engine_version)}`. Pure function, no DB calls inside.

**Snapshot:** `now`, waiting tokens in dispatch order (category, arrived, requeue_count), tokens in service (elapsed time), counters (effective open count per service), service stats (EWMA mean/variance for this hour bucket), settings (`priority_every_n`), historical priority arrival rate.

**Engines (fallback chain):**
1. **Naive (always computed, for benchmarking and fallback):** `p50 = tokens_ahead × avg_service_minutes ÷ open_counters`.
2. **Live-adjusted (P0 default):** an exact version of "workload ahead ÷ counters":
   - Build the *dispatch order* using the priority rule (so priority jumpers are accounted for).
   - Each effective counter becomes free at `remaining_i = max(mean − elapsed, 1 min)`; others at `now`.
   - Greedy schedule: assign each next token to the earliest-free counter with expected service time = EWMA mean for (service, hour bucket). The start time of your token is your ETA.
   - If no counter is effectively open: ETA = `PAUSED` with reason `COUNTER_DOWN`.
   - Range: P0 fixed ±20%; P1 band from the rolling relative error (P80) of the last 50 completions, clamped to 15–50%.
   - P1 adds expected future priority arrivals (from historical rate) to the dispatch order.
3. **ML (P1/P2):** LightGBM quantile models (P20/P50/P80) on: tokens ahead by category, effective counters, hour, weekday, EWMA mean, throughput in last 15 min, position. Used only if it beats engine 2 on a held-out simulated day; output clamped to [0.5×, 2×] of engine 2; 300 ms timeout; any error → engine 2.

**Service-time learning:** on every COMPLETED, update `service_stats` with an EWMA (alpha ≈ 0.2), starting from `prior_avg_minutes`.

**Reason codes** (counterfactual attribution): when ETA changes by the notification threshold, recompute the ETA with each factor reverted to its previous value (open counters, priority tokens ahead, service-time mean, tokens ahead). The factor with the largest effect is the reason: `COUNTER_DOWN`, `COUNTER_UP`, `PRIORITY_AHEAD`, `SLOWER_SERVICE`, `FASTER_SERVICE`, `CANCELLATIONS_AHEAD`, `NO_SHOWS_SKIPPED`. Shown as: "Your wait went up by 12 min — Counter 2 is on break." Previous factors are stored in `tokens.eta_features`.

**Evaluation (the number that wins the demo):** for every token, `eta_log` holds the booking-time prediction from the chosen engine and from the naive formula. After the token is called: `actual_wait = called_at − created_at`. Report MAE, % within the predicted range, and improvement over naive. All ETA numbers shown to judges are labelled as simulated data.

---

## 9. Simulator (`app/sim/`)

- **Virtual clock:** the sim calls the same `token_service` / `officer` functions with a fake `Clock` advanced in steps (e.g. 1 virtual minute per 100 ms), and calls `tick()` each virtual minute.
- **Separate simulation office** (`is_simulation=true`) so real data is untouched; the dashboard watches it through the same realtime path.
- **Scenario config:** arrival rate by hour (peak late morning, lunch dip, end-of-day taper), service-time distribution per service (log-normal), priority share (~10–15%), cancel rate (~5%), no-show rate (~8%), random counter breaks, number of counters.
- **Controls (admin UI):** start / pause / speed ×1–×600 / inject "Counter 2 breaks" / inject "rush of 30 citizens". The last two are your live demo moments.
- **Outputs:** full `token_events` log, exportable as CSV for ML training and for the accuracy report.
- Endpoints `/v1/admin/sim/*` are disabled in production configuration.

---

## 10. Reports and analytics (SQL over `token_events` / `eta_log`)
Average and P90 wait, service time per service, tokens served / cancelled / expired / no-show, counter utilization, load by hour, priority share and rejection rate, and the ETA accuracy panel (MAE, within-range %, vs naive). Dashboard calls three aggregate endpoints; heavy aggregates may become materialized views (P1).

---

## 11. Security, privacy, abuse control
- JWT verified on every request; role + office from `app_metadata`; per-route role guards; officers see only their own office; citizens only their own tokens (checked in API and covered by tests, since the API connection bypasses RLS).
- Realtime exposes only `queue_state` aggregates.
- Rate limits: bookings per phone per day, OTP limits via Supabase, per-IP limits on public endpoints.
- Abuse: one active token per phone per service; priority strikes (O6); idempotency keys.
- Privacy by minimization: store phone (and optional name) only; **no Aadhaar numbers**; consent text on first launch; document photos (P2 AI check) processed and not stored.
- Server is the only time authority; apps display `server_time` offsets.
- `/internal/*` requires the shared secret; never exposed in client code.

---

## 12. AI modules (all optional, behind interfaces, off the critical path)
| Module | What it does | Fallback | Phase |
|---|---|---|---|
| ETA ML | Better wait predictions | Live-adjusted engine | P1 |
| Voice/chat booking in Gujarati/Hindi | LLM + speech turns "mane birth certificate no token joiye chhe" into an API call | Normal app screens | P2 |
| Document pre-check | Photo of documents → vision model flags missing items against the checklist | Static checklist | P2 |
| Admin forecast | Predicts peak hours, suggests counters to open | Historical averages | P2 |
Rule: each module has a timeout, never raises into the request path, and is feature-flagged.

---

## 13. Repository layout
```
queueless/
  docs/            spec.md (this file), architecture.png, demo-script.md
  openapi/         openapi.json (exported, committed)
  api/
    app/
      main.py
      core/        config.py security.py clock.py db.py errors.py idempotency.py
      domain/      state_machine.py dispatch.py priority.py
      services/    token_service.py queue_service.py counter_service.py admin_service.py
                   checkin_service.py notification_service.py tick_service.py report_service.py
      eta/         engine.py naive.py live.py ml.py reasons.py snapshot.py
      sim/         scenario.py runner.py generators.py
      api/v1/      citizen.py officer.py desk.py admin.py internal.py
      models/ schemas/ i18n/ (en.json gu.json hi.json)
    migrations/    (alembic)
    tests/         unit/ concurrency/ api/ eta/
    Dockerfile pyproject.toml
  web/             src/{api(generated), features/{officer,desk,admin,sim}, components, i18n}
  mobile/          lib/{api(generated), features/{auth,book,token,history,settings}, l10n, core}
  ml/              train_eta.py, notebooks/, models/
```

---

## 14. Testing (written before the UIs)
1. **Concurrency:** 200 parallel `POST /tokens` → all seq unique and gapless. 2–5 officers calling next in parallel → all get different tokens. Same Idempotency-Key twice → one token.
2. **Transition matrix:** enumerate every (from, to, actor); only the allowed ones succeed, in both the API and the DB trigger.
3. **Priority/dispatch:** with N normal + M priority waiting, the call order matches the rule; rejected priority returns to its original position.
4. **Authorization:** citizen cannot read or modify another citizen's token; officer cannot act outside their office.
5. **ETA properties (Hypothesis):** adding tokens ahead never lowers ETA; adding an open counter never raises it; closed counters give `PAUSED`.
6. **Simulation regression:** a seeded simulated day must give live-adjusted MAE lower than naive; CI fails if not.
7. **Tick idempotency:** running tick twice produces no duplicate transitions or notifications.

---

## 15. Build order and "done" definitions (70% prototype = M1–M6)
| Milestone | Contents | Done when |
|---|---|---|
| M1 | Schema, constraints, triggers, seed office (3–4 services, 3 counters) | Migrations run; transition trigger test passes |
| M2 | API: auth, booking, cancel, call-next, start/complete, no-show, check-in + generated OpenAPI | Concurrency + transition tests green |
| M3 | ETA: naive + live-adjusted, `eta_log`, reasons | Property tests green; ETA returned on booking |
| M4 | Tick: no-show, expiry, ladder, outbox (log sender first, FCM next) | Tick idempotency test green |
| M5 | Web: login, officer queue + actions, counter status, desk booking, priority check, basic admin | A full token life runs through the browser |
| M6 | Simulator + admin sim controls + accuracy report | One-button simulated day; accuracy panel shows vs naive |
| M7 | Flutter app: language, OTP login, book, live token, cancel, check-in, push | Real phone receives LEAVE_NOW |
| M8 | P1 items + AI modules | — |

If time is short: M7 can demo as the Flutter web build, and M1–M6 alone still tell the full story. Do not start M8 before M1–M6 are stable.

---

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

---

## 17. Decisions log
| Decision | Rejected | Reason |
|---|---|---|
| Flutter for citizens | PWA/website | One-icon access, persistent login, native-language UX for seniors/village users, reliable background push |
| React SPA for staff | Next.js | No SSR/SEO need; simpler hosting |
| API owns logic, DB enforces integrity | Logic in Postgres functions | Two clients in two languages + AI modules need one testable, typed contract |
| Supabase (Postgres + Auth + Realtime + cron) | Self-hosted Node/Mongo/Socket.io | Fewer moving parts, free tier, scale path to Pro |
| Signal + refetch | Pushing ETAs over realtime | Avoids N updates per event; no personal data over realtime |
| pg_cron → `/internal/tick` | In-process scheduler | Free API hosts sleep; the cron call wakes them and logic stays in one place |
| Greedy multi-counter schedule for ETA | Plain average formula only | Handles priority jumps, breaks, in-progress service; formula kept as benchmark |
| Redis | — | Not needed at this scale; add only if measurements show a bottleneck |

## 18. Open decisions (fill in before M1)
- Office type for the demo (ward office / RTO / other) and its services, counters, average times.
- Defaults: `grace_minutes`, `priority_every_n`, `requeue_offset`.
- API hosting choice (verify free limits and cold-start time).
- Which AI module, if any, you ship in the hackathon version.

---

## 19. v1.1 patches (these OVERRIDE earlier sections wherever they conflict)
Found by auditing the spec against a 38-point problem list (lifecycle, abuse, ETA, access, ops).

### 19.1 Admission control (P0) — replaces the "office open?" check in §6.4
Booking is rejected with `409 QUEUE_FULL_FOR_TODAY` when the predicted start time of the new token is later than `close_time − close_grace`, or when `waiting_count >= max_waiting_per_service`. The error tells the citizen to try tomorrow. DESK may override with a mandatory reason (logged). This stops the system issuing tokens that can never be served.

### 19.2 Arrived-first dispatch (P0) — replaces token selection in §6.5
Problem: calling a remote citizen who has not arrived leaves the counter idle for the whole grace period while arrived people wait.
Rule: within the first `dispatch_window` (default 3) WAITING tokens of the chosen pool (by `sort_key`), pick the first one with `arrived_at` set. If none has arrived, pick the head (they were alerted; grace applies). Passed-over tokens keep their `sort_key`; `pass_over_count` is incremented and a token can be passed over at most `max_pass_overs` (default 2) times. Walk-in and assisted tokens get `arrived_at = created_at`. The ETA engine keeps assuming `sort_key` order (small, documented approximation).

### 19.3 ETA overrun rule (P0) — replaces the `remaining_i` formula in §8
`remaining_i = max(mean − elapsed, 1 min)` while `elapsed <= mean`; if `elapsed > mean` (case is overrunning) use `remaining_i = 0.5 × mean`. Add reason code `SLOW_CASE` when an in-service token exceeds 1.5 × mean. Before this, a 45-minute case made everyone's ETA think it would end next minute.

### 19.4 Family / on-behalf booking (P1) — replaces the one-active-token rule for C10
The unique index becomes `(beneficiary_key, service_id)` where `beneficiary_key` = beneficiary phone if given, else `booker_id + normalized beneficiary name`. One booker may hold up to `max_on_behalf_tokens` (default 3) active tokens per service. Until C10 ships, the rule stays one active token per phone per service.

### 19.5 Schema additions
- `tokens`: `pass_over_count`, `outcome_code`, `on_my_way_at`, `beneficiary_name`, `beneficiary_key`.
- `token_events.meta.reason_code` is **mandatory** for: no-show, release, transfer, priority rejection, manual reorder, desk override.
- Outcome codes: `SERVED, MISSING_DOCS, WRONG_SERVICE, WRONG_OFFICE, CITIZEN_LEFT, OTHER`.
- `services`: `requires_physical_visit bool`, `online_alternative_url`, `location_hint jsonb {en,gu,hi}` (floor/hall shown at booking).
- `office_settings`: `dispatch_window`, `max_pass_overs`, `max_waiting_per_service`, `max_on_behalf_tokens`, `on_my_way_extension_minutes` (5), `retention_days` (90).
- `queue_state`: `paused bool`.
- New `office_calendar(office_id, date, status CLOSED|CUSTOM_HOURS, open_time, close_time, note)` for holidays and special days.
- New `counter_service_stats(counter_id, service_id, hour_bucket, ewma_minutes, n)` — per COUNTER, never per person.

### 19.6 New or changed functions
| # | Function | How | Phase |
|---|---|---|---|
| C12 | "I'm on my way" | `POST /v1/tokens/{id}/on-my-way` extends grace once by `on_my_way_extension_minutes` | P1 |
| O1 | Identity check at counter | Officer view shows name + masked phone (last 4 digits) | P0 |
| O4 | Complete with outcome | `outcome_code` on complete; transfer/send-back requires `MISSING_DOCS` or `WRONG_SERVICE` | P1 |
| O10 | Pause / resume booking for a service | `POST /v1/queues/{service}/pause`, reason required, sets `queue_state.paused` | P1 |
| O11 | Manual reorder (move token) | ADMIN only, reason mandatory, logged as event | P1 |
| O12 | Close counter guard | A counter cannot be set CLOSED while it has a SERVING token; complete, transfer, or release first | P0 |
| D1 | Lobby display board | `GET /v1/display/{office_id}` public, read-only: per-counter now-serving display codes only (no personal data); web route `/display/:officeId`; refresh on `queue_state` signal, 10 s poll fallback | P1 |
| P1 | Per-counter service time | ETA uses `counter_service_stats` when `n >= 20`, else service-level stats | P1 |

Booking UI additions (P0): show `location_hint`, `requires_physical_visit` (+ online alternative link), the document checklist, and a required "I have these documents" tick before the token is issued.

### 19.7 Ops and privacy additions
- `/healthz` (process alive) and `/readyz` (database reachable); structured JSON logs with request id; log and alert on tick failures.
- Backups: confirm what backup or point-in-time recovery your database plan includes before relying on it (not verified here).
- Retention job: null out phone numbers on tokens older than `retention_days`; keep anonymized events for analytics.
- ML guard: online monitor compares rolling MAE of ML vs the live-adjusted engine on the last 100 completed tokens; auto-disable ML if it is worse. Calendar flags (holiday, month-end, deadline) from `office_calendar` become ML features.
- Role `SUPER_ADMIN` (organisation level) added for multi-office use (P2).

---

## 20. Known limitations of this version (be explicit about these in the pitch)
| Not solved now | Planned direction |
|---|---|
| Multi-step services in one journey (verify → pay → approve) | `journey_id` linking tokens, one queue per stage; transfers already link via `parent_token_id` |
| Office-side offline mode (office internet or server down) | Not built. Interim fallback: paper tokens during an outage. Later: staff app with local cache and sync |
| Advance appointments / time slots | Same-day virtual tokens only. Hybrid slots + live queue later |
| SMS, IVR, WhatsApp, missed-call booking, voice | Phase 2; assisted desk booking covers no-smartphone users now |
| Strong identity verification | Not attempted (no Aadhaar numbers stored). Abuse limited by OTP, per-phone limits, strikes, desk checks |
| Cross-office token transfer, district/department hierarchy | Cancel and rebook; hierarchy tables later (schema is already office-scoped) |
| Payments | Out of scope |
| Geofencing | Optional later, never the only security control |
| High availability / failover | Single-region free tier; no failover |