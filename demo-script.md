# QueueLess — Live Demonstration Script & Judge Walkthrough
> **End-to-End Civic Appointment & Queue Management Walkthrough**  
> *Demonstrating Technical Specification v3 compliance: Fixed Online Slots, Physical Walk-Ins, Printed Turn Slips, Officer Operations, 'I'm on My Way' Buffer, and Live Lobby Display.*

---

## 1. Preparation & Environment Startup

Ensure the database is seeded and services are running:

```powershell
# 1. Seed the demo environment
python scripts/seed_demo.py

# 2. Start the API service (Terminal 1)
.\venv\Scripts\uvicorn.exe api.app.main:app --port 8000 --reload

# 3. Start the Web Dashboard (Terminal 2)
cd web
npm run dev

# 4. Start the Citizen Mobile App / Web View (Terminal 3)
cd mobile
flutter run -d chrome
```

---

## 2. Walkthrough Act 1: The Citizen Mobile Experience

### Step 1: Language Picker & Onboarding
1. Open the Flutter app.
2. Select your preferred language: **English**, **ગુજરાતી (Gujarati)**, or **हिन्दी (Hindi)**.
3. The interface immediately switches to native trilingual typography using Google Stitch Civic tokens.
4. Enter phone number `+919876543210` and tap **"Send OTP"** ➔ enter `123456` to log in as Citizen **Aarav Shah**.

### Step 2: Civic Centre & Service Directory
1. Browse civic centres and select **"Ward Central Office 01"**.
2. Notice the office hours (09:00 - 18:00) and live indicative wait time chips.
3. Select **"Birth Certificate Registration"** (`srv-bc`):
   - Average duration: **15 mins**.
   - Review the document checklist: *Hospital Discharge Summary, Parents' Aadhaar Cards (for verification only), Marriage Certificate*.
   - Notice the **Online Alternative Alert**: *"Can be completed online at digitalgujarat.gov.in without visiting!"* with a direct external link.

### Step 3: Document Confirmation Gating & Slot Booking
1. Switch booking category between **General Access** and **Priority Access** (Senior Citizen / PwD / Pregnant).
2. Attempt to tap **"Confirm Appointment"**:
   - The button is strictly **disabled** until the mandatory confirmation checkbox is ticked:  
     *"I confirm that I have all required original documents ready for this visit."* (Spec Section 2.1 Principle 14).
3. Check the confirmation box and tap **"Confirm Appointment"**.
4. A fixed slot appointment token is generated (e.g. `BC-001`).

### Step 4: Live Token Tracking & "I'm on My Way"
1. View the token dashboard:
   - **54px high-contrast token identifier** (`BC-001`).
   - Queue position: *"You are #1 in line"*.
   - Live estimated turn time with ±5 min confidence range.
2. Simulate running late:
   - Tap **"I'm on My Way (+5 min)"**.
   - The ETA engine immediately logs the grace period request, pushes the buffer, and disables the button to enforce the single-claim rule.

---

## 3. Walkthrough Act 2: Help Desk & Physical Walk-In Slips

### Step 1: Help Desk Operator Sign-In
1. Navigate to the Web Dashboard at `http://localhost:5173/`.
2. Click the **"Help Desk"** persona card (`Pooja Patel`).
3. You are redirected to the `/desk` assisted booking terminal.

### Step 2: Registering a Walk-In Citizen
1. An elderly citizen visits the desk without a smartphone to pay Property Tax.
2. Select Service: **"Property Tax Assessment & Payment"** (`srv-tax`).
3. Check **"Priority Access (Senior Citizen / PwD)"**.
4. Enter Phone Number: `+919812345678`.
5. Enter Citizen Name: `Rameshbhai Patel`.
6. Tap **"Generate Token & Print Slip"**.

### Step 3: Physical Turn Slip Preview
1. A thermal 80mm printable turn slip modal appears automatically:
   - Official municipal header: *Ward Central Civic Centre*.
   - High-contrast display code: `TAX-002`.
   - Current Queue Status: *Estimated Turn: 10:45 AM (Wait: ~15 mins)*.
   - Verification QR Code.
   - Document checklist reminder.
