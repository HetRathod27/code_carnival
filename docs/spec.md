# QueueLess — Technical Specification v3

PS-02: Government service appointment + queue management with fixed online slots, physical walk-ins, printed physical turn slips, tokens, QR verification, live operations, deadline controls, and ETA support.

> **Superseding rule:** This version replaces earlier conflicting appointment/physical-user rules. The QueueLess token and QR system remain core. Online users receive fixed appointment slots. Physical users can enter through the help desk and receive a physical token with an estimated turn time based on the current queue. Officers may serve available physical users whenever an online appointment holder has not arrived and the officer has usable capacity; there is **no requirement to wait for three missed online users**.

---

## 1. Product goal and design principles

### 1.1 Product goal
QueueLess is a government-service operating system that:
- gives citizens fixed appointment times through the mobile app;
- gives online bookings a token and QR/check-in mechanism;
- tells citizens which documents are required before visiting;
- lets citizens see appointment status and department updates;
- prevents officers from sitting idle when booked citizens are not present;
- supports physical citizens, including citizens without smartphones;
- gives physical citizens a printed token slip and estimated turn time;
- lets officers manage real-time service flow;
- lets department/admin staff control booking rules, deadlines, closures, and service configuration;
- records completion from both sides for online appointments;
- balances convenience for online users with continued access for physical users.

### 1.2 Core principles
1. **One API owns all business rules.** Flutter and web clients are thin clients. No appointment, queue, cancellation, priority, or fee logic is duplicated in UI code.
2. **Postgres is the source of truth.** The API enforces business rules and the database enforces uniqueness, constraints, and integrity.
3. **Every state change goes through one transition function.** Never update appointment/token state directly.
4. **Online appointments are fixed.** Once booked, the citizen receives a defined slot. The system does not continuously move the appointment because another citizen failed to arrive.
5. **An officer must not remain idle because an online user is absent.** If an online appointment holder has not arrived and a physical citizen is waiting, the officer can serve an eligible physical citizen according to the current dispatch rules.
6. **Three missed online users is NOT a prerequisite.** The officer may serve physical users after even one absent online appointment when the officer has usable capacity. A consecutive-missed count may still be recorded for analytics, but it does not gate physical service.
7. **Physical users remain supported.** No smartphone must never mean no access to government services.
8. **Physical users receive a printed turn slip.** The help desk creates a physical token and the system calculates an estimated turn time from the current queue and service conditions.
9. **Physical turn time is an estimate, not a fixed appointment.** The printed time can change because the queue, counters, service durations, or delays can change.
10. **Government-side failures are a separate class of event.** Server failure, department closure, or government-side technical problems are not treated as citizen cancellation.
11. **Payments do not guarantee protection from government-side failure.** A higher-priced custom slot remains subject to government/server availability. This condition must be shown before payment.
12. **QR/token remains core.** Online citizens receive a digital token/QR. Physical citizens receive a physical token and printed slip.
13. **Public display shows token numbers, not citizen names.** The public TV/display must never display names, phone numbers, Aadhaar numbers, or other personal identifiers.
14. **Document readiness is part of booking.** Citizens see the service document checklist and confirm readiness before completing an online booking.
15. **Server time is authoritative.** Client clocks cannot change appointment validity.
16. **Configuration over code.** Appointment duration, grace period, booking horizon, deadline cutoff, pricing, and other tunables live in settings.
17. **AI never sits in the critical path.** ETA/ML/document AI may improve the product but must never be required for booking, calling, cancellation, or completion.
18. **The system must be honest about uncertainty.** An online slot is a reserved appointment according to configured centre capacity; a physical turn time is an estimate.

---

## 2. High-level architecture

