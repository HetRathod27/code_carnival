import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/api/client.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/book/book_screen.dart';
import 'package:mobile/features/browse/offices_screen.dart';
import 'package:mobile/features/browse/services_screen.dart';
import 'package:mobile/l10n/app_localizations.dart';

class FakeApiClient extends ApiClient {
  final List<OfficeModel> offices;
  final List<ServiceModel> services;
  final TokenModel? tokenToReturn;
  final List<SlotItemModel>? slots;

  FakeApiClient({
    this.offices = const [],
    this.services = const [],
    this.tokenToReturn,
    this.slots,
  });

  @override
  Future<List<OfficeModel>> fetchOffices() async {
    return offices;
  }

  @override
  Future<List<ServiceModel>> fetchServices(String officeId) async {
    return services;
  }

  @override
  Future<List<SlotItemModel>> fetchSlots({
    required String officeId,
    required String serviceId,
    String? date,
    int partySize = 1,
  }) async {
    if (slots != null) return slots!;
    return [
      SlotItemModel(
        slotTime: '09:30 AM – 10:30 AM',
        startTime: '09:30:00',
        endTime: '10:30:00',
        available: true,
        status: 'AVAILABLE',
        reasonCode: 'AVAILABLE',
        remainingCapacity: 4,
        bookedCount: 0,
        totalCapacity: 4,
      ),
      SlotItemModel(
        slotTime: '10:30 AM – 11:30 AM',
        startTime: '10:30:00',
        endTime: '11:30:00',
        available: true,
        status: 'AVAILABLE',
        reasonCode: 'AVAILABLE',
        remainingCapacity: 4,
        bookedCount: 0,
        totalCapacity: 4,
      ),
      SlotItemModel(
        slotTime: '11:30 AM – 12:30 PM',
        startTime: '11:30:00',
        endTime: '12:30:00',
        available: false,
        status: 'TIME_PASSED',
        reasonCode: 'TIME_PASSED',
        remainingCapacity: 4,
        bookedCount: 0,
        totalCapacity: 4,
      ),
      SlotItemModel(
        slotTime: '02:00 PM – 03:00 PM',
        startTime: '14:00:00',
        endTime: '15:00:00',
        available: false,
        status: 'FULLY_BOOKED',
        reasonCode: 'FULLY_BOOKED',
        remainingCapacity: 0,
        bookedCount: 4,
        totalCapacity: 4,
      ),
    ];
  }

  @override
  Future<TokenModel> bookToken({
    required String token,
    required String officeId,
    required String serviceId,
    required String category,
    required String phone,
    String? beneficiaryName,
    String? priorityDocType,
    int travelMinutes = 0,
    String? appointmentDate,
    String? appointmentSlot,
    bool isFixed = true,
    List<Map<String, dynamic>>? accompanyingMembers,
    required String idempotencyKey,
  }) async {
    if (tokenToReturn != null) return tokenToReturn!;
    final childTokens = <TokenModel>[];
    if (accompanyingMembers != null) {
      for (int i = 0; i < accompanyingMembers.length; i++) {
        final cSeq = i + 2;
        childTokens.add(TokenModel(
          id: 'tok-child-${i + 1}',
          officeId: officeId,
          serviceId: serviceId,
          businessDate: '2026-10-05',
          seq: cSeq,
          displayCode: 'TAX-00$cSeq',
          state: 'WAITING',
          category: category,
          priorityStatus: category == 'PRIORITY' ? 'PRIORITY' : 'NONE',
          createdVia: 'ONLINE',
          waitingAhead: i + 1,
          beneficiaryName: accompanyingMembers[i]['name'] as String?,
          appointmentSlot: accompanyingMembers[i]['slot_time'] as String?,
          parentTokenId: 'tok-123',
        ));
      }
    }
    return TokenModel(
      id: 'tok-123',
      officeId: officeId,
      serviceId: serviceId,
      businessDate: '2026-10-05',
      seq: 1,
      displayCode: 'TAX-001',
      state: 'WAITING',
      category: category,
      priorityStatus: category == 'PRIORITY' ? 'PRIORITY' : 'NONE',
      createdVia: 'ONLINE',
      waitingAhead: 0,
      beneficiaryName: beneficiaryName,
      appointmentSlot: appointmentSlot,
      childTokens: childTokens,
    );
  }
}

