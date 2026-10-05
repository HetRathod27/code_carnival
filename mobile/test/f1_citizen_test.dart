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

  FakeApiClient({
    this.offices = const [],
    this.services = const [],
    this.tokenToReturn,
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
  Future<TokenModel> bookToken({
    required String token,
    required String officeId,
    required String serviceId,
    required String category,
    required String phone,
    String? beneficiaryName,
    String? priorityDocType,
    int travelMinutes = 0,
    required String idempotencyKey,
  }) async {
    if (tokenToReturn != null) return tokenToReturn!;
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

      // Tap the mandatory confirmation checkbox
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      // Assert button is now ENABLED
      final enabledButton = tester.widget<ElevatedButton>(bookButtonFinder);
      expect(enabledButton.onPressed, isNotNull, reason: 'Book button must be enabled once documents confirmed');
    });

    testWidgets('Priority category selection switches mode and shows proof notice', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeClient = FakeApiClient(services: sampleServices);
      await tester.pumpWidget(createTestApp(
        BookScreen(officeId: 'off-1', serviceId: 'srv-1', client: fakeClient),
      ));
      await tester.pumpAndSettle();

      // Verify priority chip is available
      final priorityChip = find.text('Priority Access');
      expect(priorityChip, findsOneWidget);

      // Tap Priority chip
      await tester.tap(priorityChip);
      await tester.pumpAndSettle();

      // Verify notice and eligibility dropdown appears
      expect(find.textContaining('Reserved for senior citizens'), findsOneWidget);
      expect(find.text('Senior Citizen (60+ years)'), findsOneWidget);
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
  });
}