```text
 ┌──────────────────────────┐
 │ Flutter Citizen App      │
 │ Fixed booking + QR       │
 │ Token + status + alerts  │
 └─────────────┬────────────┘
               │ REST
               ▼
 ┌─────────────────────────────────────────┐
 │ FastAPI API                             │
 │                                         │
 │ Auth → Booking → Slot Engine            │
 │ Token/QR → Dispatch → ETA → Notify      │
 │ Cancellation → Closure → Completion     │
 │ Physical Slip → Display                 │
 │                                         │
 │ /internal/tick                          │
 └──────────────────┬──────────────────────┘
                    │ SQL transactions
                    ▼
 ┌─────────────────────────────────────────┐
 │ PostgreSQL / Supabase                   │
 │                                         │
 │ appointments, tokens, slots, queues     │
 │ events, users, services, counters       │
 │ notifications, closures, payments       │
 └─────────────────────────────────────────┘
                    ▲
                    │
 ┌──────────────────┴──────────────────────┐
 │ React + TypeScript Web Dashboard         │
 │                                          │
 │ Officer / Desk / Department Admin        │
 │ Queue + counter + closure + reports      │
 └──────────────────────────────────────────┘

 External:
 - Firebase FCM → mobile push notifications
 - Payment provider → optional paid/custom booking
```

### 2.1 Core online flow
```text
Citizen selects service
        ↓
Checks documents
        ↓
Selects number of people
        ↓
Selects normal/custom appointment
        ↓
System checks slot capacity
        ↓
Payment, if required
        ↓
Appointment + token + QR created atomically
        ↓
Citizen receives confirmation
        ↓
Citizen arrives within fixed appointment window
        ↓
QR check-in
        ↓
Officer verifies identity/documents
        ↓
Officer serves citizen
        ↓
Officer confirms completion
        ↓
Citizen confirms completion
        ↓
Appointment completed
```

### 2.2 Core physical flow
```text
Citizen reaches office
        ↓
Help desk
        ↓
System checks current queue/capacity
        ↓
Physical token created
        ↓
Estimated turn time calculated
        ↓
Printed slip issued
        ↓
Citizen waits according to estimated time
        ↓
TV shows physical token when called
        ↓
Officer serves citizen
        ↓
Officer confirms completion
```

---

## 3. Technology stack

### 3.1 Citizen app
- Flutter
- Dart 3
- Riverpod
- go_router
- Generated API client from OpenAPI
- Supabase Auth / phone OTP
- Firebase Cloud Messaging
- flutter_local_notifications
- mobile_scanner
- flutter_secure_storage
- shared_preferences
- intl + en/gu/hi localization
- connectivity_plus

### 3.2 Officer/admin web
- React
- TypeScript
- Vite
- Tailwind CSS
- shadcn/ui
- TanStack Query
- OpenAPI-generated TypeScript client
- react-i18next
- Recharts

### 3.3 Backend
- Python
- FastAPI
- Pydantic v2
- SQLAlchemy 2.x
- asyncpg
- Alembic
- pytest / pytest-asyncio / httpx
- Ruff
- Mypy
- Hypothesis for property tests

### 3.4 Database/auth/realtime
- PostgreSQL / Supabase
- Supabase Auth
- Supabase Realtime
- pg_cron + pg_net for periodic tick
- RLS enabled
- API remains the authorization boundary

### 3.5 Push
- Firebase Cloud Messaging for the MVP.

### 3.6 AI/ML
Optional:
- ETA prediction
- demand/peak forecasting
- document pre-check
- voice booking
All must have deterministic fallbacks.

---

## 4. User roles

| Role | Main responsibility |
|---|---|
| **CITIZEN** | Book, pay where applicable, check in, cancel, confirm completion |
| **PHYSICAL CITIZEN** | Receive physical token/slip and use office service |
| **OFFICER** | Manage counter, call/serve citizens, handle missed appointments, verify documents, complete service, control display |
| **DESK** | Create assisted/physical bookings and help citizens without smartphones |
| **DEPARTMENT_ADMIN** | Configure services, slots, deadlines, counters, staff, closure rules, pricing |
| **ADMIN** | Higher-level office/department management and reports |
| **SYSTEM** | Automatic expiry, no-show, notifications, slot locking, scheduled tasks |

