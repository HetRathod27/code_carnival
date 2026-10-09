# QueueLess — Architecture & Design Decisions Log

Log of all assumptions, technical choices, and resolved ambiguities.

---

| ID | Date | Area | Decision / Assumption | Reason / Context |
|---|---|---|---|---|
| D-001 | 2026-10-02 | Environment | Local Python 3.13 + Local PostgreSQL 16 on port 5432 | Specified in environment instructions; no Docker used. |
| D-002 | 2026-10-02 | Auth | DevAuth (HMAC-signed local JWT) for local development | Allows complete automated testing and local execution before Supabase deployment in D1. |
| D-003 | 2026-10-02 | Database Safety | Strictly enforce DB name ending in `_test` for any test or reset operation | AGENTS.md core safety rule against accidental data loss. |
| D-004 | 2026-10-02 | Time | Clock interface injected throughout core services and queries | Ensures deterministic testing and virtual clock support for simulator. |
| D-005 | 2026-10-02 | Concurrency & Data Integrity | `queue_state.last_seq` synchronized with `max(queue_state.last_seq, max(Token.seq))` on booking | Under normal operating conditions, `queue_state` is locked with `FOR UPDATE` and is strictly authoritative. The `max(Token.seq)` defensive sync path protects against rare edge cases (e.g. manual administrative token insertions or database backup restores) without incurring race conditions or sequence collisions. Under standard booking flows, `queue_state.last_seq >= max(Token.seq)` is always invariant. |
| D-006 | 2026-10-05 | Specification Architecture | Adoption of Technical Specification v3 (Fixed Online Slots + Physical Desk Slips + Immediate Idle Capacity Dispatch) | Replaces conflicting rules. Online users get fixed non-moving appointments with 5-min buffer; physical walk-ins receive printed slip with live ETA estimate; officers serve physical users immediately when an online user is absent (no 3-missed prerequisite); double completion confirmation for online; deadline cutoff controls. |
| D-007 | 2026-10-10 | Mobile / Citizen Appointments | Accompanying Persons Limited to Max 4 & Single Counter Policy Enforcement | Capped total party size at 4 (1 primary applicant + up to 3 accompanying members). Requires full names and verified counter-specific co-attendance reasons for all accompanying persons. Excludes multi-counter co-attendance under a single booking; users with different counter tasks are blocked with clear notice requiring a separate booking. |