Widget createTestApp(Widget child, [Locale locale = const Locale('en')]) {
  return MaterialApp(
    theme: CivicTheme.lightTheme,
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'ql_phone': '+919876543210',
      'ql_token': 'fake_token',
      'ql_language': 'en',
    });
  });

  final sampleOffices = [
    OfficeModel(
      id: 'off-1',
      name: 'Central Ward Office',
      address: 'Opp. Town Hall, Ellisbridge, Ahmedabad',
      timezone: 'Asia/Kolkata',
      openTime: '09:00',
      closeTime: '17:00',
    ),
    OfficeModel(
      id: 'off-2',
      name: 'North Zone Civic Centre',
      address: 'Memnagar Road, Ahmedabad',
      timezone: 'Asia/Kolkata',
      openTime: '09:30',
      closeTime: '17:30',
    ),
  ];

  final sampleServices = [
    ServiceModel(
      id: 'srv-1',
      officeId: 'off-1',
      code: 'TAX',
      names: {
        'en': 'Property Tax Assessment',
        'gu': 'મિલકત વેરા આકારણી',
        'hi': 'संपत्ति कर निर्धारण',
      },
      priorAvgMinutes: 15.0,
      requiredDocs: [
        {'name': 'Identity Proof (Voter ID / PAN)'},
        {'name': 'Previous Tax Receipt'},
        {'name': 'Electricity Bill / Title Deed'},
      ],
      priorityAllowed: true,
      requiresPhysicalVisit: true,
      onlineAlternativeUrl: 'https://ahmedabadcity.gov.in/tax',
      indicativeWaitMinutes: 25,
    ),
    ServiceModel(
      id: 'srv-2',
      officeId: 'off-1',
      code: 'BIRTH',
      names: {
        'en': 'Birth Certificate',
        'gu': 'જન્મ પ્રમાણપત્ર',
        'hi': 'जन्म प्रमाण पत्र',
      },
      priorAvgMinutes: 10.0,
      requiredDocs: [
        {'name': 'Hospital Discharge Summary'},
        {'name': 'Parents Photo ID'},
      ],
      priorityAllowed: false,
      requiresPhysicalVisit: true,
      indicativeWaitMinutes: 0,
    ),
  ];

  group('F1: Citizen App A - Office and Service Browsing', () {
    testWidgets('OfficesScreen renders civic centres with hours and address', (tester) async {
      final fakeClient = FakeApiClient(offices: sampleOffices);
      await tester.pumpWidget(createTestApp(OfficesScreen(client: fakeClient)));
      await tester.pumpAndSettle();

      // Verify offices list rendered
      expect(find.text('Central Ward Office'), findsOneWidget);
      expect(find.text('North Zone Civic Centre'), findsOneWidget);
      expect(find.text('Opp. Town Hall, Ellisbridge, Ahmedabad'), findsOneWidget);
      expect(find.text('Operating Hours: 09:00 – 17:00'), findsOneWidget);
    });

    testWidgets('ServicesScreen renders service items with details and online portal notification', (tester) async {
      final fakeClient = FakeApiClient(services: sampleServices);
      await tester.pumpWidget(createTestApp(ServicesScreen(officeId: 'off-1', client: fakeClient)));
      await tester.pumpAndSettle();

      // Verify services rendered
      expect(find.text('Property Tax Assessment'), findsOneWidget);
      expect(find.text('TAX'), findsOneWidget);
      expect(find.text('⭐ Priority Allowed'), findsOneWidget);

      // Verify online alternative banner shown when URL present
      expect(find.textContaining('This service is also available online'), findsOneWidget);

      // Verify second service
      expect(find.text('Birth Certificate'), findsOneWidget);
      expect(find.text('BIRTH'), findsOneWidget);
    });

    testWidgets('ServicesScreen renders Gujarati translations when locale is gu', (tester) async {
      final fakeClient = FakeApiClient(services: sampleServices);
      await tester.pumpWidget(createTestApp(
        ServicesScreen(officeId: 'off-1', client: fakeClient),
        const Locale('gu'),
      ));
      await tester.pumpAndSettle();

      // Verify Gujarati service name from service.names['gu']
      expect(find.text('મિલકત વેરા આકારણી'), findsOneWidget);
      expect(find.text('જન્મ પ્રમાણપત્ર'), findsOneWidget);
    });
  });

  group('F1: Citizen App A - Document Checklist and Mandatory Confirmation Gating', () {
    testWidgets('BookScreen displays document checklist and gates booking button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeClient = FakeApiClient(services: sampleServices);
      await tester.pumpWidget(createTestApp(
        BookScreen(officeId: 'off-1', serviceId: 'srv-1', client: fakeClient),
      ));
      await tester.pumpAndSettle();

      // Verify Service Header
      expect(find.text('Property Tax Assessment'), findsOneWidget);
      expect(find.text('TAX'), findsOneWidget);

      // Verify Document Checklist rendered
      expect(find.text('Required Document Checklist'), findsOneWidget);
      expect(find.text('Identity Proof (Voter ID / PAN)'), findsOneWidget);
      expect(find.text('Previous Tax Receipt'), findsOneWidget);
      expect(find.text('Electricity Bill / Title Deed'), findsOneWidget);

      // Verify mandatory confirmation checkbox exists
      final checkboxFinder = find.byKey(const Key('mandatory_document_checkbox'));
      expect(checkboxFinder, findsOneWidget);

      // Find the Book Fixed Appointment button
      final bookButtonFinder = find.widgetWithText(ElevatedButton, 'Book Fixed Appointment');
      expect(bookButtonFinder, findsOneWidget);

      // Assert button is DISABLED before checking confirmation
      final initialButton = tester.widget<ElevatedButton>(bookButtonFinder);
      expect(initialButton.onPressed, isNull, reason: 'Book button must be disabled until documents confirmed');

      // Tap the mandatory confirmation checkbox first
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      // Assert button is STILL DISABLED because individual document checkboxes are not yet checked
      final stillDisabledButton = tester.widget<ElevatedButton>(bookButtonFinder);
      expect(stillDisabledButton.onPressed, isNull, reason: 'Book button must remain disabled until every document checkbox is also selected');

      // Check all 3 document checkboxes
      for (int i = 0; i < 3; i++) {
        final docCheckboxFinder = find.byKey(Key('doc_checkbox_$i'));
        expect(docCheckboxFinder, findsOneWidget);
        await tester.tap(docCheckboxFinder);
        await tester.pumpAndSettle();
      }

      // Assert button is now ENABLED (every document + final confirmation checked)
      final enabledButton = tester.widget<ElevatedButton>(bookButtonFinder);
      expect(enabledButton.onPressed, isNotNull, reason: 'Book button must be enabled once all documents and final confirmation are confirmed');

      // Tap Book Fixed Appointment to open bottom sheet
      await tester.tap(bookButtonFinder);
      await tester.pumpAndSettle();
      expect(find.text('Choose an Available Appointment Slot'), findsOneWidget);

      // Verify standard slot fee starts at ₹20
      expect(find.textContaining('Normal Slot (Within 2 Days) • ₹20 Standard Fee'), findsOneWidget);

      // Select 'In 2 Days' chip -> should switch to higher fee (₹50)
      final in2DaysFinder = find.text('In 2 Days');
      expect(in2DaysFinder, findsOneWidget);
      await tester.tap(in2DaysFinder);
      await tester.pumpAndSettle();
      expect(find.textContaining('Custom Future Slot • Higher Fee (₹50)'), findsOneWidget);

      // Tap Confirm Appointment to submit booking
      final confirmBtn = find.textContaining('Confirm Appointment • Higher Fee: ₹50');
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Verify confirmation dialog displays token
      expect(find.textContaining('Appointment Confirmed!'), findsOneWidget);
      expect(find.text('TAX-001'), findsAtLeast(1));
    });

    testWidgets('Priority access selection is removed from normal citizen booking UI', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeClient = FakeApiClient(services: sampleServices);
      await tester.pumpWidget(createTestApp(
        BookScreen(officeId: 'off-1', serviceId: 'srv-1', client: fakeClient),
      ));
      await tester.pumpAndSettle();

      // Verify citizen cannot self-select Priority Access
      final priorityChip = find.text('Priority Access');
      expect(priorityChip, findsNothing, reason: 'Citizens should not self-select Priority Access in normal booking');
    });

    testWidgets('Core Rule 11: Button height is at least 56px', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeClient = FakeApiClient(services: sampleServices);
      await tester.pumpWidget(createTestApp(
        BookScreen(officeId: 'off-1', serviceId: 'srv-1', client: fakeClient),
      ));
      await tester.pumpAndSettle();

      final bookButtonFinder = find.widgetWithText(ElevatedButton, 'Book Fixed Appointment');
      final size = tester.getSize(bookButtonFinder);
      expect(size.height, greaterThanOrEqualTo(56.0), reason: 'Rule 11 touch target requires >= 56px height');
    });

    testWidgets('Party size capped at max 4 people and gates accompanying person details', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeClient = FakeApiClient(services: sampleServices);
      await tester.pumpWidget(createTestApp(
        BookScreen(officeId: 'off-1', serviceId: 'srv-1', client: fakeClient),
      ));
      await tester.pumpAndSettle();

      // Check all documents to enable booking sheet
      await tester.tap(find.byKey(const Key('mandatory_document_checkbox')));
      await tester.pumpAndSettle();
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byKey(Key('doc_checkbox_$i')));
        await tester.pumpAndSettle();
      }

      // Open time selection sheet
      await tester.tap(find.widgetWithText(ElevatedButton, 'Book Fixed Appointment'));
      await tester.pumpAndSettle();

      // Assert chips: 1 Person, 2 People, 3 People, 4 People exist, 5 People does NOT
      expect(find.text('1 Person'), findsOneWidget);
      final twoPeopleFinder = find.text('2 People');
      expect(twoPeopleFinder, findsOneWidget);
      expect(find.text('3 People'), findsOneWidget);
      expect(find.text('4 People'), findsOneWidget);
      expect(find.text('5 People'), findsNothing, reason: 'Max 4 people allowed for now');

      // Scroll to and select '2 People'
      await tester.ensureVisible(twoPeopleFinder);
      await tester.pumpAndSettle();
      await tester.tap(twoPeopleFinder);
      await tester.pumpAndSettle();

      // Scroll down if needed to see Accompanying Persons section
      final sectionTitleFinder = find.text('Accompanying Persons Details (Max 4 Total)');
      await tester.ensureVisible(sectionTitleFinder);
      await tester.pumpAndSettle();
      expect(sectionTitleFinder, findsOneWidget);
      expect(find.textContaining('Single Counter Policy: All accompanying members must attend for this same counter service'), findsOneWidget);
      expect(find.text('Accompanying Person #2'), findsOneWidget);

      // Verify queue slots notice and staggered queue time for accompanying member #2
      expect(find.textContaining('2 queue slots will be allotted for your group'), findsOneWidget);
      expect(find.textContaining('Allotted Queue Time: 09:45 AM – 10:00 AM'), findsOneWidget);

      // Confirm button must be DISABLED because name & reason are missing
      final confirmBtnFinder = find.widgetWithText(ElevatedButton, 'Confirm Appointment • Standard Fee: ₹20');
      expect(confirmBtnFinder, findsOneWidget);
      var confirmBtn = tester.widget<ElevatedButton>(confirmBtnFinder);
      expect(confirmBtn.onPressed, isNull, reason: 'Confirm button must be disabled when accompanying details missing');
      expect(find.text('Please provide full name and select a valid counter reason for all accompanying persons.'), findsOneWidget);

      // Enter name for accompanying person #2
      final nameFieldFinder = find.byKey(const Key('accompanying_name_0'));
      await tester.ensureVisible(nameFieldFinder);
      await tester.pumpAndSettle();
      await tester.enterText(nameFieldFinder, 'Ramesh Patel');
      await tester.pumpAndSettle();

      // Button still disabled because reason is not selected
      confirmBtn = tester.widget<ElevatedButton>(confirmBtnFinder);
      expect(confirmBtn.onPressed, isNull);

      // Select reason: Invalid 'Work at a different counter/department'
      final reasonFieldFinder = find.byKey(const Key('accompanying_reason_0'));
      await tester.ensureVisible(reasonFieldFinder);
      await tester.pumpAndSettle();
      await tester.tap(reasonFieldFinder);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Work at a different counter/department (Separate booking required)').last);
      await tester.pumpAndSettle();

      // Verify error notice displayed and button STILL disabled
      expect(find.textContaining('Not allowed: Accompanying person has work at another counter'), findsAtLeast(1));
      confirmBtn = tester.widget<ElevatedButton>(confirmBtnFinder);
      expect(confirmBtn.onPressed, isNull, reason: 'Must block booking when work is for another counter');

      // Select valid reason: 'Joint Property Owner / Co-applicant for this service'
      await tester.ensureVisible(reasonFieldFinder);
      await tester.pumpAndSettle();
      await tester.tap(reasonFieldFinder);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Joint Property Owner / Co-applicant for this service').last);
      await tester.pumpAndSettle();

      // Button must now be ENABLED
      confirmBtn = tester.widget<ElevatedButton>(confirmBtnFinder);
      expect(confirmBtn.onPressed, isNotNull, reason: 'Confirm button must be enabled once valid name and counter reason provided');

      // Tap Confirm Appointment
      await tester.tap(confirmBtnFinder);
      await tester.pumpAndSettle();

      // Verify confirmation dialog shows individual allotted tokens and times
      expect(find.textContaining('Appointment Confirmed!'), findsOneWidget);
      expect(find.text('2 People'), findsOneWidget);
      expect(find.textContaining('Allotted Tokens & Queue Times'), findsOneWidget);
      expect(find.text('TAX-001'), findsAtLeast(1));
      expect(find.text('TAX-002'), findsOneWidget);
      expect(find.textContaining('Ramesh Patel'), findsOneWidget);
      expect(find.textContaining('09:45 AM – 10:00 AM'), findsAtLeast(1));
    });

    testWidgets('Custom date picker displays 15-day advance booking limit notice', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeClient = FakeApiClient(services: sampleServices);
      await tester.pumpWidget(createTestApp(
        BookScreen(officeId: 'off-1', serviceId: 'srv-1', client: fakeClient),
      ));
      await tester.pumpAndSettle();

      // Check all documents to enable booking button
      await tester.tap(find.byKey(const Key('mandatory_document_checkbox')));
      await tester.pumpAndSettle();
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byKey(Key('doc_checkbox_$i')));
        await tester.pumpAndSettle();
      }

      // Open time selection sheet
      await tester.tap(find.widgetWithText(ElevatedButton, 'Book Fixed Appointment'));
      await tester.pumpAndSettle();

      // Verify the advance booking limit notice is displayed
      expect(find.text('Bookings are allowed up to 15 days in advance'), findsOneWidget);
    });

    testWidgets('Time slots display real-time availability badges and status reasons', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final customSlots = [
        SlotItemModel(
          slotTime: '09:30 AM – 10:30 AM',
          startTime: '09:30:00',
          endTime: '10:30:00',
          available: true,
          status: 'AVAILABLE',
          reasonCode: 'AVAILABLE',
          remainingCapacity: 4,
          bookedCount: 0,
          totalCapacity: 4,
        ),
        SlotItemModel(
          slotTime: '11:30 AM – 12:30 PM',
          startTime: '11:30:00',
          endTime: '12:30:00',
          available: false,
          status: 'TIME_PASSED',
          reasonCode: 'TIME_PASSED',
          remainingCapacity: 4,
          bookedCount: 0,
          totalCapacity: 4,
        ),
        SlotItemModel(
          slotTime: '02:00 PM – 03:00 PM',
          startTime: '14:00:00',
          endTime: '15:00:00',
          available: false,
          status: 'FULLY_BOOKED',
          reasonCode: 'FULLY_BOOKED',
          remainingCapacity: 0,
          bookedCount: 4,
          totalCapacity: 4,
        ),
      ];

      final fakeClient = FakeApiClient(
        services: sampleServices,
        slots: customSlots,
      );

      await tester.pumpWidget(createTestApp(
        BookScreen(officeId: 'off-1', serviceId: 'srv-1', client: fakeClient),
      ));
      await tester.pumpAndSettle();

      // Check all documents to enable booking button
      await tester.tap(find.byKey(const Key('mandatory_document_checkbox')));
      await tester.pumpAndSettle();
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byKey(Key('doc_checkbox_$i')));
        await tester.pumpAndSettle();
      }

      // Open slot selection sheet
      await tester.tap(find.widgetWithText(ElevatedButton, 'Book Fixed Appointment'));
      await tester.pumpAndSettle();

      // Verify availability status badges are displayed
      expect(find.text('Available'), findsAtLeast(1));
      expect(find.text('Time Passed'), findsOneWidget);
      expect(find.text('Fully Booked'), findsOneWidget);

      // Tapping unavailable 'Time Passed' slot shows error message
      final timePassedFinder = find.text('11:30 AM – 12:30 PM');
      await tester.ensureVisible(timePassedFinder);
      await tester.pumpAndSettle();
      await tester.tap(timePassedFinder);
      await tester.pumpAndSettle();
      expect(find.textContaining('Cannot book: this slot time has already passed.'), findsAtLeast(1));

      // Tapping unavailable 'Fully Booked' slot shows error message
      final fullyBookedFinder = find.text('02:00 PM – 03:00 PM');
      await tester.ensureVisible(fullyBookedFinder);
      await tester.pumpAndSettle();
      await tester.tap(fullyBookedFinder);
      await tester.pumpAndSettle();
      expect(find.textContaining('Cannot book: this slot is fully booked.'), findsAtLeast(1));

      // Tapping available slot selects it cleanly
      final availableFinder = find.text('09:30 AM – 10:30 AM');
      await tester.ensureVisible(availableFinder);
      await tester.pumpAndSettle();
      await tester.tap(availableFinder);
      await tester.pumpAndSettle();
      expect(find.textContaining('Confirm Appointment'), findsOneWidget);
    });
  });
}

