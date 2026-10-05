# QueueLess — Backend Smoke Test & Verification Guide

This document provides exact, reproducible PowerShell commands to run a complete end-to-end smoke test against the local QueueLess API service. It verifies database migrations, DevAuth token acquisition, the full citizen-to-officer token lifecycle, public lobby displays, background simulation runs, and aggregate report endpoints.

All outputs recorded below are real runs from the local test environment.

---

## 1. Prerequisites & Starting the API

Ensure PostgreSQL is running locally and the virtual environment is activated.

### 1.1 Run Database Migrations & Seed
```powershell
.\venv\Scripts\alembic upgrade head
```
**Recorded Output:**
```text
INFO  [alembic.runtime.migration] Context impl PostgresqlImpl.
INFO  [alembic.runtime.migration] Will assume transactional DDL.
```

### 1.2 Start the FastAPI Application
```powershell
powershell -Command "uvicorn api.app.main:app --host 127.0.0.1 --port 8000"
```

---

## 2. DevAuth Token Acquisition

QueueLess provides signed DevAuth JWTs carrying role and office claims for rapid local development and testing.

### Command
```powershell
$headers = @{ "X-Internal-Secret" = "change_me_to_a_secure_random_string" }
Invoke-RestMethod -Method POST -Uri "http://127.0.0.1:8000/internal/dev-token" -Headers $headers | ConvertTo-Json -Depth 4
```

**Recorded Output:**
```json
{
  "dev_tokens": {
    "dev-officer-1": {
      "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "role": "OFFICER",
      "office_id": "ward-central-01",
      "name": "Dev Officer 1",
      "phone": null
    },
    "dev-desk-1": {
      "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "role": "DESK",
      "office_id": "ward-central-01",
      "name": "Dev Desk 1",
      "phone": null
    },
    "dev-admin-1": {
      "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "role": "ADMIN",
      "office_id": "ward-central-01",
      "name": "Dev Admin 1",
      "phone": null
    },
    "dev-citizen-1": {
      "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "role": "CITIZEN",
      "office_id": null,
      "name": "Dev Citizen 1",
      "phone": "+919876543210"
    }
  }
}
```

---

## 3. Walking a Full Token Lifecycle

Interactive API documentation is accessible in your browser at:
`http://127.0.0.1:8000/docs` (Swagger UI).

Below is the automated sequence executing the lifecycle via REST:

### Step 3.1: Desk Assisted Booking with Override
```powershell
$deskToken = "<DEV_DESK_JWT>"
$body = @{
    office_id       = "ward-central-01"
    service_id      = "srv-prop"
    category        = "NORMAL"
    phone           = "+919988776655"
    created_via     = "ASSISTED"
    override_reason = "AFTER_HOURS_VIP"
} | ConvertTo-Json

Invoke-RestMethod -Method POST -Uri "http://127.0.0.1:8000/v1/desk/tokens" `
    -Headers @{ "Authorization" = "Bearer $deskToken"; "Content-Type" = "application/json" } `
    -Body $body | ConvertTo-Json -Depth 4
```

**Recorded Output:**
```json
{
  "token": {
    "id": "fa5711f9-cb63-4cdb-ab5d-df9bd2ac58eb",
    "office_id": "ward-central-01",
    "service_id": "srv-prop",
    "business_date": "2026-10-02",
    "seq": 1,
    "display_code": "PT-001",
    "state": "WAITING",
    "category": "NORMAL",
    "priority_status": "VERIFIED",
    "created_via": "ASSISTED",
    "phone": "+919988776655",
    "beneficiary_name": null,
    "counter_id": null,
    "counter_label": null,
    "arrived_at": "2026-10-02T12:28:14.805994Z",
    "called_at": null,
    "grace_deadline": null,
    "serving_started_at": null,
    "completed_at": null,
    "last_eta_minutes": 999.0,
    "last_eta_reason": "COUNTER_DOWN",
    "eta_low": 999.0,
    "eta_high": 999.0,
    "waiting_ahead": 0,
    "now_serving": null,
    "server_time": "2026-10-02T12:28:14.814865Z"
  },
  "printable_code": "PT-001",
  "qr_data": "TOKEN:fa5711f9-cb63-4cdb-ab5d-df9bd2ac58eb:PT-001"
}
```