---

## 5. Online appointment model

### 5.1 Online appointment
Every online booking has:
- appointment ID;
- citizen/booker ID;
- service ID;
- office ID;
- date;
- fixed start time;
- configured slot duration;
- number of people;
- appointment type;
- token;
- QR;
- booking price;
- document confirmation;
- appointment status.

### 5.2 Fixed appointment rule
Online appointments are non-flexible by default.
Example:
```text
Appointment: 4:00 PM
Buffer: 5 minutes
Expected arrival window: 4:00–4:05 PM
```
The system must not automatically change the citizen's appointment time because another user is absent.

### 5.3 No automatic "come early"
The system must not send:
> "Come early because the queue is empty."
The user's selected appointment remains the authoritative expected service time.

### 5.4 Appointment is not a government-server guarantee
Before booking/payment, show a clear disclosure:
> Government-side technical failures, official closures, or other department-side problems may affect service availability even when an appointment has been booked or paid for.

---

## 6. Slot types and pricing

### 6.1 Normal booking
Normal booking uses the standard configured booking horizon and fee.
Example: standard near-term slot; configured normal fee.

### 6.2 Custom/future booking
The department may allow citizens to choose a preferred time farther in the future.
Example:
```text
Normal booking → normal fee
Custom booking after 2+ days → higher configured fee
```
Exact amounts are configuration, not hardcoded.

### 6.3 Premium/custom slot limitation
A higher payment does not guarantee protection against:
- government server failure;
- official department closure;
- emergency shutdown;
- other government-side operational problems.
The booking/payment screen must disclose this.

---

## 7. Slot capacity and concurrency

### 7.1 No double booking
Two citizens must never consume the same protected capacity. Use database transactions and locking.

### 7.2 Family/group capacity
Booking must ask:
> **How many people are coming with you?** (1, 2, 3, 4, 5+)
The selected group size affects service capacity and estimated service duration.

### 7.3 Service duration
Each service can configure:
- expected service duration;
- minimum slot duration;
- maximum group size;
- optional group multiplier.
Example: Base = 10 min; 1 person = 10 min; 2 people = 15 min; 4 people = 30 min.

### 7.4 Atomic booking
The server must atomically:
1. validate user;
2. validate office/service;
3. validate booking window;
4. validate online cutoff;
5. validate service active;
6. validate group size;
7. validate document confirmation;
8. validate priority if applicable;
9. calculate capacity;
10. lock capacity;
11. calculate fee;
12. verify payment if required;
13. create appointment;
14. create token;
15. generate QR;
16. create audit event;
17. create notification outbox event;
18. commit.

---

## 8. Document checklist
Each service has a configured document checklist.
Example:
```text
Aadhaar Update
Required:
✓ Identity proof
✓ Existing Aadhaar-related document
✓ Address proof, if required

[ I have the required documents ]
```
The citizen must confirm document readiness before completing an online booking where the service requires it. The officer can still physically verify the documents.

---

## 9. Family/group booking

### 9.1 Booking field
Required: "How many people are coming for this booking?"

### 9.2 Optional details
Where necessary, collect: beneficiary name, relationship, beneficiary phone if available. Do not store Aadhaar numbers unnecessarily.

### 9.3 Group service
The officer must be able to record whether: all people were served, only some were served, service failed because of missing documents, or another configured outcome occurred. Do not mark an entire group as successfully completed if only part of the requested work was completed.

---

## 10. Token and QR system

### 10.1 Online user
Online booking generates:
```text
Appointment: 4:00 PM
Token: A-047
People: 3
QR: signed QR
```

### 10.2 Physical user
The help desk generates:
```text
Physical Token: P-024
Service: Aadhaar Update
Estimated Turn: 3:40 PM
```
A printed slip is given to the citizen.

