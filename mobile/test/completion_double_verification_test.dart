import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/home/home_screen.dart';
import 'package:mobile/api/client.dart';
import 'package:mobile/l10n/app_localizations.dart';

class MockCompletionApiClient extends ApiClient {
  final TokenModel token;
  bool confirmCompletionCalled = false;
  bool? reportedCompleted;
  String? reportedReason;
  int? reportedRating;

  MockCompletionApiClient(this.token);

  @override
  Future<TokenModel?> getActiveToken(String authToken) async {
    return token;
  }

  @override
  Future<void> confirmCompletion({
    required String token,
    required String tokenId,
    required bool serviceCompleted,
    String? reasonIfNot,
    required int rating,
    String? feedbackText,
  }) async {
    confirmCompletionCalled = true;
    reportedCompleted = serviceCompleted;
    reportedReason = reasonIfNot;
    reportedRating = rating;
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
      'ql_token': 'test_token',
      'ql_phone': '+919876543210',
    });
  });

  testWidgets('Double-verification view renders on COMPLETED token and submits feedback', (tester) async {
    final completedToken = TokenModel(
      id: 'tok-done-1',
      officeId: 'ward-central-01',
      serviceId: 'srv-1',
      businessDate: '2026-10-07',
      seq: 14,
      displayCode: 'TAX-014',
      state: 'COMPLETED',
      category: 'NORMAL',
      priorityStatus: 'NONE',
      createdVia: 'APP',
      counterLabel: 'Counter 1',
      waitingAhead: 0,
    );

    final mockClient = MockCompletionApiClient(completedToken);

    await tester.pumpWidget(wrapApp(HomeScreen(client: mockClient)));
    await tester.pumpAndSettle();

    // Verify double-verification UI elements
    expect(find.text('Service Completed at Counter'), findsOneWidget);
    expect(find.text('Was your service completed successfully?'), findsOneWidget);
    expect(find.text('Yes / હા'), findsOneWidget);
    expect(find.text('No / ના'), findsOneWidget);

    // Tap "No / ના"
    await tester.tap(find.text('No / ના'));
    await tester.pumpAndSettle();

    // Reason explanation field must appear
    expect(find.text('Why was the service not completed?'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Server error at counter');
    await tester.pumpAndSettle();

    // Change rating to 4 stars
    final starButtons = find.byType(IconButton);
    if (starButtons.evaluate().length >= 4) {
      await tester.ensureVisible(starButtons.at(3));
      await tester.tap(starButtons.at(3));
      await tester.pumpAndSettle();
    }

    // Submit verification
    final submitBtn = find.text('Submit & Return to Civic Centres');
    expect(submitBtn, findsOneWidget);
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    // Assert that client was called with correct verification data
    expect(mockClient.confirmCompletionCalled, isTrue);
    expect(mockClient.reportedCompleted, isFalse);
    expect(mockClient.reportedReason, equals('Server error at counter'));
  });
}