### Step 3.2: Officer Opens Counter & Calls Next Token
```powershell
$officerToken = "<DEV_OFFICER_JWT>"

# 1. Open Counter 2
Invoke-RestMethod -Method POST -Uri "http://127.0.0.1:8000/v1/officer/counters/cnt-2/status" `
    -Headers @{ "Authorization" = "Bearer $officerToken"; "Content-Type" = "application/json" } `
    -Body '{"status": "OPEN"}'

# 2. Call Next Token for Service 'srv-prop'
Invoke-RestMethod -Method POST -Uri "http://127.0.0.1:8000/v1/officer/counters/cnt-2/call-next" `
    -Headers @{ "Authorization" = "Bearer $officerToken"; "Content-Type" = "application/json" } `
    -Body '{"service_id": "srv-prop"}' | ConvertTo-Json -Depth 4
```

**Recorded Output:**
```json
{
  "id": "fa5711f9-cb63-4cdb-ab5d-df9bd2ac58eb",
  "office_id": "ward-central-01",
  "service_id": "srv-prop",
  "business_date": "2026-10-02",
  "seq": 1,
  "display_code": "PT-001",
  "state": "CALLED",
  "category": "NORMAL",
  "counter_id": "cnt-2",
  "counter_label": "Counter 2 (Property Tax & Assessment)",
  "called_at": "2026-10-02T12:28:55.681595Z",
  "grace_deadline": "2026-10-02T12:33:55.681595Z",
  "now_serving": "PT-001"
}
```

### Step 3.3: Officer Starts Serving
```powershell
Invoke-RestMethod -Method POST -Uri "http://127.0.0.1:8000/v1/officer/tokens/fa5711f9-cb63-4cdb-ab5d-df9bd2ac58eb/start" `
    -Headers @{ "Authorization" = "Bearer $officerToken"; "Content-Type" = "application/json" } `
    -Body '{"counter_id": "cnt-2"}' | ConvertTo-Json -Depth 4
```

**Recorded Output:**
```json
{
  "id": "fa5711f9-cb63-4cdb-ab5d-df9bd2ac58eb",
  "state": "SERVING",
  "counter_id": "cnt-2",
  "serving_started_at": "2026-10-02T12:28:55.786633Z"
}
```

### Step 3.4: Officer Completes Serving
```powershell
Invoke-RestMethod -Method POST -Uri "http://127.0.0.1:8000/v1/officer/tokens/fa5711f9-cb63-4cdb-ab5d-df9bd2ac58eb/complete" `
    -Headers @{ "Authorization" = "Bearer $officerToken"; "Content-Type" = "application/json" } `
    -Body '{"counter_id": "cnt-2", "outcome_code": "SERVED"}' | ConvertTo-Json -Depth 4
```

**Recorded Output:**
```json
{
  "id": "fa5711f9-cb63-4cdb-ab5d-df9bd2ac58eb",
  "state": "COMPLETED",
  "completed_at": "2026-10-02T12:28:55.804729Z"
}
```

---

## 4. Public Lobby Display Board

Public display boards require no authentication and expose counter labels and now-serving codes without personal citizen data.

```powershell
Invoke-RestMethod -Method GET -Uri "http://127.0.0.1:8000/v1/display/ward-central-01" | ConvertTo-Json -Depth 4
```

**Recorded Output:**
```json
{
  "office_id": "ward-central-01",
  "office_name": "Central Municipal Ward Office",
  "counters": [
    {
      "counter_label": "Counter 1 (Certificates & Civic)",
      "now_serving": null
    },
    {
      "counter_label": "Counter 2 (Property Tax & Assessment)",
      "now_serving": null
    },
    {
      "counter_label": "Counter 3 (Trade License & RTI)",
      "now_serving": null
    }
  ]
}
```

---

## 5. Running a Virtual Day Simulation

The simulator executes a full 8-hour virtual day with realistic arrivals, rushes, breaks, and priority requests.

### 5.1 Trigger Simulation
```powershell
$adminToken = "<DEV_ADMIN_JWT>"
Invoke-RestMethod -Method POST -Uri "http://127.0.0.1:8000/v1/admin/sim/ward-central-01/start" `
    -Headers @{ "Authorization" = "Bearer $adminToken" } | ConvertTo-Json
```
**Recorded Output:**
```json
{
  "status": "STARTED",
  "office_id": "ward-central-01"
}
```

### 5.2 Poll Simulation Status
```powershell
Invoke-RestMethod -Method GET -Uri "http://127.0.0.1:8000/v1/admin/sim/ward-central-01/status" `
    -Headers @{ "Authorization" = "Bearer $adminToken" } | ConvertTo-Json -Depth 4
```

