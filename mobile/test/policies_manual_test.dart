import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/api/client.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/policies/policies_screen.dart';
import 'package:mobile/features/policies/policy_content_model.dart';
import 'package:mobile/features/account/account_screen.dart';
import 'package:mobile/features/book/book_screen.dart';

class FakePoliciesApiClient extends ApiClient {
  final ProfileModel? profile;
  final List<ServiceModel> services;

  FakePoliciesApiClient({
    this.profile,
    this.services = const [],
  });

  @override
  Future<ProfileModel> getProfile(String token) async {
    return profile ??
        ProfileModel(
          id: 'CITIZEN-001',
          phone: '+919876543210',
          name: 'Priya Sharma',
          language: 'en',
          role: 'CITIZEN',
          priorityStrikes: 0,
        );
  }

  @override
  Future<List<ServiceModel>> fetchServices(String officeId) async {
    return services;
  }
}

Widget createTestApp(Widget child, {Locale locale = const Locale('en'), double textScale = 1.0}) {
  return MaterialApp(
    theme: CivicTheme.lightTheme,
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: MediaQuery(
      data: MediaQueryData(
        size: const Size(800, 1400),
        textScaler: TextScaler.linear(textScale),
      ),
      child: child,
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'ql_token': 'fake_token',
      'ql_phone': '+919876543210',
      'ql_user_name': 'Priya Sharma',
      'ql_selected_city': 'Gandhinagar',
      'ql_language': 'en',
    });
  });

  group('Help & Rules Manual Tests', () {
    test('Parity check: All policy keys exist in EN, GU, and HI arb files', () {
      final enFile = File('lib/l10n/app_en.arb');
      final guFile = File('lib/l10n/app_gu.arb');
      final hiFile = File('lib/l10n/app_hi.arb');

      expect(enFile.existsSync(), isTrue);
      expect(guFile.existsSync(), isTrue);
      expect(hiFile.existsSync(), isTrue);

      final enJson = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
      final guJson = jsonDecode(guFile.readAsStringSync()) as Map<String, dynamic>;
      final hiJson = jsonDecode(hiFile.readAsStringSync()) as Map<String, dynamic>;

      // Check category keys
      for (final cat in policyCategories) {
        expect(enJson.containsKey(cat.titleKey), isTrue, reason: 'Missing EN key ${cat.titleKey}');
        expect(guJson.containsKey(cat.titleKey), isTrue, reason: 'Missing GU key ${cat.titleKey}');
        expect(hiJson.containsKey(cat.titleKey), isTrue, reason: 'Missing HI key ${cat.titleKey}');

        for (final sec in cat.sections) {
          expect(enJson.containsKey(sec.titleKey), isTrue, reason: 'Missing EN title key ${sec.titleKey}');
          expect(guJson.containsKey(sec.titleKey), isTrue, reason: 'Missing GU title key ${sec.titleKey}');
          expect(hiJson.containsKey(sec.titleKey), isTrue, reason: 'Missing HI title key ${sec.titleKey}');

          for (final bodyKey in sec.bodyKeys) {
            expect(enJson.containsKey(bodyKey), isTrue, reason: 'Missing EN body key $bodyKey');
            expect(guJson.containsKey(bodyKey), isTrue, reason: 'Missing GU body key $bodyKey');
            expect(hiJson.containsKey(bodyKey), isTrue, reason: 'Missing HI body key $bodyKey');
          }
        }
      }

      // Check Important Notice keys
      expect(enJson.containsKey('importantCivicNoticeTitle'), isTrue);
      expect(guJson.containsKey('importantCivicNoticeTitle'), isTrue);
      expect(hiJson.containsKey('importantCivicNoticeTitle'), isTrue);

      expect(enJson.containsKey('importantCivicNoticeBody'), isTrue);
      expect(guJson.containsKey('importantCivicNoticeBody'), isTrue);
      expect(hiJson.containsKey('importantCivicNoticeBody'), isTrue);
    });

    testWidgets('PoliciesScreen displays Help & Rules header, 4 categories, and Important Notice', (tester) async {
      await tester.pumpWidget(createTestApp(const PoliciesScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Help & Rules'), findsWidgets);
      expect(find.text('Important information about appointments, arrival, cancellation and service.'), findsOneWidget);
      expect(find.text('1. Booking Rules'), findsOneWidget);
      expect(find.text('2. Arrival & Service Delivery'), findsOneWidget);
      expect(find.text('3. Problems & What To Do'), findsOneWidget);
      expect(find.text('4. Special Categories & System Rules'), findsOneWidget);

      expect(find.text('Important Notice'), findsOneWidget);
      expect(find.textContaining('QueueLess helps manage appointments and queues'), findsOneWidget);
      expect(find.text('QueueLess Appointment & Service Policies'), findsOneWidget);
      expect(find.text('Official Civic System v1.1.0 • Gujarat e-Gov'), findsOneWidget);
    });

    testWidgets('PoliciesScreen accordion expand and collapse works with accessibility semantics', (tester) async {
      await tester.pumpWidget(createTestApp(const PoliciesScreen()));
      await tester.pumpAndSettle();

      // Find the first section title
      final firstTitle = find.text('How QueueLess Appointments Work');
      expect(firstTitle, findsOneWidget);

      // Verify body text is NOT yet visible
      expect(find.textContaining('To schedule a civic service: Select your city'), findsNothing);

      // Verify semantics initially collapsed
      expect(
        tester.getSemantics(find.byType(PolicyAccordionCard).first).hint,
        contains('Tap to view rules'),
      );

      // Tap to expand
      await tester.tap(firstTitle);
      await tester.pumpAndSettle();

      // Verify body text is NOW visible and semantics updated to expanded
      expect(find.textContaining('To schedule a civic service: Select your city'), findsOneWidget);
      expect(find.textContaining('QueueLess appointments use fixed time slots'), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(PolicyAccordionCard).first).hint,
        contains('Tap to collapse'),
      );

      // Tap to collapse
      await tester.tap(firstTitle);
      await tester.pumpAndSettle();

      // Verify body text collapsed
      expect(find.textContaining('To schedule a civic service: Select your city'), findsNothing);
    });

    testWidgets('PoliciesScreen back navigation works', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: CivicTheme.lightTheme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PoliciesScreen()),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(PoliciesScreen), findsOneWidget);

      // Tap back button in AppBar
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(PoliciesScreen), findsNothing);
      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('Entry point 1: AccountScreen has Help & Rules and opens PoliciesScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeClient = FakePoliciesApiClient();
      await tester.pumpWidget(createTestApp(AccountScreen(client: fakeClient)));
      await tester.pumpAndSettle();

      // Verify Help & Rules button is present in AccountScreen
      final policiesButtonFinder = find.text('Help & Rules');
      expect(policiesButtonFinder, findsOneWidget);

      await tester.ensureVisible(policiesButtonFinder);
      await tester.pumpAndSettle();

      // Tap the button
      await tester.tap(policiesButtonFinder);
      await tester.pumpAndSettle();

      // Verify PoliciesScreen is opened
      expect(find.byType(PoliciesScreen), findsOneWidget);
      expect(find.text('1. Booking Rules'), findsOneWidget);
    });

    testWidgets('Entry point 2: BookScreen has View appointment & cancellation rules and opens PoliciesScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeService = ServiceModel(
        id: 'srv-1',
        officeId: 'off-1',
        code: 'TAX',
        names: {'en': 'Property Tax', 'gu': 'મિલકત વેરો', 'hi': 'संपत्ति कर'},
        priorAvgMinutes: 10,
        requiredDocs: [
          {'name_en': 'Identity Proof', 'name_gu': 'ઓળખનો પુરાવો', 'name_hi': 'पहचान प्रमाण'}
        ],
        priorityAllowed: false,
        requiresPhysicalVisit: true,
      );

      final fakeClient = FakePoliciesApiClient(services: [fakeService]);
      await tester.pumpWidget(createTestApp(
        BookScreen(officeId: 'off-1', serviceId: 'srv-1', client: fakeClient),
      ));
      await tester.pumpAndSettle();

      // Verify secondary link exists
      final linkFinder = find.text('View appointment & cancellation rules');
      expect(linkFinder, findsOneWidget);

      await tester.ensureVisible(linkFinder);
      await tester.pumpAndSettle();

      // Tap secondary link
      await tester.tap(linkFinder);
      await tester.pumpAndSettle();

      // Verify same PoliciesScreen opens
      expect(find.byType(PoliciesScreen), findsOneWidget);
      expect(find.text('1. Booking Rules'), findsOneWidget);
    });

    testWidgets('Multilingual rendering works in Gujarati (GU)', (tester) async {
      await tester.pumpWidget(createTestApp(const PoliciesScreen(), locale: const Locale('gu')));
      await tester.pumpAndSettle();

      expect(find.text('મદદ અને નિયમો'), findsWidgets);
      expect(find.text('૧. મુલાકાત બુકિંગના નિયમો'), findsOneWidget);
      expect(find.text('૨. આગમન અને સેવા વિતરણ'), findsOneWidget);
      expect(find.text('૩. સમસ્યાઓ અને ઉપાયો'), findsOneWidget);
      expect(find.text('૪. ખાસ કેટેગરી અને સિસ્ટમ નિયમો'), findsOneWidget);

      // Expand a section in Gujarati
      final guTitle = find.text('QueueLess અપોઇન્ટમેન્ટ કેવી રીતે કાર્ય કરે છે');
      expect(guTitle, findsOneWidget);
      await tester.tap(guTitle);
      await tester.pumpAndSettle();

      expect(find.textContaining('નાગરિક સેવા શેડ્યૂલ કરવા: તમારું શહેર પસંદ કરો'), findsOneWidget);
      expect(find.text('મહત્વપૂર્ણ સૂચના'), findsOneWidget);
    });

    testWidgets('Multilingual rendering works in Hindi (HI)', (tester) async {
      await tester.pumpWidget(createTestApp(const PoliciesScreen(), locale: const Locale('hi')));
      await tester.pumpAndSettle();

      expect(find.text('सहायता और नियम'), findsWidgets);
      expect(find.text('1. अपॉइंटमेंट बुकिंग नियम'), findsOneWidget);
      expect(find.text('2. आगमन और सेवा वितरण'), findsOneWidget);
      expect(find.text('3. समस्याएं और समाधान'), findsOneWidget);
      expect(find.text('4. विशेष श्रेणियां और प्रणाली नियम'), findsOneWidget);

      // Expand a section in Hindi
      final hiTitle = find.text('QueueLess अपॉइंटमेंट कैसे कार्य करता है');
      expect(hiTitle, findsOneWidget);
      await tester.tap(hiTitle);
      await tester.pumpAndSettle();

      expect(find.textContaining('नागरिक सेवा निर्धारित करने के लिए: अपना शहर चुनें'), findsOneWidget);
      expect(find.text('महत्वपूर्ण सूचना'), findsOneWidget);
    });

    testWidgets('Large text scale (1.8x) does not overflow or crash in GU/HI', (tester) async {
      await tester.pumpWidget(createTestApp(
        const PoliciesScreen(),
        locale: const Locale('gu'),
        textScale: 1.8,
      ));
      await tester.pumpAndSettle();

      // Expand first card
      final titleFinder = find.text('QueueLess અપોઇન્ટમેન્ટ કેવી રીતે કાર્ય કરે છે');
      await tester.tap(titleFinder);
      await tester.pumpAndSettle();

      // Should not throw layout exception
      expect(tester.takeException(), isNull);
    });
  });
}
