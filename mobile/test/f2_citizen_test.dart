import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/api/client.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/home/home_screen.dart';
import 'package:mobile/l10n/app_localizations.dart';

class FakeHomeApiClient extends ApiClient {
  TokenModel? activeToken;
  bool checkInCalled = false;
  bool onMyWayCalled = false;
  bool cancelCalled = false;

  FakeHomeApiClient({this.activeToken});

  @override
  Future<TokenModel?> getActiveToken(String token) async {
    return activeToken;
  }

  @override
  Future<TokenModel> checkIn({
    required String token,
    required String tokenId,
    required String qrPayload,
  }) async {
    checkInCalled = true;
    activeToken = TokenModel(
      id: activeToken!.id,
      officeId: activeToken!.officeId,
      serviceId: activeToken!.serviceId,
      businessDate: activeToken!.businessDate,
      seq: activeToken!.seq,
      displayCode: activeToken!.displayCode,
      state: activeToken!.state,
      category: activeToken!.category,
      priorityStatus: activeToken!.priorityStatus,
      createdVia: activeToken!.createdVia,
      arrivedAt: '2026-10-05T10:00:00Z',
      lastEtaMinutes: activeToken!.lastEtaMinutes,
      lastEtaReason: activeToken!.lastEtaReason,
      etaLow: activeToken!.etaLow,
      etaHigh: activeToken!.etaHigh,
      waitingAhead: activeToken!.waitingAhead,
      nowServing: activeToken!.nowServing,
    );
    return activeToken!;
  }

  @override
  Future<TokenModel> onMyWay({
    required String token,
    required String tokenId,
  }) async {
    onMyWayCalled = true;
    activeToken = TokenModel(
      id: activeToken!.id,
      officeId: activeToken!.officeId,
      serviceId: activeToken!.serviceId,
      businessDate: activeToken!.businessDate,
      seq: activeToken!.seq,
      displayCode: activeToken!.displayCode,
      state: activeToken!.state,
      category: activeToken!.category,
      priorityStatus: activeToken!.priorityStatus,
      createdVia: activeToken!.createdVia,
      arrivedAt: activeToken!.arrivedAt,
      onMyWayAt: '2026-10-05T10:05:00Z',
      lastEtaMinutes: activeToken!.lastEtaMinutes,
      lastEtaReason: activeToken!.lastEtaReason,
      etaLow: activeToken!.etaLow,
      etaHigh: activeToken!.etaHigh,
      waitingAhead: activeToken!.waitingAhead,
      nowServing: activeToken!.nowServing,
    );
    return activeToken!;
  }

  @override
  Future<TokenModel> cancelToken({
    required String token,
    required String tokenId,
    String? reason,
  }) async {
    cancelCalled = true;
    activeToken = null;
    return TokenModel(
      id: tokenId,
      officeId: 'off-1',
      serviceId: 'srv-1',
      businessDate: '2026-10-05',
      seq: 1,
      displayCode: 'TAX-001',
      state: 'CANCELLED',
      category: 'NORMAL',
      priorityStatus: 'NONE',
      createdVia: 'APP',
      waitingAhead: 0,
    );
  }
}