### 10.3 QR check-in
The citizen scans the office QR to prove physical presence. The QR must not be accepted as an indication that the citizen is physically present if scanned remotely. P0 may use a signed daily QR; P1 may rotate the QR periodically.

---

## 11. Physical user system
This is a core QueueLess feature.

### 11.1 Physical user entry
A physical citizen:
1. comes to the office;
2. goes to the help desk;
3. requests the required service;
4. help desk creates a physical token;
5. system checks the current queue;
6. system calculates an estimated turn time;
7. help desk prints the slip;
8. citizen waits according to the estimated time.

### 11.2 Printed slip
The slip should contain at least:
```text
QueueLess
Service: Aadhaar Update

Token: P-024

Estimated Turn:
3:40 PM

Please wait for your token to be displayed.
```
It should not expose unnecessary personal information.

### 11.3 Physical turn time
The physical user's printed time is not a fixed appointment. It is an estimate based on: current waiting queue, online appointments, physical tokens ahead, active counters, average service duration, group size, priority rules, and current delays. A single displayed time may be printed if the product UX requires it, but internally the system should retain an ETA range.

### 11.4 Queue changes
If the queue changes substantially: physical ETA can be recalculated, dashboard can show the updated estimate, and optional notification can be sent if a phone number is available. The printed slip is therefore an estimated turn, not a guaranteed appointment.

---

## 12. Physical users and online users

### 12.1 Online user absent
Suppose:
```text
4:00 PM online appointment
User has not arrived
Buffer expires
```
The officer does not have to remain idle. If a physical user is waiting and the officer has usable capacity, the officer can serve the physical user. **There is no requirement to wait for three missed online users.**

### 12.2 Three missed users
The system may still count `consecutive_missed_online_appointments = 3` for analytics, staffing decisions, reports, and detecting high no-show periods. But it is not a prerequisite for physical service.

### 12.3 Later online user
Suppose:
```text
4:00 online A → absent
4:05 physical P-024 → served
4:15 online B → arrives on time
```
B's valid appointment remains valid. The officer should finish an already-started service and then serve B according to the dispatch rules. Physical users must not permanently cancel or consume another valid online user's appointment.

---

## 13. Dispatch rules
The backend owns dispatch.
```text
Is a valid online appointment holder present?
        │
       YES
        ↓
Serve valid online appointment according to appointment rules
        │
       NO
        ↓
Is a physical user waiting?
        │
       YES
        ↓
Serve eligible physical user
        │
       NO
        ↓
Wait / perform other officer work
```
Additional rules may apply for: priority categories, service-specific constraints, already-started service, multiple counters, group bookings, official emergency rules. The system must never require an officer to sit idle solely because an absent online appointment exists.

---

## 14. Public TV/display

### 14.1 Token only
The public TV must display the token number, not the citizen's name.
```text
━━━━━━━━━━━━━━━━━━━━
       NOW SERVING
━━━━━━━━━━━━━━━━━━━━

         P-024

       COUNTER 2
━━━━━━━━━━━━━━━━━━━━
```

### 14.2 Privacy rule
The public display must never expose: citizen name, phone number, Aadhaar number, PAN number, address, or private document information.

### 14.3 Display content
Allowed: token number, counter number, service category where useful, queue status, general announcements.

### 14.4 Officer control
The officer can select which eligible token is currently being served. The display must reflect the actual serving token.

### 14.5 Display endpoint
`GET /v1/display/{office_id}`: public/read-only, returns only safe display information.

---

## 15. Officer workflow

### 15.1 Dashboard
Officer sees: current counter, service, valid online appointments, arrived online users, missed appointments, physical waiting tokens, estimated physical turn times, current serving token, priority verification, document verification, closure controls, display controls.

### 15.2 Normal operation
```text
Check current appointment/queue
        ↓
Check whether valid online user is present
        ↓
If present → serve according to appointment rules
If absent → serve eligible physical user if available
        ↓
Complete
        ↓
Move to next eligible citizen
```

