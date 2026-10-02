# QueueLess — Architecture & Design Decisions Log

Log of all assumptions, technical choices, and resolved ambiguities.

---

| ID | Date | Area | Decision / Assumption | Reason / Context |
|---|---|---|---|---|
| D-001 | 2026-10-02 | Environment | Local Python 3.13 + Local PostgreSQL 16 on port 5432 | Specified in environment instructions; no Docker used. |
| D-002 | 2026-10-02 | Auth | DevAuth (HMAC-signed local JWT) for local development | Allows complete automated testing and local execution before Supabase deployment in D1. |
| D-003 | 2026-10-02 | Database Safety | Strictly enforce DB name ending in `_test` for any test or reset operation | AGENTS.md core safety rule against accidental data loss. |
| D-004 | 2026-10-02 | Time | Clock interface injected throughout core services and queries | Ensures deterministic testing and virtual clock support for simulator. |
