# QueueLess 🎟️
> **Civic Appointment & Intelligent Queue Operating System**  
> *Government service appointment + queue management with fixed online slots, physical walk-ins, printed physical turn slips, tokens, QR verification, live operations, deadline controls, and pure ETA support.*

[![Full Suite Verification](https://img.shields.io/badge/verification-passing-brightgreen)](#automated-verification-suite)
[![Python 3.13](https://img.shields.io/badge/python-3.13-blue)](api/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.135-009688)](api/)
[![React 19](https://img.shields.io/badge/React-19-61dafb)](web/)
[![Flutter 3.44](https://img.shields.io/badge/Flutter-3.44-02569B)](mobile/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15+-336791)](supabase/)

---

## 1. System Overview & Problem Statement

Civic offices frequently experience unpredictability, long lines, and overcrowding. **QueueLess** replaces chaotic physical waiting with a transparent, equitable queue operating system adhering to **Technical Specification v3**:
- **Fixed Online Appointment Slots**: Citizens reserve fixed appointment times via the mobile app, receive verifiable QR tokens, and track real-time queue progression.
- **Physical Walk-Ins & Printed Turn Slips**: Unregistered citizens receive assistance at the Help Desk with printed thermal turn slips displaying token identifiers, QR codes, and current estimated wait times.
- **Dynamic Capacity Utilization**: Officers serve waiting physical walk-ins whenever an online appointment holder has not yet checked in, eliminating idle staff capacity.
- **Privacy & Dignity First**: Zero Aadhaar storage; public TV displays display *only* token numbers and counter assignments—never citizen names or personal details.
- **Live Operations & Grace Periods**: Automatic no-show sweeps, "I'm on My Way" (+5 min) single-claim buffers, service pause reasons, and live ETA adjustments.

---

## 2. Architecture & Feedback Loop

```
 ┌──────────────────────────┐         ┌──────────────────────────┐
 │   Flutter Citizen App    │         │    React Web Dashboard   │
 │ (Android / iOS / Web)    │         │ (Officer/Desk/Admin/Sim) │
 └─────────────┬────────────┘         └────────────┬─────────────┘
               │ REST (Generated OpenAPI Client)   │
               │   + Read-only Realtime Signal     │
               ▼                                   ▼
 ┌───────────────────────────────────────────────────────────────┐
 │                      QueueLess API (FastAPI)                  │
 │  • State Machine (Transition matrix with event audits)        │
 │  • Lock Order: queue_state ➔ counters ➔ tokens                │
 │  • Pure ETA Engine: Zero DB/Network in compute_etas()         │
 │  • Injected Virtual Clock (Deterministic simulation)          │
 │  • Push Notifier & /internal/tick Cron Sweep                  │
 └───────────────────────────────┬───────────────────────────────┘
                                 │ SQL (Transactions & Row Locks)
                                 ▼
 ┌───────────────────────────────────────────────────────────────┐
 │               Supabase / PostgreSQL Database                  │
 │  • Tables: offices, services, counters, tokens, token_events  │
 │  • Append-Only Audit Trail: token_events immutable            │
 │  • queue_state: Versioned aggregates for Realtime broadcast   │
 └───────────────────────────────────────────────────────────────┘
```

**Core Feedback Loop**:
`Counter Events ➔ Event Log ➔ Service-Time Stats ➔ Live ETA Engine ➔ Citizen Push Notifications ➔ Regulated Physical Arrivals ➔ Decongested Waiting Area`.

---

## 3. Technology Stack

| Layer | Technology | Key Details |
|---|---|---|
| **Backend API** | FastAPI / Python 3.13 | Uvicorn, SQLAlchemy 2 (Asyncio), Asyncpg, Pydantic v2 |
| **Database** | PostgreSQL 15+ / Supabase | Row-level locking (`SKIP LOCKED`), monotonic sequence numbering |
| **ETA Engine** | Pure Python Algorithm | Mathematically proven (`MAE_Live < MAE_Naive`), 0 network calls |
| **Staff Web** | React 19 / TypeScript / Vite | Lucide icons, i18next (`en`, `gu`, `hi`), CSS modules |
| **Citizen App** | Flutter 3.44 / Dart 3.12 | Material 3, Google Stitch Design System, ARB localizations |
| **Push / Auth** | Firebase FCM / DevAuth / Supabase | Dual-provider auth architecture (`DevAuth` local, `SupabaseAuth` prod) |

---

## 4. Demo Personas & Credentials

Run the demo seed command (`python scripts/seed_demo.py`) to initialize a fully operational civic centre (*Ward Central Office 01*):

| Role | Name | Phone Number | Responsibilities |
|---|---|---|---|
| **Senior Officer** | Rajesh Sharma | `+919800000001` | Call tokens, serve, transfer, pause counter, log no-shows |
| **Help Desk** | Pooja Patel | `+919800000002` | Assisted citizen booking, printable physical turn slips |
| **Admin** | Kirit Mehta | `+919800000003` | Office settings, QR code generator, KPI analytics reports |
| **Citizen** | Aarav Shah | `+919876543210` | Fixed slot booking, document confirmation, live ETA, QR check-in |

---

## 5. Quickstart Guide (Local Setup)

### Prerequisites
- Python 3.11+ (Python 3.13 recommended)
- Node.js 20+ & npm
- Flutter 3.22+ (Flutter 3.44 recommended)
- PostgreSQL running locally on port 5432

### Step 1: Environment & Database Setup
```powershell
# Clone the repository
git clone https://github.com/HetRathod27/code_carnival.git
cd code_carnival

# Create and activate Python virtual environment
python -m venv venv
.\venv\Scripts\Activate.ps1

# Install API dependencies
pip install -r api/requirements.txt -r api/requirements-dev.txt

# Run migrations and seed demo data
.\venv\Scripts\python.exe scripts/seed_demo.py
```

### Step 2: Start Backend API
```powershell
.\venv\Scripts\uvicorn.exe api.app.main:app --host 0.0.0.0 --port 8000 --reload
```
*API Swagger documentation available at:* `http://localhost:8000/docs`

### Step 3: Start Staff Web Dashboard
```powershell
cd web
npm install
npm run dev
```
*Web dashboard available at:* `http://localhost:5173/`  
*Public Lobby Display Board:* `http://localhost:5173/display/ward-central-01`

### Step 4: Run Citizen Mobile App
```powershell
cd mobile
flutter pub get

# Run on Chrome for local web preview
flutter run -d chrome

# Or run on connected Android device / emulator
flutter run -d android
```

---

## 6. Automated Verification Suite

QueueLess enforces strict quality gates via `scripts/verify.ps1`:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/verify.ps1
```
The verification gate runs:
1. **Ruff linting & formatting** on all Python modules.
2. **OpenAPI schema generation** (`scripts/export_openapi.py`).
3. **Mypy strict static typing** on 52 Python files.
4. **Pytest comprehensive suite** (57 tests including full-day Monte Carlo queue simulation regression).
5. **React TypeScript typecheck and production build** (`npm run build`).
6. **Flutter static analysis** (`flutter analyze`).
7. **Flutter widget tests** (`flutter test`).

---

## 7. Key Architecture Rules (The 13 Rules)

1. **API Owns Business Logic**: Frontend clients never calculate state transitions or ETAs directly.
2. **Strict State Transitions**: Tokens transition solely via `transition()`, enforcing `ALLOWED_TRANSITIONS` and generating append-only `token_events`.
3. **Locking Order**: Every mutation executes in a single transaction locking `queue_state` ➔ `counters` ➔ `tokens` using `FOR UPDATE SKIP LOCKED`.
4. **Pure ETA Engine**: `compute_etas(snapshot)` is a deterministic, pure function with 0 database or network calls.
5. **Injected Clocks**: System components accept `Clock` interfaces, enabling high-speed virtual simulations.
6. **Privacy Preserved**: No Aadhaar or confidential citizen IDs stored; public TV displays only display alphanumeric token codes.
7. **Trilingual Localization**: Complete native support across English, Gujarati, and Hindi (`en`, `gu`, `hi`).

---

## 8. License & Authors
Developed for the **Code Carnival Civic Tech Hackathon**.  
Released under the MIT License.
