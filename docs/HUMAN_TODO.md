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

### Gate F0: Flutter SDK & Android Tooling (Done)
- Flutter 3.44.8 and Dart 3.12.2 installed and verified.
- Mobile application skeleton and widget test suite operational.

### Gate F3: Firebase Cloud Messaging (Human Gate)
1. **Create Firebase Project**:
   - Go to [Firebase Console](https://console.firebase.google.com/) and create a project named `QueueLess`.
2. **Add Android App**:
   - Register an Android app with package name `in.gov.queueless.mobile` (configured in `mobile/android/app/build.gradle`).
   - App nickname: `QueueLess Citizen App`.
3. **Download Configuration**:
   - Download `google-services.json`.
   - Place `google-services.json` into `d:\code_carnival\mobile\android\app\google-services.json`.
4. **Firebase Service Account for Backend**:
   - In Firebase Console, go to **Project Settings** > **Service Accounts**.
   - Click **Generate new private key** (downloads JSON file).
   - Save the file path in `.env` as `FIREBASE_CREDENTIALS_PATH=./firebase-credentials.json`.
5. **Development & Offline Behavior**:
   - The Flutter mobile application already includes `NotificationService` (`mobile/lib/core/notifications.dart`) which automatically registers devices via `POST /v1/devices` and provides a simulated in-app notification pipeline for local testing without requiring physical Google Play Services.
