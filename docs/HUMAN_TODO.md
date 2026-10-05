# QueueLess — Human TODO

This file contains tasks that require manual developer intervention (accounts, external keys, physical hardware, SDK installations).

---

## Current Items

### 1. Database Initialization (Done)
- Created local databases `queueless_dev` and `queueless_test`.
- Configured connection strings in `.env`.

---

## Upcoming Human Gates

### Gate D1: Supabase Setup (In Progress / Actionable)
1. **Create Supabase Project**:
   - Go to [https://supabase.com](https://supabase.com) and create a project named `queueless` (select region `ap-south-1` Mumbai or nearest).
2. **Retrieve API Keys & Secrets**:
   - Go to **Project Settings** > **API**:
     - `Project URL`: Copy to `SUPABASE_URL` in `.env`.
     - `anon / public key`: Used by Flutter citizen app for phone OTP and `queue_state` Realtime subscription.
     - `JWT Secret`: Copy to `SUPABASE_JWT_SECRET` in `.env`.
3. **Configure Authentication (Phone OTP)**:
   - Go to **Authentication** > **Providers** > **Phone**:
     - Enable Phone provider.
     - Add test phone numbers (e.g. `+919876543210` with OTP `123456`) under **Authentication** > **Settings** > **Phone Test Numbers**.
4. **Apply SQL Setup**:
   - Open **SQL Editor** in Supabase dashboard.
   - Open [supabase/setup.sql](file:///d:/code_carnival/supabase/setup.sql) from this repository, paste and execute it.
   - This enables Realtime publication on `queue_state` (Rule 3 Realtime Exception), activates RLS, and sets up the `pg_cron` minute tick schedule.
5. **Switching Provider (Optional)**:
   - For local development and CI tests, `AUTH_PROVIDER="dev"` continues using `DevAuth`.
   - Set `AUTH_PROVIDER="supabase"` in `.env` to verify live Supabase tokens against the FastAPI backend.

### Gate F0: Flutter SDK & Android Tooling (Before F0)
1. Install Flutter SDK (version 3.24+ recommended with Dart 3).
2. Install Android Studio & Command Line Tools.
3. Verify with `flutter doctor`.
*(Step-by-step instructions will be provided in simple terms for F0)*.

### Gate F3: Firebase Project (Before F3)
1. Create Firebase project in Firebase Console.
2. Download `google-services.json` for Android push notifications.