2. Tap **"Print Turn Slip"** to simulate thermal dispatch, or **"Done"** to complete.

---

## 4. Walkthrough Act 3: Public TV Lobby Board

1. Open `http://localhost:5173/display/ward-central-01` in a separate browser window or fullscreen display.
2. **Observe privacy preservation**:
   - Only token display codes (e.g. `BC-001`, `TAX-002`) and counter numbers are visible.
   - Citizen names, phone numbers, and Aadhaar numbers are **never** rendered on public boards.
3. Notice the high-visibility civic color scheme:
   - **Green badge**: Currently serving at Counter 1.
   - **Amber badge**: Arrived & Next in line.
   - **Audible Chime**: Alerts waiting citizens whenever a token is called.

---

## 5. Walkthrough Act 4: Officer Operations & Live Queue Management

### Step 1: Officer Sign-In & Counter Selection
1. Open a new window and sign in as **Rajesh Sharma (Senior Officer)** (`+919800000001`).
2. Select **Counter 1 (Civil Registration)**.
3. View the live queue dashboard:
   - Queue summary tiles (Waiting count, Average service time, Queue health).
   - Real-time list of waiting citizens separated by category (Online appointments vs. Physical walk-ins).

### Step 2: Dynamic Walk-In Utilization & Serving
1. Citizen `BC-001` has not arrived yet.
2. Officer taps **"Call Next Available"**:
   - The system automatically serves the physical walk-in token (`TAX-002`) because the online appointment has not checked in.
   - The Public TV board chimes and updates: *"Now Serving TAX-002 at Counter 1"*.
3. Verify presence:
   - Citizen presents QR code; officer validates token status.
4. Mark Serving:
   - Tap **"Start Serving"**.
   - Officer completes document verification.
   - Tap **"Complete Service"**.
   - Token transitions to `COMPLETED` and is logged in `token_events`.

### Step 3: Service Pause & Reason Auditing
1. Officer needs to step out for official duties.
2. Tap **"Pause Counter"**.
3. A modal prompts for an official reason (e.g. *"System Maintenance"*, *"Lunch Break"*, *"Document Verification Meeting"*).
4. Select a reason and confirm.
5. The queue status updates across all connected citizen devices and the ETA engine recalculates downstream arrival estimates.

---

## 6. Walkthrough Act 5: Administration & Simulation Intelligence

### Step 1: Admin Settings & QR Code Generator
1. Switch role to **Kirit Mehta (Centre Administrator)**.
2. Open `/admin`:
   - Adjust grace periods, priority ratio share (default 25%), strike limits, and retention periods.
   - Generate official office check-in QR poster for citizen self-verification.

### Step 2: Queue Simulator & ETA Accuracy Proof
1. Navigate to `/sim` (Simulation Control Center).
2. Run a 100-citizen virtual queue simulation:
   - Watch the virtual clock accelerate through morning peak hours.
   - Inspect the live metric comparison:
     - **Naive Static ETA (MAE)** vs. **Live-Adjusted ETA (MAE)**.
   - Confirm mathematical superiority: **`MAE_Live < MAE_Naive`**, proving the accuracy of the dynamic feedback loop.

---

## 7. Wrap-Up & Evaluation Summary

| Feature Verified | Specification Requirement | Verification Status |
|---|---|---|
| **Fixed Online Booking** | Spec v3 Section 1.1 | Passed (Flutter Citizen App) |
| **Physical Turn Slips** | Spec v3 Section 2.2 | Passed (Desk Printable Modal) |
| **No-Wait Walk-In Utilization** | Spec v3 Superseding Rule | Passed (Officer Dispatch Engine) |
| **Document Gating** | Spec Section 2.1 Principle 14 | Passed (Strict Confirmation Checkbox) |
| **Public Board Privacy** | Spec Section 11 | Passed (Zero citizen PII displayed) |
| **Live ETA Feedback Loop** | Spec Section 4 | Passed (`MAE_Live < MAE_Naive` regression) |