### 15.3 Officer must not wait unnecessarily
An absent online appointment does not automatically make the officer idle. The officer may serve an eligible physical user whenever operationally possible.

---

## 16. Completion confirmation

### 16.1 Online user
Double confirmation:
```text
Officer completes service → Officer confirms completion → User receives confirmation request → User confirms → Appointment = COMPLETED
```

### 16.2 Physical user
Single verification:
```text
Officer completes service → Officer confirms completion → Token = COMPLETED
```

---

## 17. Cancellation rules

### 17.1 User cancellation
Normal voluntary cancellation is controlled by the citizen. The officer/admin cannot casually cancel a citizen's appointment.

### 17.2 Automatic cancellation
Fixed appointment + 5-minute buffer expires + citizen absent → MISSED → AUTO_CANCELLED.

### 17.3 Exceptional department/system cancellation
May occur for official closure, government/server outage, emergency, officer/service unavailability, or government instruction. Requires authorized role, reason, audit event, and citizen notification where possible.

### 17.4 No silent cancellation
Every cancellation/invalidation must record who/what caused it, reason, timestamp, affected appointment, and notification status.

---

## 18. Government/server delay
Government-side delay is not citizen fault, normal officer fault, or normal admin fault. When a government-side issue occurs, mark service/office as delayed, identify affected appointments, notify mobile users, provide rescheduling instructions, and preserve the original reason in the audit trail. A citizen who paid more for a custom slot is subject to the same government-side failure rule.

---

## 19. Sudden department closure
If the department/service suddenly closes:
```text
Officer/Admin selects SERVICE CLOSED → Reason required → New online bookings stop → Affected future appointments identified → Mobile users notified → Rescheduling workflow started → Closure event stored
```
For physical citizens already present: informed at the office; help desk handles what is operationally possible; staff may call later if a phone number exists.

---

## 20. Rescheduling
- **User-caused missed appointment:** Does not automatically get a flexible appointment. Must make a new booking if another slot is available.
- **Government-caused disruption:** Notify mobile users, provide rescheduling instructions/options, preserve reason, do not mark as user cancellation.
- **No-phone physical user:** Office announcement, help-desk communication, phone call when a number exists.

---

## 21. Advance booking cutoff and government deadlines
- **Deadline configuration:** Example: Government deadline = 10 September; Online booking cutoff = 3 September.
- **After cutoff:** New online booking is disabled. App shows: *"Online booking for this service is closed due to the configured government deadline policy. Please visit the centre physically."* Physical/help-desk service remains available.
- **Existing appointments:** Existing valid bookings remain valid unless an exceptional closure affects them.

---

## 22. Notifications
- **Online booking:** APPOINTMENT_CONFIRMED, TOKEN_CREATED, PAYMENT_CONFIRMED (if applicable), DOCUMENT_REMINDER.
- **Appointment reminder:** *"Your appointment is at 4:00 PM. Please arrive within the allowed 5-minute buffer."* (Do not send automatic "come early" messages).
- **Missed appointment:** *"You did not arrive within the allowed appointment window. Your appointment has been automatically cancelled."*
- **Government delay / Closure:** Notifications with rescheduling instructions.
- **Physical ETA:** Optional/configurable if phone provided: *"Your estimated turn is approaching. Please be ready for token P-024."*
- **Localization:** English, Gujarati, Hindi.

---

## 23. ETA and queue engine
Fixed appointments do not remove ETA. ETA is used for physical-user turn estimates, active queue monitoring, service delay estimation, and officer capacity planning.
- **Physical ETA baseline:** Workload ahead / effective open counters. Range represented as `~3:35–3:45 PM` internally, printed as `Estimated turn: 3:40 PM` on slip.
- **Online user:** Fixed appointment is authoritative. ETA supplements with expected delay / current progress.

---

## 24. Priority users
Categories: senior citizens, pregnant citizens, persons with disabilities, etc.
- **Verification:** *"Trust at booking, verify at the office."*
- **Fairness:** Reserved capacity, interleaving, auditable server-side rules.

