import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/history/visit_history_screen.dart';
import 'package:mobile/api/client.dart';
import 'package:mobile/l10n/app_localizations.dart';

class MockHistoryApiClient extends ApiClient {
  final List<TokenModel> historyTokens;

  MockHistoryApiClient(this.historyTokens);

  @override
  Future<List<TokenModel>> getVisitHistory(String authToken) async {
    return historyTokens;
  }
}

Widget wrapApp(Widget child) {
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
      'ql_token': 'test_auth_token',
      'ql_phone': '+919876543210',
    });
  });

  testWidgets('renders visit history cards and summary metrics correctly', (tester) async {
    final List<TokenModel> mockVisits = [
      TokenModel(
        id: 'tok-1',
        officeId: 'off-1',
        serviceId: 'srv-1',
        serviceName: 'Aadhaar Card Update',
        seq: 12,
        state: 'COMPLETED',
        category: 'REGULAR',
        priorityStatus: 'NORMAL',
        createdVia: 'APPOINTMENT',
        waitingAhead: 0,
        displayCode: 'AU-012',
        counterLabel: 'Counter 3',
        businessDate: '2026-10-10',
        calledAt: '2026-10-10T10:05:00Z',
        completedAt: '2026-10-10T10:20:00Z',
        createdAt: '2026-10-10T09:30:00Z',
        citizenRating: 5,
        citizenFeedback: 'Very polite officer and fast turnaround',
        citizenConfirmed: true,
      ),
      TokenModel(
        id: 'tok-2',
        officeId: 'off-1',
        serviceId: 'srv-2',
        serviceName: 'Income Certificate',
        seq: 45,
        state: 'WAITING',
        category: 'REGULAR',
        priorityStatus: 'NORMAL',
        createdVia: 'WALK_IN',
        waitingAhead: 2,
        displayCode: 'IC-045',
        businessDate: '2026-10-10',
        createdAt: '2026-10-10T11:00:00Z',
      ),
    ];

    final client = MockHistoryApiClient(mockVisits);
    await tester.pumpWidget(wrapApp(VisitHistoryScreen(client: client)));
    await tester.pumpAndSettle();

    // Verify Title & Subtitle
    expect(find.text('Visit History'), findsWidgets);
    expect(find.text('AU-012'), findsOneWidget);
    expect(find.text('IC-045'), findsOneWidget);
    expect(find.text('Aadhaar Card Update'), findsOneWidget);
    expect(find.text('Income Certificate'), findsOneWidget);

    // Expand completed visit card to see journey milestones & feedback
    await tester.tap(find.byType(ExpansionTile).first);
    await tester.pumpAndSettle();

    // Verify feedback and rating
    expect(find.textContaining('Very polite officer and fast turnaround'), findsOneWidget);
    expect(find.text('Citizen Confirmed Done'), findsOneWidget);

    // Verify summary stats
    expect(find.text('2'), findsWidgets); // Total visits
    expect(find.text('1'), findsWidgets); // Completed visits

    // Verify filter tabs exist
    expect(find.text('All Visits (2)'), findsOneWidget);
    expect(find.text('Completed (1)'), findsOneWidget);
    expect(find.text('Active / Upcoming (1)'), findsOneWidget);

    // Tap on Completed filter
    await tester.tap(find.text('Completed (1)'));
    await tester.pumpAndSettle();

    expect(find.text('AU-012'), findsOneWidget);
    expect(find.text('IC-045'), findsNothing);
  });

  testWidgets('renders empty state when citizen has no visit history', (tester) async {
    final client = MockHistoryApiClient([]);
    await tester.pumpWidget(wrapApp(VisitHistoryScreen(client: client)));
    await tester.pumpAndSettle();

    expect(find.text('No Previous Visits Found'), findsOneWidget);
    expect(find.text('Book Fixed Appointment'), findsOneWidget);
  });
}
