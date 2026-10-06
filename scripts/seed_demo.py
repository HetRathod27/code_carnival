"""
QueueLess Demonstration Database Seeder.
Populates standard municipal offices, services, counters, staff credentials,
and initial queue state for live demonstration and judging evaluation.
"""

import asyncio
from datetime import date, datetime, time, timedelta, timezone
import os
import sys

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker

# Ensure api is in Python path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from api.app.core.config import settings
from api.app.models.entities import (
    Counter,
    CounterService,
    Office,
    OfficeSettings,
    Profile,
    QueueState,
    Service,
    Token,
    TokenEvent,
)


async def seed() -> None:
    db_url = settings.DATABASE_URL
    print(f"[*] Connecting to database: {db_url}")

    engine = create_async_engine(db_url, echo=False)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with async_session() as session:
        # 1. Seed Municipal Ward Office
        office_id = "ward-central-01"
        res = await session.execute(select(Office).where(Office.id == office_id))
        office = res.scalar_one_or_none()
        if not office:
            office = Office(
                id=office_id,
                name="Central Ward Civic Centre",
                address="Opp. Town Hall, Ellisbridge, Ahmedabad, Gujarat 380006",
                timezone="Asia/Kolkata",
                open_time=time(9, 0),
                close_time=time(18, 0),
                active=True,
            )
            session.add(office)
            print(f"[+] Created Office: {office.name}")

        # 2. Seed Office Settings
        res_set = await session.execute(select(OfficeSettings).where(OfficeSettings.office_id == office_id))
        office_settings = res_set.scalar_one_or_none()
        if not office_settings:
            office_settings = OfficeSettings(
                office_id=office_id,
                priority_ratio=0.25,
                grace_period_minutes=5,
                strike_limit=3,
                strike_block_days=30,
                close_grace_minutes=15,
                max_waiting_per_service=60,
                on_my_way_extension_minutes=5,
                retention_days=90,
            )
            session.add(office_settings)
            print("[+] Configured Office Settings (5-min buffer, 25% priority share)")

        # 3. Seed Civic Services
        services_data = [
            {
                "id": "srv-bc",
                "code": "BC",
                "names": {
                    "en": "Birth & Death Registration",
                    "gu": "જન્મ અને મરણ નોંધણી",
                    "hi": "जन्म एवं मृत्यु पंजीकरण",
                },
                "prior_avg_minutes": 10.0,
                "required_docs": [
                    {
                        "name_en": "Hospital Discharge Summary / Certificate",
                        "name_gu": "હોસ્પિટલ ડિસ્ચાર્જ સારાંશ / પ્રમાણપત્ર",
                        "name_hi": "अस्पताल डिस्चार्ज सारांश / प्रमाण पत्र",
                    },
                    {
                        "name_en": "Parents Photo ID Proof",
                        "name_gu": "માતાપિતાનું ફોટો ઓળખકાર્ડ",
                        "name_hi": "माता-पिता का फोटो पहचान पत्र",
                    },
                    {
                        "name_en": "Marriage Certificate (if applicable)",
                        "name_gu": "લગ્ન પ્રમાણપત્ર (જો લાગુ હોય તો)",
                        "name_hi": "विवाह प्रमाण पत्र (यदि लागू हो)",
                    },
                ],
                "priority_allowed": True,
                "requires_physical_visit": True,
                "online_alternative_url": None,
            },
            {
                "id": "srv-tax",
                "code": "TAX",
                "names": {
                    "en": "Property Tax Assessment & Payment",
                    "gu": "મિલકત વેરા આકારણી અને ભરપાઈ",
                    "hi": "संपत्ति कर निर्धारण एवं भुगतान",
                },
                "prior_avg_minutes": 15.0,
                "required_docs": [
                    {
                        "name_en": "Previous Year Tax Receipt",
                        "name_gu": "પાછલા વર્ષની ટેક્સ પહોંચ / રસીદ",
                        "name_hi": "पिछले वर्ष की कर रसीद",
                    },
                    {
                        "name_en": "Property Index-2 / Title Document",
                        "name_gu": "મિલકત ઇન્ડેક્સ-૨ / દસ્તાવેજ",
                        "name_hi": "संपत्ति इंडेक्स-2 / शीर्षक दस्तावेज़",
                    },
                    {
                        "name_en": "Valid Photo ID",
                        "name_gu": "માન્ય ફોટો ઓળખકાર્ડ",
                        "name_hi": "मान्य फोटो पहचान पत्र",
                    },
                ],
                "priority_allowed": True,
                "requires_physical_visit": False,
                "online_alternative_url": "https://ahmedabadcity.gov.in/tax",
            },
            {
                "id": "srv-trade",
                "code": "TRD",
                "names": {
                    "en": "Trade & Commercial License",
                    "gu": "વેપાર અને વાણિજ્ય લાઇસન્સ",
                    "hi": "व्यापार एवं वाणिज्यिक लाइसेंस",
                },
                "prior_avg_minutes": 20.0,
                "required_docs": [
                    {
                        "name_en": "Premises Rent Agreement / Ownership Proof",
                        "name_gu": "જગ્યાનો ભાડા કરાર / માલિકી પુરાવો",
                        "name_hi": "परिसर किराया समझौता / स्वामित्व प्रमाण",
                    },
                    {
                        "name_en": "NOC from Fire & Emergency Services",
                        "name_gu": "ફાયર અને ઇમરજન્સી સેવાઓ તરફથી એનઓસી",
                        "name_hi": "अग्निशमन एवं आपातकालीन सेवाओं से एनओसी",
                    },
                    {
                        "name_en": "Partnership Deed / Incorporation Certificate",
                        "name_gu": "ભાગીદારી ડીડ / ઇન્કોર્પોરેશન પ્રમાણપત્ર",
                        "name_hi": "साझेदारी विलेख / निगमन प्रमाणपत्र",
                    },
                ],
                "priority_allowed": False,
                "requires_physical_visit": True,
                "online_alternative_url": None,
            },
        ]

        for s_data in services_data:
            s_res = await session.execute(select(Service).where(Service.id == s_data["id"]))
            existing_service = s_res.scalar_one_or_none()
            if not existing_service:
                service = Service(
                    id=s_data["id"],
                    office_id=office_id,
                    code=s_data["code"],
                    names=s_data["names"],
                    prior_avg_minutes=s_data["prior_avg_minutes"],
                    required_docs=s_data["required_docs"],
                    priority_allowed=s_data["priority_allowed"],
                    requires_physical_visit=s_data["requires_physical_visit"],
                    online_alternative_url=s_data["online_alternative_url"],
                    active=True,
                )
                session.add(service)
                print(f"[+] Created Service: {s_data['code']} - {s_data['names']['en']}")
            else:
                existing_service.required_docs = s_data["required_docs"]
                session.add(existing_service)
                print(f"[+] Updated required_docs for Service: {s_data['code']}")

        # 4. Seed Service Counters
        counters_data = [
            {"id": "ctr-01", "label": "Counter 1 (Civil Registration)", "services": ["srv-bc"]},
            {"id": "ctr-02", "label": "Counter 2 (Revenue & Property Tax)", "services": ["srv-tax"]},
            {"id": "ctr-03", "label": "Counter 3 (Commercial & Trade)", "services": ["srv-trade", "srv-tax"]},
        ]

        for c_data in counters_data:
            c_res = await session.execute(select(Counter).where(Counter.id == c_data["id"]))
            if not c_res.scalar_one_or_none():
                counter = Counter(
                    id=c_data["id"],
                    office_id=office_id,
                    label=c_data["label"],
                    status="OPEN",
                )
                session.add(counter)
                for srv_id in c_data["services"]:
                    session.add(CounterService(counter_id=c_data["id"], service_id=srv_id))
                print(f"[+] Created Counter: {c_data['label']}")

        # 5. Seed Staff Personas & User Profiles
        now = datetime.now(timezone.utc)
        profiles_data = [
            {
                "id": "officer-01",
                "role": "OFFICER",
                "phone": "+919800000001",
                "name": "Rajesh Sharma (Senior Officer)",
                "language": "en",
            },
            {
                "id": "desk-01",
                "role": "DESK",
                "phone": "+919800000002",
                "name": "Pooja Patel (Help Desk)",
                "language": "gu",
            },
            {
                "id": "admin-01",
                "role": "ADMIN",
                "phone": "+919800000003",
                "name": "Kirit Mehta (Centre Administrator)",
                "language": "en",
            },
            {
                "id": "citizen-01",
                "role": "CITIZEN",
                "phone": "+919876543210",
                "name": "Aarav Shah (Citizen)",
                "language": "en",
            },
        ]

        for p_data in profiles_data:
            p_res = await session.execute(select(Profile).where(Profile.id == p_data["id"]))
            if not p_res.scalar_one_or_none():
                profile = Profile(
                    id=p_data["id"],
                    office_id=office_id,
                    role=p_data["role"],
                    phone=p_data["phone"],
                    name=p_data["name"],
                    language=p_data["language"],
                    created_at=now,
                )
                session.add(profile)
                print(f"[+] Created Profile: {p_data['name']} [{p_data['role']}]")

        # 6. Initialize Queue State for Today
        today = date.today()
        for s_data in services_data:
            q_res = await session.execute(
                select(QueueState).where(
                    QueueState.office_id == office_id,
                    QueueState.service_id == s_data["id"],
                    QueueState.business_date == today,
                )
            )
            if not q_res.scalar_one_or_none():
                q_state = QueueState(
                    office_id=office_id,
                    service_id=s_data["id"],
                    business_date=today,
                    last_seq=0,
                    waiting_count=0,
                    version=1,
                    updated_at=now,
                )
                session.add(q_state)

        await session.commit()
        print("\n" + "=" * 60)
        print("  QUEUELESS DEMO DATA SEEDED SUCCESSFULLY")
        print("=" * 60)
        print("Demo Credentials & Personas:")
        print(" - Officer:   +919800000001 (Role: OFFICER, Counter 1)")
        print(" - Help Desk: +919800000002 (Role: DESK, assisted slips & walk-ins)")
        print(" - Admin:     +919800000003 (Role: ADMIN, settings & QR codes)")
        print(" - Citizen:   +919876543210 (Role: CITIZEN, mobile app fixed booking)")
        print("\nWeb URLs:")
        print(" - Staff Dashboard: http://localhost:5173/")
        print(f" - Public TV Board: http://localhost:5173/display/{office_id}")
        print("=" * 60 + "\n")


if __name__ == "__main__":
    asyncio.run(seed())