---

## 25. Department/admin controls
- **Office:** name, address, timezone, opening/closing hours, holidays, special closures.
- **Services:** service name, documents, average duration, group rules, online availability, physical availability, priority eligibility, location, online alternative.
- **Appointment:** slot duration, booking horizon, custom-slot horizon, pricing, buffer, maximum group size, capacity.
- **Physical queue:** physical token numbering, physical capacity, ETA settings, help-desk settings, display settings.
- **Deadline:** government deadline, online booking cutoff, deadline note.
- **Closure:** closure reason, notification policy, rescheduling policy.

---

## 26. Booking transaction
```text
BEGIN
if idempotency key already exists: return previous response
validate user, office, service, calendar, booking horizon, booking cutoff, service active, group size, document confirmation, priority
lock appointment capacity
if capacity unavailable: return SLOT_UNAVAILABLE
calculate price; verify payment if required
create appointment; create token; create signed QR reference
write appointment event; write notification outbox; write idempotency response
COMMIT
```

---

## 27. Physical token creation transaction
```text
BEGIN
validate office/service, service physical availability, current office time
calculate physical queue position, workload ahead, ETA range
assign unique physical token
create token event
create printed-slip data
write notification if applicable
COMMIT
```

---

## 28. Token state machines

### 28.1 Online appointment
```text
BOOKED → CHECKED_IN → CALLED → SERVING → OFFICER_COMPLETED → USER_CONFIRMED → COMPLETED
```
Missed:
```text
BOOKED → MISSED → AUTO_CANCELLED
```
Government closure:
```text
BOOKED → AFFECTED_BY_CLOSURE → RESCHEDULE_REQUIRED
```

### 28.2 Physical token
```text
WAITING → CALLED → SERVING → COMPLETED
(optional: WAITING → CANCELLED)
```

---

## 29. Database model
Core tables:
- `offices`: Government office
- `office_settings`: Appointment/queue rules
- `office_calendar`: holidays, deadlines, closures
- `services`: Government services
- `counters`: Physical counters
- `counter_services`: Counter/service mapping
- `profiles`: Users/staff
- `appointment_slots`: Available online capacity
- `appointments`: Online appointments
- `tokens`: Online + physical service tokens
- `token_events`: Immutable audit trail
- `allowed_transitions`: State-machine protection
- `service_stats`: Service-time statistics
- `counter_service_stats`: Counter-specific statistics
- `eta_log`: ETA predictions
- `priority_checks`: Priority verification
- `devices`: FCM device tokens
- `notification_outbox`: Reliable notifications
- `idempotency_keys`: Double-tap protection
- `counter_events`: Counter status history
- `closure_events`: Department/service closure history
- `payment_records`: Payment state
- `completion_confirmations`: Online double confirmation

---

## 30. Database constraints
- **Token uniqueness:** `UNIQUE(office_id, service_id, business_date, seq)`
- **Online capacity:** Protected through database locking/constraints.
- **One active appointment:** Prevent conflicting active appointments per citizen/service.
- **Idempotency:** Same booking idempotency key = same booking result.
- **State integrity:** All transitions validated.
- **Audit:** Immutable event logs for cancellation, closure, rescheduling, no-show, priority rejection, physical token creation, manual dispatch, display changes, officer overrides.

---

## 31. API catalogue

### Citizen
| Function | Endpoint |
|---|---|
| Browse offices | `GET /v1/offices` |
| Browse services | `GET /v1/offices/{id}/services` |
| Get slots | `GET /v1/services/{id}/slots` |
| Create appointment | `POST /v1/appointments` |
| View appointment | `GET /v1/appointments/{id}` |
| Cancel appointment | `POST /v1/appointments/{id}/cancel` |
| Check-in | `POST /v1/appointments/{id}/check-in` |
| Confirm completion | `POST /v1/appointments/{id}/confirm-completion` |
| Register device | `POST /v1/devices` |
| Change language | `PATCH /v1/me` |
| History | `GET /v1/appointments/me/history` |