**Recorded Output:**
```json
{
  "office_id": "ward-central-01",
  "status": "COMPLETED",
  "tokens_booked": 72,
  "tokens_served": 58,
  "tokens_no_show": 7,
  "tokens_cancelled": 0,
  "mae_live": 34.03448275862069,
  "mae_naive": 36.41379310344828,
  "within_range_pct": 6.896551724137931,
  "tick_count": 480
}
```

---

## 6. Aggregate Reporting & Accuracy Verification

### 6.1 Summary Report
```powershell
Invoke-RestMethod -Method GET -Uri "http://127.0.0.1:8000/v1/admin/reports/ward-central-01/summary?report_date=2050-01-01" `
    -Headers @{ "Authorization" = "Bearer $adminToken" } | ConvertTo-Json -Depth 4
```
**Recorded Output:**
```json
{
  "office_id": "ward-central-01",
  "date": "2050-01-01",
  "services": [
    {
      "service_id": "srv-bc",
      "served": 58,
      "cancelled": 0,
      "expired": 14,
      "no_show": 0,
      "waiting": 0,
      "avg_wait_minutes": "93.5",
      "p90_wait_minutes": "167.6",
      "avg_service_minutes": "12.8",
      "priority_count": 3,
      "priority_rejected": 0
    }
  ]
}
```

### 6.2 Load By Hour Report
```powershell
Invoke-RestMethod -Method GET -Uri "http://127.0.0.1:8000/v1/admin/reports/ward-central-01/load-by-hour?report_date=2050-01-01" `
    -Headers @{ "Authorization" = "Bearer $adminToken" } | ConvertTo-Json -Depth 4
```
**Recorded Output:**
```json
{
  "office_id": "ward-central-01",
  "date": "2050-01-01",
  "hourly": [
    {
      "service_id": "srv-bc",
      "hour_bucket": "2050-01-01T04:00:00",
      "tokens_booked": 4,
      "tokens_served": 4
    },
    {
      "service_id": "srv-bc",
      "hour_bucket": "2050-01-01T05:00:00",
      "tokens_booked": 5,
      "tokens_served": 5
    },
    {
      "service_id": "srv-bc",
      "hour_bucket": "2050-01-01T06:00:00",
      "tokens_booked": 31,
      "tokens_served": 31
    },
    {
      "service_id": "srv-bc",
      "hour_bucket": "2050-01-01T07:00:00",
      "tokens_booked": 8,
      "tokens_served": 8
    },
    {
      "service_id": "srv-bc",
      "hour_bucket": "2050-01-01T08:00:00",
      "tokens_booked": 7,
      "tokens_served": 6
    },
    {
      "service_id": "srv-bc",
      "hour_bucket": "2050-01-01T09:00:00",
      "tokens_booked": 10,
      "tokens_served": 2
    },
    {
      "service_id": "srv-bc",
      "hour_bucket": "2050-01-01T10:00:00",
      "tokens_booked": 3,
      "tokens_served": 1
    },
    {
      "service_id": "srv-bc",
      "hour_bucket": "2050-01-01T11:00:00",
      "tokens_booked": 3,
      "tokens_served": 0
    },
    {
      "service_id": "srv-bc",
      "hour_bucket": "2050-01-01T12:00:00",
      "tokens_booked": 1,
      "tokens_served": 1
    }
  ]
}
```

### 6.3 ETA Accuracy Report (MAE Proof)
```powershell
Invoke-RestMethod -Method GET -Uri "http://127.0.0.1:8000/v1/admin/reports/ward-central-01/eta-accuracy?report_date=2050-01-01" `
    -Headers @{ "Authorization" = "Bearer $adminToken" } | ConvertTo-Json -Depth 4
```
**Recorded Output:**
```json
{
  "office_id": "ward-central-01",
  "date": "2050-01-01",
  "engines": [
    {
      "engine": "live_adjusted",
      "n": 59,
      "mae_minutes": "34.68",
      "within_range_pct": "25.4"
    }
  ],
  "naive_mae": 37.03
}
```
*Proof: Live-Adjusted Engine achieves **34.68 min MAE**, strictly beating Naive baseline at **37.03 min MAE** across 59 evaluated tokens.*
