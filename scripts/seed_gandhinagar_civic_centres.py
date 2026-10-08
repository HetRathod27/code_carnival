import asyncio
import os
import sys
from datetime import time

sys.path.insert(0, os.path.abspath("."))

from sqlalchemy import select, text

from api.app.core.clock import SystemClock
from api.app.core.db import async_session_maker
from api.app.models.entities import (
    Counter,
    Office,
    OfficeSettings,
    QueueState,
    Service,
)

GANDHINAGAR_CENTRES = [
    {
        "id": "ward-central-01",
        "name": "Central Municipal Civic Centre (Sector 11)",
        "address": "Near Sachivalaya Complex & Mahatma Mandir, Sector 11, Gandhinagar - 382011",
        "timezone": "Asia/Kolkata",
        "open_time": time(9, 0),
        "close_time": time(18, 0),
        "qr_secret": "sec-gmc-sec11-secret-key-2026",
    },
    {
        "id": "gmc-sector-21",
        "name": "Sector 21 Jan Seva Kendra",
        "address": "District Shopping Centre Market, Near Gh-4 Road, Sector 21, Gandhinagar - 382021",
        "timezone": "Asia/Kolkata",
        "open_time": time(9, 0),
        "close_time": time(18, 0),
        "qr_secret": "sec-gmc-sec21-secret-key-2026",
    },
    {
        "id": "gmc-sector-24",
        "name": "Sector 24 Municipal Ward Office",
        "address": "Near Civil Hospital Road & GIDC Industrial Area, Sector 24, Gandhinagar - 382024",
        "timezone": "Asia/Kolkata",
        "open_time": time(9, 0),
        "close_time": time(17, 30),
        "qr_secret": "sec-gmc-sec24-secret-key-2026",
    },
    {
        "id": "gmc-kudasan",
        "name": "Kudasan Civic Facilitation Centre",
        "address": "Urjanagar Road, Near PDPU Knowledge Corridor, Kudasan, Gandhinagar - 382421",
        "timezone": "Asia/Kolkata",
        "open_time": time(9, 0),
        "close_time": time(18, 0),
        "qr_secret": "sec-gmc-kudasan-secret-key-2026",
    },
    {
        "id": "gmc-infocity",
        "name": "InfoCity IT Hub Civic Kendra",
        "address": "Infocity Complex, Super Mall-1, GH-0 Road, Gandhinagar - 382007",
        "timezone": "Asia/Kolkata",
        "open_time": time(9, 30),
        "close_time": time(18, 30),
        "qr_secret": "sec-gmc-infocity-secret-key-2026",
    },
    {
        "id": "gmc-sargasan",
        "name": "Sargasan Crossroads Jan Seva Kendra",
        "address": "Near Swaminarayan Dham & SG Highway Junction, Sargasan, Gandhinagar - 382421",
        "timezone": "Asia/Kolkata",
        "open_time": time(9, 0),
        "close_time": time(18, 0),
        "qr_secret": "sec-gmc-sargasan-secret-key-2026",
    },
    {
        "id": "amc-west-bodakdev",
        "name": "Bodakdev Civic Centre (West Zone)",
        "address": "Near Judges Bungalow Road, Bodakdev, Ahmedabad - 380054",
        "timezone": "Asia/Kolkata",
        "open_time": time(9, 0),
        "close_time": time(18, 0),
        "qr_secret": "sec-amc-bodakdev-secret-key-2026",
    },
    {
        "id": "amc-central-danapith",
        "name": "Danapith Municipal Civic Centre (Central Zone)",
        "address": "Opp. AMC Head Office, Danapith, Old City, Ahmedabad - 380001",
        "timezone": "Asia/Kolkata",
        "open_time": time(9, 0),
        "close_time": time(18, 0),
        "qr_secret": "sec-amc-danapith-secret-key-2026",
    },
    {
        "id": "amc-south-maninagar",
        "name": "Maninagar Jan Seva Kendra (South Zone)",
        "address": "Near Kankaria Lake Gate 3, Maninagar, Ahmedabad - 380008",
        "timezone": "Asia/Kolkata",
        "open_time": time(9, 0),
        "close_time": time(18, 0),
        "qr_secret": "sec-amc-maninagar-secret-key-2026",
    },
]

