import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/api/client.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/browse/services_screen.dart';
import 'package:mobile/l10n/app_localizations.dart';

class MockCounterStatusApiClient extends ApiClient {
  List<ServiceModel> services;

  MockCounterStatusApiClient(this.services);

  @override
  Future<List<ServiceModel>> fetchServices(String officeId) async {
    return services;
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
  final sampleOffice = OfficeModel(
    id: 'ward-central-01',
    name: 'Central Municipal Civic Centre',
    address: 'Sector 11, Gandhinagar',
    timezone: 'Asia/Kolkata',
    openTime: '09:00',
    closeTime: '18:00',
  );

  testWidgets('OPEN counter shows Book Fixed Appointment button and is active', (tester) async {
    final client = MockCounterStatusApiClient([
      ServiceModel(
        id: 'srv-bc',
        officeId: 'ward-central-01',
        code: 'BC',
        names: {'en': 'Birth & Death Certificate', 'gu': 'જન્મ અને મરણ પ્રમાણપત્ર', 'hi': 'जन्म और मृत्यु प्रमाण पत्र'},
        priorAvgMinutes: 8.0,
        requiredDocs: [],
        priorityAllowed: true,
        requiresPhysicalVisit: true,
        counterStatus: 'OPEN',
      ),
    ]);

    await tester.pumpWidget(wrapWithTestApp(
      ServicesScreen(officeId: sampleOffice.id, client: client),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Birth & Death Certificate'), findsOneWidget);
    expect(find.text('Book Fixed Appointment'), findsOneWidget);
    expect(find.text('Counter Closed'), findsNothing);
    expect(find.text('Counter On Break'), findsNothing);
  });

  testWidgets('CLOSED counter shows Counter Closed badge and notice, disables booking', (tester) async {
    final client = MockCounterStatusApiClient([
      ServiceModel(
        id: 'srv-bc',
        officeId: 'ward-central-01',
        code: 'BC',
        names: {'en': 'Birth & Death Certificate', 'gu': 'જન્મ અને મરણ પ્રમાણપત્ર', 'hi': 'जन्म અને મરણ પ્રમાણપત્ર'},
        priorAvgMinutes: 8.0,
        requiredDocs: [],
        priorityAllowed: true,
        requiresPhysicalVisit: true,
        counterStatus: 'CLOSED',
      ),
    ]);

    await tester.pumpWidget(wrapWithTestApp(
      ServicesScreen(officeId: sampleOffice.id, client: client),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Birth & Death Certificate'), findsOneWidget);
    expect(find.text('Book Fixed Appointment'), findsNothing);
    expect(find.text('Counter Closed'), findsOneWidget);
    expect(
      find.text('Appointments are temporarily unavailable because the counter is closed.'),
      findsOneWidget,
    );
  });

  testWidgets('BREAK counter shows Counter On Break badge and notice, disables booking', (tester) async {
    final client = MockCounterStatusApiClient([
      ServiceModel(
        id: 'srv-bc',
        officeId: 'ward-central-01',
        code: 'BC',
        names: {'en': 'Birth & Death Certificate', 'gu': 'જન્મ અને મરણ પ્રમાણપત્ર', 'hi': 'जन्म और मृत्यु प्रमाण पत्र'},
        priorAvgMinutes: 8.0,
        requiredDocs: [],
        priorityAllowed: true,
        requiresPhysicalVisit: true,
        counterStatus: 'BREAK',
      ),
    ]);

    await tester.pumpWidget(wrapWithTestApp(
      ServicesScreen(officeId: sampleOffice.id, client: client),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Birth & Death Certificate'), findsOneWidget);
    expect(find.text('Book Fixed Appointment'), findsNothing);
    expect(find.text('Counter On Break'), findsOneWidget);
    expect(
      find.text('Appointments are temporarily unavailable while the counter is on break.'),
      findsOneWidget,
    );
  });

  testWidgets('Gujarati and Hindi localization render correct status badges and notices', (tester) async {
    final client = MockCounterStatusApiClient([
      ServiceModel(
        id: 'srv-bc',
        officeId: 'ward-central-01',
        code: 'BC',
        names: {'en': 'Birth Certificate', 'gu': 'જન્મ પ્રમાણપત્ર', 'hi': 'जन्म प्रमाण पत्र'},
        priorAvgMinutes: 8.0,
        requiredDocs: [],
        priorityAllowed: true,
        requiresPhysicalVisit: true,
        counterStatus: 'CLOSED',
      ),
    ]);

    // Test Gujarati (gu)
    await tester.pumpWidget(wrapWithTestApp(
      ServicesScreen(officeId: sampleOffice.id, client: client),
      locale: const Locale('gu'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('કાઉન્ટર બંધ છે'), findsOneWidget);
    expect(find.text('કાઉન્ટર બંધ હોવાથી મુલાકાતો હાલ પૂરતી ઉપલબ્ધ નથી.'), findsOneWidget);

    // Test Hindi (hi) with BREAK
    client.services = [
      ServiceModel(
        id: 'srv-bc',
        officeId: 'ward-central-01',
        code: 'BC',
        names: {'en': 'Birth Certificate', 'gu': 'જન્મ પ્રમાણપત્ર', 'hi': 'जन्म प्रमाण पत्र'},
        priorAvgMinutes: 8.0,
        requiredDocs: [],
        priorityAllowed: true,
        requiresPhysicalVisit: true,
        counterStatus: 'BREAK',
      ),
    ];

    await tester.pumpWidget(wrapWithTestApp(
      ServicesScreen(
        key: const ValueKey('hi_screen'),
        officeId: sampleOffice.id,
        client: client,
      ),
      locale: const Locale('hi'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('काउंटर ब्रेक पर है'), findsOneWidget);
    expect(find.text('काउंटर ब्रेक पर होने के कारण अपॉइंटमेंट अस्थायी रूप से अनुपलब्ध हैं।'), findsOneWidget);
  });

  testWidgets('Multiple counters: dynamic refresh reflects status changes', (tester) async {
    final client = MockCounterStatusApiClient([
      ServiceModel(
        id: 'srv-bc',
        officeId: 'ward-central-01',
        code: 'BC',
        names: {'en': 'Birth & Death Certificate'},
        priorAvgMinutes: 8.0,
        requiredDocs: [],
        priorityAllowed: true,
        requiresPhysicalVisit: true,
        counterStatus: 'OPEN',
      ),
    ]);

    await tester.pumpWidget(wrapWithTestApp(
      ServicesScreen(officeId: sampleOffice.id, client: client),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Book Fixed Appointment'), findsOneWidget);

    // Officer closes counter, citizen refreshes
    client.services = [
      ServiceModel(
        id: 'srv-bc',
        officeId: 'ward-central-01',
        code: 'BC',
        names: {'en': 'Birth & Death Certificate'},
        priorAvgMinutes: 8.0,
        requiredDocs: [],
        priorityAllowed: true,
        requiresPhysicalVisit: true,
        counterStatus: 'CLOSED',
      ),
    ];

    // Tap refresh icon button
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();

    expect(find.text('Counter Closed'), findsOneWidget);
    expect(find.text('Book Fixed Appointment'), findsNothing);
  });
}
