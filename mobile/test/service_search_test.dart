import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/browse/offices_screen.dart';
import 'package:mobile/api/client.dart';
import 'package:mobile/l10n/app_localizations.dart';

class MockOfficesWithServicesClient extends ApiClient {
  final List<OfficeModel> sampleOffices;
  final Map<String, List<ServiceModel>> sampleServices;

  MockOfficesWithServicesClient(this.sampleOffices, this.sampleServices);

  @override
  Future<List<OfficeModel>> fetchOffices() async => sampleOffices;

  @override
  Future<List<ServiceModel>> fetchServices(String officeId) async {
    return sampleServices[officeId] ?? [];
  }
}

Widget wrapWithTestApp(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    theme: CivicTheme.lightTheme,
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

void main() {
  late List<OfficeModel> gandhinagarOffices;
  late Map<String, List<ServiceModel>> officeServicesMap;
  late MockOfficesWithServicesClient mockClient;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'ql_selected_city': 'Gandhinagar',
    });

    gandhinagarOffices = [
      OfficeModel(
        id: 'ward-central-01',
        name: 'Central Municipal Civic Centre (Sector 11)',
        address: 'Sector 11, Gandhinagar - 382011',
        timezone: 'Asia/Kolkata',
        openTime: '09:00',
        closeTime: '18:00',
      ),
      OfficeModel(
        id: 'gmc-sector-21',
        name: 'Sector 21 Jan Seva Kendra',
        address: 'Sector 21, Gandhinagar - 382021',
        timezone: 'Asia/Kolkata',
        openTime: '09:00',
        closeTime: '18:00',
      ),
      OfficeModel(
        id: 'gmc-kudasan',
        name: 'Kudasan Civic Facilitation Centre',
        address: 'Kudasan, Gandhinagar - 382421',
        timezone: 'Asia/Kolkata',
        openTime: '09:00',
        closeTime: '18:00',
      ),
      OfficeModel(
        id: 'amc-bodakdev',
        name: 'Bodakdev Civic Centre',
        address: 'Bodakdev, Ahmedabad - 380054',
        timezone: 'Asia/Kolkata',
        openTime: '09:00',
        closeTime: '18:00',
      ),
    ];

    officeServicesMap = {
      'ward-central-01': [
        ServiceModel(
          id: 'srv-bc',
          officeId: 'ward-central-01',
          code: 'BC',
          names: {
            'en': 'Birth & Death Certificate',
            'gu': 'જન્મ અને મરણ પ્રમાણપત્ર',
            'hi': 'जन्म और मृत्यु प्रमाण पत्र',
          },
          priorAvgMinutes: 10,
          requiredDocs: [],
          priorityAllowed: true,
          requiresPhysicalVisit: true,
        ),
        ServiceModel(
          id: 'srv-pt',
          officeId: 'ward-central-01',
          code: 'PT',
          names: {
            'en': 'Property Tax Assessment',
            'gu': 'મિલકત વેરો આકારણી',
            'hi': 'संपत्ति कर निर्धारण',
          },
          priorAvgMinutes: 15,
          requiredDocs: [],
          priorityAllowed: true,
          requiresPhysicalVisit: true,
        ),
      ],
      'gmc-sector-21': [
        ServiceModel(
          id: 'srv-pt-21',
          officeId: 'gmc-sector-21',
          code: 'PT',
          names: {
            'en': 'Property Tax Assessment',
            'gu': 'મિલકત વેરો આકારણી',
            'hi': 'संपत्ति कर निर्धारण',
          },
          priorAvgMinutes: 12,
          requiredDocs: [],
          priorityAllowed: true,
          requiresPhysicalVisit: true,
        ),
        ServiceModel(
          id: 'srv-trade',
          officeId: 'gmc-sector-21',
          code: 'TRADE',
          names: {
            'en': 'Trade License & Shop Registration',
            'gu': 'વેપાર પરવાનો અને દુકાન નોંધણી',
            'hi': 'व्यापार लाइसेंस और दुकान पंजीकरण',
          },
          priorAvgMinutes: 20,
          requiredDocs: [],
          priorityAllowed: true,
          requiresPhysicalVisit: true,
        ),
      ],
      'gmc-kudasan': [
        ServiceModel(
          id: 'srv-bc-kudasan',
          officeId: 'gmc-kudasan',
          code: 'BC',
          names: {
            'en': 'Birth & Death Certificate',
            'gu': 'જન્મ અને મરણ પ્રમાણપત્ર',
            'hi': 'जन्म और मृत्यु प्रमाण पत्र',
          },
          priorAvgMinutes: 8,
          requiredDocs: [],
          priorityAllowed: true,
          requiresPhysicalVisit: true,
        ),
      ],
      'amc-bodakdev': [
        ServiceModel(
          id: 'srv-pt-ahmedabad',
          officeId: 'amc-bodakdev',
          code: 'PT',
          names: {
            'en': 'Property Tax Assessment',
            'gu': 'મિલકત વેરો આકારણી',
            'hi': 'संपत्ति कर निर्धारण',
          },
          priorAvgMinutes: 15,
          requiredDocs: [],
          priorityAllowed: true,
          requiresPhysicalVisit: true,
        ),
      ],
    };

    mockClient = MockOfficesWithServicesClient(gandhinagarOffices, officeServicesMap);
  });

  testWidgets('Search field is displayed in top bar and normal browsing works when search is empty', (tester) async {
    await tester.pumpWidget(wrapWithTestApp(OfficesScreen(client: mockClient)));
    await tester.pumpAndSettle();

    // Verify Title & Top bar elements
    expect(find.text('Gandhinagar Civic Centres'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.account_circle_outlined), findsOneWidget);

    // Default state: all 3 Gandhinagar centres visible
    expect(find.text('Central Municipal Civic Centre (Sector 11)'), findsOneWidget);
    expect(find.text('Sector 21 Jan Seva Kendra'), findsOneWidget);
    expect(find.text('Kudasan Civic Facilitation Centre'), findsOneWidget);
    expect(find.text('Bodakdev Civic Centre'), findsNothing); // Ahmedabad centre filtered out
    expect(find.text('3 Centres'), findsOneWidget);
  });

  testWidgets('Search for exact service name filters matching civic centres and displays count & indicator', (tester) async {
    await tester.pumpWidget(wrapWithTestApp(OfficesScreen(client: mockClient)));
    await tester.pumpAndSettle();

    // Enter search query "Property Tax Assessment"
    await tester.enterText(find.byType(TextField), 'Property Tax Assessment');
    await tester.pumpAndSettle();

    // Should match Central Municipal Civic Centre and Sector 21 Jan Seva Kendra (2 centres)
    expect(find.text('Central Municipal Civic Centre (Sector 11)'), findsOneWidget);
    expect(find.text('Sector 21 Jan Seva Kendra'), findsOneWidget);
    expect(find.text('Kudasan Civic Facilitation Centre'), findsNothing); // Kudasan does not offer Property Tax

    // Result count banner
    expect(find.text('2 centres offer this service'), findsOneWidget);
    expect(find.text('2 Centres'), findsOneWidget);

    // Availability indicator on cards
    expect(find.text('→ Property Tax Assessment available'), findsNWidgets(2));
  });

  testWidgets('Partial matching, case-insensitivity, and trimming work seamlessly', (tester) async {
    await tester.pumpWidget(wrapWithTestApp(OfficesScreen(client: mockClient)));
    await tester.pumpAndSettle();

    // Search with leading/trailing spaces and mixed case: "   tRaDe   "
    await tester.enterText(find.byType(TextField), '   tRaDe   ');
    await tester.pumpAndSettle();

    // Only Sector 21 Jan Seva Kendra offers Trade License
    expect(find.text('Sector 21 Jan Seva Kendra'), findsOneWidget);
    expect(find.text('Central Municipal Civic Centre (Sector 11)'), findsNothing);
    expect(find.text('Kudasan Civic Facilitation Centre'), findsNothing);

    // Singular count message
    expect(find.text('1 centre offers this service'), findsOneWidget);
    expect(find.text('1 Centres'), findsOneWidget);
    expect(find.text('→ Trade License & Shop Registration available'), findsOneWidget);
  });

  testWidgets('Search for unavailable service displays empty state and clear button restores list', (tester) async {
    await tester.pumpWidget(wrapWithTestApp(OfficesScreen(client: mockClient)));
    await tester.pumpAndSettle();

    // Search for a service not available in Gandhinagar
    await tester.enterText(find.byType(TextField), 'Passport Verification');
    await tester.pumpAndSettle();

    // Empty state should display without clear search button
    expect(find.text('No civic centre in this city offers this service.'), findsOneWidget);
    expect(find.byIcon(Icons.search_off), findsOneWidget);
    expect(find.text('0 centres offer this service'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Clear Search'), findsNothing);

    // Clear search using the suffix clear icon in the search field
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();

    // Restores complete list
    expect(find.text('Central Municipal Civic Centre (Sector 11)'), findsOneWidget);
    expect(find.text('Sector 21 Jan Seva Kendra'), findsOneWidget);
    expect(find.text('Kudasan Civic Facilitation Centre'), findsOneWidget);
    expect(find.text('3 Centres'), findsOneWidget);
  });

  testWidgets('Clear button in search TextField clears input and restores list', (tester) async {
    await tester.pumpWidget(wrapWithTestApp(OfficesScreen(client: mockClient)));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Birth');
    await tester.pumpAndSettle();

    expect(find.text('2 centres offer this service'), findsOneWidget);

    // Tap clear button in TextField suffix
    final clearBtn = find.byIcon(Icons.clear);
    expect(clearBtn, findsOneWidget);
    await tester.tap(clearBtn);
    await tester.pumpAndSettle();

    // Search query is cleared and all 3 centres restored
    expect(find.text('3 Centres'), findsOneWidget);
    expect(find.text('Central Municipal Civic Centre (Sector 11)'), findsOneWidget);
    expect(find.text('Sector 21 Jan Seva Kendra'), findsOneWidget);
    expect(find.text('Kudasan Civic Facilitation Centre'), findsOneWidget);
  });

  testWidgets('Multilingual search works in Gujarati and Hindi', (tester) async {
    // 1. Gujarati test
    await tester.pumpWidget(wrapWithTestApp(OfficesScreen(client: mockClient), locale: const Locale('gu')));
    await tester.pumpAndSettle();

    // Search for "મિલકત" (Property)
    await tester.enterText(find.byType(TextField), 'મિલકત');
    await tester.pumpAndSettle();

    expect(find.text('Central Municipal Civic Centre (Sector 11)'), findsOneWidget);
    expect(find.text('Sector 21 Jan Seva Kendra'), findsOneWidget);
    expect(find.text('Kudasan Civic Facilitation Centre'), findsNothing);
    expect(find.text('→ મિલકત વેરો આકારણી ઉપલબ્ધ'), findsNWidgets(2));

    // 2. Hindi test
    await tester.pumpWidget(wrapWithTestApp(OfficesScreen(client: mockClient), locale: const Locale('hi')));
    await tester.pumpAndSettle();

    // Search for "जन्म" (Birth)
    await tester.enterText(find.byType(TextField), 'जन्म');
    await tester.pumpAndSettle();

    expect(find.text('Central Municipal Civic Centre (Sector 11)'), findsOneWidget);
    expect(find.text('Kudasan Civic Facilitation Centre'), findsOneWidget);
    expect(find.text('Sector 21 Jan Seva Kendra'), findsNothing);
    expect(find.text('→ जन्म और मृत्यु प्रमाण पत्र उपलब्ध'), findsNWidgets(2));
  });

  testWidgets('Search never bleeds into other cities and operates strictly in selected city', (tester) async {
    await tester.pumpWidget(wrapWithTestApp(OfficesScreen(client: mockClient)));
    await tester.pumpAndSettle();

    // Search "Property" in Gandhinagar
    await tester.enterText(find.byType(TextField), 'Property');
    await tester.pumpAndSettle();

    // Bodakdev in Ahmedabad also offers Property Tax, but must NEVER be shown because city is Gandhinagar
    expect(find.text('Bodakdev Civic Centre'), findsNothing);
  });
}