STANDARD_SERVICES = [
    {
        "suffix": "bc",
        "code": "BC",
        "names": {
            "en": "Birth & Death Certificate",
            "gu": "જન્મ અને મરણ પ્રમાણપત્ર",
            "hi": "जन्म और मृत्यु प्रमाण पत्र",
        },
        "prior_avg_minutes": 8.0,
        "priority_allowed": True,
        "requires_physical_visit": True,
        "required_docs": [
            {
                "id": "discharge_card",
                "name_en": "Hospital Discharge Card / Certificate",
                "name_gu": "હોસ્પિટલ ડિસ્ચાર્જ કાર્ડ / પ્રમાણપત્ર",
                "name_hi": "अस्पताल डिस्चार्ज कार्ड / प्रमाण पत्र",
            },
            {
                "id": "parents_id",
                "name_en": "Parents Photo ID Proof",
                "name_gu": "માતા-પિતાનું ઓળખ પુરાવો",
                "name_hi": "माता-पिता का फोटो पहचान पत्र",
            },
        ],
        "location_hint": {
            "en": "Ground Floor, Counter 1",
            "gu": "ગ્રાઉન્ડ ફ્લોર, કાઉન્ટર ૧",
            "hi": "भू-तल, काउंटर १",
        },
    },
    {
        "suffix": "prop",
        "code": "PT",
        "names": {
            "en": "Property Tax Payment & Assessment",
            "gu": "મિલકત વેરો આકારણી અને ભરપાઈ",
            "hi": "संपत्ति कर निर्धारण एवं भुगतान",
        },
        "prior_avg_minutes": 12.0,
        "priority_allowed": True,
        "requires_physical_visit": True,
        "required_docs": [
            {
                "id": "tax_bill",
                "name_en": "Previous Tax Receipt/Bill",
                "name_gu": "અગાઉની વેરા પાવતી/બિલ",
                "name_hi": "पिछली कर रसीद/बिल",
            },
            {
                "id": "property_deed",
                "name_en": "Property Index-2 / Title Document",
                "name_gu": "ઇન્ડેક્સ-૨ / દસ્તાવેજ",
                "name_hi": "इंडेक्स-2 / स्वामित्व दस्तावेज",
            },
        ],
        "location_hint": {
            "en": "Ground Floor, Counter 2",
            "gu": "ગ્રાઉન્ડ ફ્લોર, કાઉન્ટર ૨",
            "hi": "भू-तल, काउंटर २",
        },
    },
    {
        "suffix": "tax",
        "code": "TAX",
        "names": {
            "en": "Property Tax Assessment & Payment",
            "gu": "પ્રોપર્ટી ટેક્સ આકારણી અને ચૂકવણી",
            "hi": "प्रॉपर्टी टैक्स असेसमेंट और भुगतान",
        },
        "prior_avg_minutes": 15.0,
        "priority_allowed": True,
        "requires_physical_visit": False,
        "online_alternative_url": "https://gmc.gujarat.gov.in",
        "required_docs": [
            {
                "id": "tax_receipt",
                "name_en": "Previous Year Tax Receipt",
                "name_gu": "ગત વર્ષની ટેક્સ રસીદ",
                "name_hi": "पिछले वर्ष की कर रसीद",
            },
            {
                "id": "valid_id",
                "name_en": "Valid Photo ID Proof",
                "name_gu": "માન્ય ફોટો આઈડી પ્રૂફ",
                "name_hi": "वैध फोटो पहचान प्रमाण",
            },
        ],
        "location_hint": {
            "en": "Ground Floor, Counter 3",
            "gu": "ગ્રાઉન્ડ ફ્લોર, કાઉન્ટર ૩",
            "hi": "भू-तल, काउंटर ३",
        },
    },
    {
        "suffix": "trade",
        "code": "TL",
        "names": {
            "en": "Trade License & Shop Registration",
            "gu": "ટ્રેડ લાયસન્સ અને દુકાન નોંધણી",
            "hi": "ट्रेड लाइसेंस और दुकान पंजीकरण",
        },
        "prior_avg_minutes": 15.0,
        "priority_allowed": False,
        "requires_physical_visit": True,
        "required_docs": [
            {
                "id": "rent_agreement",
                "name_en": "Shop Rent Agreement / Ownership Proof",
                "name_gu": "દુકાન ભાડા કરાર / માલિકી પુરાવો",
                "name_hi": "दुकान किराया अनुबंध / स्वामित्व प्रमाण",
            },
            {
                "id": "fire_noc",
                "name_en": "NOC from Fire Services (if applicable)",
                "name_gu": "ફાયર એનઓસી (જો લાગુ પડે તો)",
                "name_hi": "फायर एनओसी (यदि लागू हो)",
            },
        ],
        "location_hint": {
            "en": "First Floor, Counter 4",
            "gu": "પહેલો માળ, કાઉન્ટર ૪",
            "hi": "प्रथम तल, काउंटर ४",
        },
    },
    {
        "suffix": "rti",
        "code": "RTI",
        "names": {
            "en": "RTI Application & Civic Grievances",
            "gu": "માહિતી અધિકાર (RTI) અને નાગરિક ફરિયાદ",
            "hi": "सूचना का अधिकार (RTI) और नागरिक शिकायतें",
        },
        "prior_avg_minutes": 10.0,
        "priority_allowed": True,
        "requires_physical_visit": True,
        "required_docs": [
            {
                "id": "written_application",
                "name_en": "Written Application / Form",
                "name_gu": "લેખિત અરજી / ફોર્મ",
                "name_hi": "लिखित आवेदन / फॉर्म",
            },
        ],
        "location_hint": {
            "en": "First Floor, Counter 5",
            "gu": "પહેલો માળ, કાઉન્ટર ૫",
            "hi": "प्रथम तल, काउंटर ५",
        },
    },
]