### Officer
| Function | Endpoint |
|---|---|
| View queue | `GET /v1/counters/{id}/queue` |
| Set counter status | `POST /v1/counters/{id}/status` |
| Call next | `POST /v1/counters/{id}/call-next` |
| Start | `POST /v1/tokens/{id}/start` |
| Complete | `POST /v1/tokens/{id}/complete` |
| Mark missed | `POST /v1/appointments/{id}/missed` |
| Priority check | `POST /v1/tokens/{id}/priority-check` |
| Display current token | `POST /v1/counters/{id}/display` |
| Close service | `POST /v1/services/{id}/close` |
| Reopen service | `POST /v1/services/{id}/reopen` |

### Desk
| Function | Endpoint |
|---|---|
| Create physical token | `POST /v1/desk/tokens` |
| Get physical queue | `GET /v1/desk/queue` |
| Print slip data | `GET /v1/desk/tokens/{id}/slip` |

### Admin
| Function | Endpoint |
|---|---|
| Office CRUD | `/v1/admin/offices/...` |
| Service CRUD | `/v1/admin/services/...` |
| Counter CRUD | `/v1/admin/counters/...` |
| Staff | `/v1/admin/staff/...` |
| Settings | `/v1/admin/offices/{id}/settings` |
| Calendar | `/v1/admin/offices/{id}/calendar` |
| Deadline | `/v1/admin/services/{id}/deadline` |
| Booking cutoff | `/v1/admin/services/{id}/booking-cutoff` |
| Pricing | `/v1/admin/services/{id}/pricing` |
| Reports | `/v1/admin/reports/...` |
| Closure | `/v1/admin/services/{id}/closure` |

### Public display
`GET /v1/display/{office_id}`:
```json
{
  "now_serving": {
    "token": "P-024",
    "counter": 2
  }
}
```
Never returns citizen name or private identifiers.

---

## 32. Automatic tick
The scheduler runs periodically to:
- detect expired appointment buffers;
- mark missed appointments;
- auto-cancel missed appointments;
- release unused appointment capacity;
- detect planned closures;
- send reminders;
- send government-delay notifications;
- send closure notifications;
- update ETA;
- update physical turn estimates;
- flush notification outbox;
- maintain statistics.
Idempotent execution.

---

## 33. Reports and analytics
Admin reports include: online bookings, physical users, completed appointments, missed appointments, user cancellations, government-side affected appointments, department closures, average wait, P90 wait, service duration, counter utilization, physical utilization, online utilization, physical-mode usage, online no-show rate, deadline-period demand, booking cutoff impact, custom-slot bookings, revenue where payments are enabled, completion confirmation rate, ETA accuracy, document-related failures, physical ETA accuracy, average physical waiting time.

Distinguish:
- `USER_CANCELLED`
- `AUTO_CANCELLED_MISSED`
- `GOVERNMENT_SIDE_AFFECTED`
- `DEPARTMENT_CLOSED`
- `COMPLETED`

---

## 34. Simulator
Supports:
- fixed online appointments;
- online no-shows;
- physical arrivals;
- physical ETA;
- officer serving physical users during online idle capacity;
- group bookings;
- multiple counters;
- priority;
- government delay;
- sudden closure;
- deadline rush.

---