Widget createTestHomeApp(Widget child) {
  return MaterialApp(
    theme: CivicTheme.lightTheme,
    locale: const Locale('en'),
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

  TokenModel buildSampleToken({
    String? arrivedAt,
    String? onMyWayAt,
  }) {
    return TokenModel(
      id: 'tok-100',
      officeId: 'off-1',
      serviceId: 'srv-1',
      businessDate: '2026-10-05',
      seq: 15,
      displayCode: 'TAX-015',
      state: 'WAITING',
      category: 'NORMAL',
      priorityStatus: 'NONE',
      createdVia: 'APP',
      waitingAhead: 3,
      nowServing: 'TAX-012',
      counterLabel: 'Counter 2',
      lastEtaMinutes: 18.0,
      etaLow: 14.0,
      etaHigh: 22.0,
      lastEtaReason: 'Live adjusted for slow case',
      arrivedAt: arrivedAt,
      onMyWayAt: onMyWayAt,
    );
  }

  group('F2: Citizen App B - Live Token Screen & ETA Details', () {
    testWidgets('HomeScreen renders full active token metrics and ETA range', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeClient = FakeHomeApiClient(activeToken: buildSampleToken());
      await tester.pumpWidget(createTestHomeApp(HomeScreen(client: fakeClient)));
      await tester.pumpAndSettle();

      // Verify token display code & status
      expect(find.text('TAX-015'), findsOneWidget);
      expect(find.text('WAITING'), findsOneWidget);
      expect(find.text('3'), findsOneWidget); // Citizens ahead
      expect(find.text('TAX-012 (Counter 2)'), findsOneWidget); // Now serving

      // Verify ETA p50 and live range
      expect(find.text('~18 minutes'), findsOneWidget);
      expect(find.text('14 – 22 minutes'), findsOneWidget);
      expect(find.text('Live adjusted for slow case'), findsOneWidget);
    });

    testWidgets('Presence check-in updates status to verified', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeClient = FakeHomeApiClient(activeToken: buildSampleToken());
      await tester.pumpWidget(createTestHomeApp(HomeScreen(client: fakeClient)));
      await tester.pumpAndSettle();

      // Check not yet verified
      expect(find.text('Not Yet Checked In'), findsOneWidget);

      // Tap Check-In button
      final checkInBtn = find.byKey(const Key('btn_presence_checkin'));
      expect(checkInBtn, findsOneWidget);
      await tester.tap(checkInBtn);
      await tester.pumpAndSettle();

      // Verify Check-In dialog appears
      expect(find.text('Verify Arrival'), findsOneWidget);
      await tester.tap(find.text('Verify Arrival'));
      await tester.pumpAndSettle();

      // Assert client was called and status changed to verified (both in badge and snackbar)
      expect(fakeClient.checkInCalled, isTrue);
      expect(find.text('Arrival Verified at Centre'), findsNWidgets(2));
    });

    testWidgets('On-My-Way button extends time and becomes disabled once claimed', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeClient = FakeHomeApiClient(activeToken: buildSampleToken());
      await tester.pumpWidget(createTestHomeApp(HomeScreen(client: fakeClient)));
      await tester.pumpAndSettle();

      final omwBtnFinder = find.byKey(const Key('btn_on_my_way'));
      expect(omwBtnFinder, findsOneWidget);

      // Tap On-My-Way
      await tester.tap(omwBtnFinder);
      await tester.pumpAndSettle();

      // Assert API called
      expect(fakeClient.onMyWayCalled, isTrue);
      expect(find.text('Extension Claimed'), findsOneWidget);

      // Verify button is disabled
      final btnWidget = tester.widget<OutlinedButton>(omwBtnFinder);
      expect(btnWidget.onPressed, isNull);
    });

    testWidgets('Cancel button prompts for confirmation and clears active appointment', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final fakeClient = FakeHomeApiClient(activeToken: buildSampleToken());
      await tester.pumpWidget(createTestHomeApp(HomeScreen(client: fakeClient)));
      await tester.pumpAndSettle();

      // Tap Cancel button
      final cancelBtn = find.byKey(const Key('btn_cancel_appointment'));
      expect(cancelBtn, findsOneWidget);
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      // Confirmation dialog appears
      expect(find.text('Are you sure you want to cancel this appointment?'), findsOneWidget);
      await tester.tap(find.text('Yes, Cancel'));
      await tester.pumpAndSettle();

      // Assert client was called and HomeScreen returned to empty state
      expect(fakeClient.cancelCalled, isTrue);
      expect(find.text('No Active Appointment'), findsOneWidget);
    });

    testWidgets('Serving state does not show On-My-Way or Cancel buttons', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final servingToken = TokenModel(
        id: 'tok-200',
        officeId: 'off-1',
        serviceId: 'srv-1',
        businessDate: '2026-10-05',
        seq: 15,
        displayCode: 'TAX-015',
        state: 'SERVING',
        category: 'NORMAL',
        priorityStatus: 'NONE',
        createdVia: 'APP',
        waitingAhead: 0,
        nowServing: 'TAX-015',
        counterLabel: 'Counter 2',
        arrivedAt: '2026-10-05T10:00:00Z',
      );

      final fakeClient = FakeHomeApiClient(activeToken: servingToken);
      await tester.pumpWidget(createTestHomeApp(HomeScreen(client: fakeClient)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn_on_my_way')), findsNothing);
      expect(find.byKey(const Key('btn_cancel_appointment')), findsNothing);
    });
  });
}