async def seed_gandhinagar_centres():
    clock = SystemClock()
    b_date = clock.business_date()
    now_dt = clock.now()

    print("=" * 60)
    print("SEEDING GANDHINAGAR CITY CIVIC CENTRES & SERVICES")
    print("=" * 60)

    async with async_session_maker() as session:
        for c_data in GANDHINAGAR_CENTRES:
            oid = c_data["id"]
            print(f"\nProcessing Civic Centre: {c_data['name']} ({oid})")
            
            # 1. Upsert Office
            res_off = await session.execute(select(Office).where(Office.id == oid))
            office = res_off.scalar_one_or_none()
            if not office:
                office = Office(
                    id=oid,
                    name=c_data["name"],
                    address=c_data["address"],
                    timezone=c_data["timezone"],
                    open_time=c_data["open_time"],
                    close_time=c_data["close_time"],
                    qr_secret=c_data["qr_secret"],
                    is_simulation=False,
                    active=True,
                    created_at=now_dt,
                )
                session.add(office)
                print(f"  [+] Created Office: {c_data['name']}")
            else:
                office.name = c_data["name"]
                office.address = c_data["address"]
                office.open_time = c_data["open_time"]
                office.close_time = c_data["close_time"]
                office.active = True
                print(f"  [*] Updated Office: {c_data['name']}")

            await session.flush()

            # 2. Upsert OfficeSettings
            res_set = await session.execute(select(OfficeSettings).where(OfficeSettings.office_id == oid))
            settings = res_set.scalar_one_or_none()
            if not settings:
                settings = OfficeSettings(
                    office_id=oid,
                    grace_minutes=5,
                    priority_every_n=3,
                    requeue_offset=5,
                    max_requeues=1,
                    close_grace_minutes=15,
                    max_active_tokens_per_phone=1,
                    strike_limit=3,
                    dispatch_window=3,
                    max_pass_overs=2,
                    max_waiting_per_service=100,
                    max_on_behalf_tokens=3,
                    on_my_way_extension_minutes=5,
                    retention_days=90,
                )
                session.add(settings)
                print("  [+] Added OfficeSettings")
            await session.flush()

            # 3. Create Universal Counter for this office
            cnt_all_id = f"cnt-all-{oid}" if oid != "ward-central-01" else "cnt-all"
            res_cnt_all = await session.execute(select(Counter).where(Counter.id == cnt_all_id))
            if not res_cnt_all.scalar_one_or_none():
                cnt_all = Counter(
                    id=cnt_all_id,
                    office_id=oid,
                    label=f"Universal Counter ({c_data['name'][:24]})",
                    status="OPEN",
                )
                session.add(cnt_all)
                await session.flush()

            # 4. Upsert Services & Counters
            for s_cfg in STANDARD_SERVICES:
                sid = f"srv-{s_cfg['suffix']}" if oid == "ward-central-01" else f"srv-{s_cfg['suffix']}-{oid}"
                cid = f"cnt-{sid}"

                res_svc = await session.execute(select(Service).where(Service.id == sid))
                svc = res_svc.scalar_one_or_none()
                if not svc:
                    svc = Service(
                        id=sid,
                        office_id=oid,
                        code=s_cfg["code"],
                        names=s_cfg["names"],
                        prior_avg_minutes=s_cfg["prior_avg_minutes"],
                        required_docs=s_cfg["required_docs"],
                        priority_allowed=s_cfg["priority_allowed"],
                        active=True,
                        requires_physical_visit=s_cfg["requires_physical_visit"],
                        online_alternative_url=s_cfg.get("online_alternative_url"),
                        location_hint=s_cfg["location_hint"],
                    )
                    session.add(svc)
                    print(f"    [+] Created Service: {s_cfg['names']['en']} ({sid})")
                else:
                    svc.names = s_cfg["names"]
                    svc.required_docs = s_cfg["required_docs"]
                    svc.priority_allowed = s_cfg["priority_allowed"]
                    svc.active = True

                await session.flush()

                # Upsert Counter for this service
                res_cnt = await session.execute(select(Counter).where(Counter.id == cid))
                if not res_cnt.scalar_one_or_none():
                    cnt = Counter(
                        id=cid,
                        office_id=oid,
                        label=f"Counter ({s_cfg['names']['en']})",
                        status="OPEN",
                    )
                    session.add(cnt)
                    await session.flush()

                # Map counter_services
                await session.execute(text("""
                    INSERT INTO counter_services (counter_id, service_id)
                    VALUES (:cid, :sid)
                    ON CONFLICT (counter_id, service_id) DO NOTHING;
                """), {"cid": cid, "sid": sid})

                # Map to Universal Counter
                await session.execute(text("""
                    INSERT INTO counter_services (counter_id, service_id)
                    VALUES (:cnt_all_id, :sid)
                    ON CONFLICT (counter_id, service_id) DO NOTHING;
                """), {"cnt_all_id": cnt_all_id, "sid": sid})

                # 5. Ensure QueueState exists
                res_qs = await session.execute(select(QueueState).where(
                    QueueState.office_id == oid,
                    QueueState.service_id == sid,
                    QueueState.business_date == b_date,
                ))
                if not res_qs.scalar_one_or_none():
                    qs = QueueState(
                        office_id=oid,
                        service_id=sid,
                        business_date=b_date,
                        last_seq=0,
                        calls_since_priority=0,
                        now_serving=None,
                        waiting_count=0,
                        paused=False,
                        version=1,
                        updated_at=now_dt,
                    )
                    session.add(qs)
                    await session.flush()

        await session.commit()
        print("\n" + "=" * 60)
        print("ALL GANDHINAGAR CIVIC CENTRES SEEDED SUCCESSFULLY!")
        print("=" * 60)

if __name__ == "__main__":
    asyncio.run(seed_gandhinagar_centres())