## 35. Testing requirements
1. **Online slot concurrency:** Concurrent requests must never overbook capacity.
2. **Double tap:** Same idempotency key yields 1 appointment only.
3. **Fixed appointment:** A valid online appointment cannot be silently moved.
4. **Five-minute buffer:** Tested before, at, inside, and after buffer.
5. **Automatic missed cancellation:** After buffer: `BOOKED → MISSED → AUTO_CANCELLED`.
6. **Physical user after one absent online user:** Tested: absent online user + physical user waiting → officer may serve physical user (no requirement for three missed users).
7. **Later online appointment:** A later valid online appointment remains valid after physical mode is used.
8. **Physical slip ETA:** Token created, current queue considered, ETA range calculated, slip data contains token + estimated time.
9. **TV privacy:** Public display must show token number, never name/phone/Aadhaar.
10. **Deadline cutoff:** After cutoff, online booking rejected; physical service allowed if configured.
11. **Closure:** Service closes → new bookings blocked, affected appointments identified, audit event written, notifications queued.
12. **Completion:** Online: `OFFICER_COMPLETED → USER_CONFIRMED → COMPLETED`; Physical: `OFFICER_COMPLETED → COMPLETED`.
13. **Cancellation authorization:** Citizen can cancel own booking; officer cannot casually cancel; exceptional closure requires authorized role + reason.
14. **Government failure:** Never classified as user cancellation.
15. **Tick idempotency:** Repeated ticks must not create duplicate cancellation or notification events.

---

## 36. Security and privacy
- JWT verification on every request.
- Role + office scope enforced server-side.
- Citizens access only their own appointments.
- Officers access only authorized office/service data.
- Admin actions audited.
- QR signed.
- Server time authoritative.
- No Aadhaar numbers stored unnecessarily.
- No unnecessary document images.
- Public TV never displays personal names or phone numbers.
- Rate limits on booking/OTP.
- Idempotency keys on booking.
- Payment webhooks verified cryptographically if enabled.

---

## 37. Build order

### M0–M5
Existing backend foundation remains reusable where compatible.

### M6 — Appointment foundation
- Fixed appointment model
- Slot model & capacity
- Fixed booking
- 5-minute buffer
- User cancellation
- Automatic missed cancellation
- Family/group count
- Document confirmation

### M7 — Physical users + officer workflow
- Physical tokens
- Help-desk flow & printed slip
- Physical ETA & queue
- Dispatch rules (serving physical users whenever online capacity is unused)
- Token-only public display

### M8 — Closure/deadline operations
- Office calendar
- Service deadline & booking cutoff
- Planned and sudden closure
- Affected appointment notifications & rescheduling workflow

### M9 — Completion + notifications
- Officer completion & user confirmation (double confirmation)
- Localized notifications (en/gu/hi)
- Government-delay notifications
- Physical ETA notifications where applicable

### M10 — Payments/custom slots (Optional)
- Custom future slots, pricing, payment state, verification, refund policy.

### M11 — Flutter integration
- Booking, family count, document checklist, slot selection, QR, appointment status, cancellation, completion confirmation, notifications.

### M12 — Reports/simulation hardening
- Appointment analytics, physical utilization, physical ETA accuracy, no-show analytics, deadline analytics, full simulation.

---

## 38. Autopilot & Final Decision Table

| Situation | System behavior |
|---|---|
| Online user arrives on time | Serve according to fixed appointment |
| Online user arrives within 5-minute buffer | Accept according to configured check-in rule |
| Online user does not arrive | Mark missed and auto-cancel according to policy |
| One online user absent + physical user waiting | Officer may serve physical user |
| Three online users absent | Physical service continues; three is not a prerequisite |
| Physical user arrives | Help desk creates physical token |
| Physical token created | System calculates estimated turn |
| Physical slip printed | Token + estimated turn shown |
| Queue changes | Physical ETA may be recalculated |
| Later online user arrives | Valid online appointment remains valid |
| TV display | Token number only (never name or personal data) |
| User wants to cancel | User can cancel |
| Officer wants ordinary cancellation | Not allowed |
| Sudden government/department closure | Exceptional closure flow with reason & notifications |
| Government server delay | Notify affected users and follow rescheduling policy |
| User paid premium custom slot | Still subject to government-side failure disclosure |
| Government deadline approaching | Admin can close online booking early |
| Online booking cutoff reached | New online bookings blocked; physical remains available |
| Online service completed | Officer confirms + user confirms (double confirmation) |
| Physical service completed | Officer confirms |