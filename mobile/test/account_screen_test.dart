import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/account/account_screen.dart';
import 'package:mobile/api/client.dart';
import 'package:mobile/l10n/app_localizations.dart';

class MockAccountApiClient extends ApiClient {
  ProfileModel currentProfile;
  bool updateProfileCalled = false;
  String? updatedName;

  MockAccountApiClient({required this.currentProfile});

  @override
  Future<ProfileModel> getProfile(String token) async {
    return currentProfile;
  }

  @override
  Future<void> updateProfile({
    required String token,
    String? name,
    String? language,
  }) async {
    updateProfileCalled = true;
    updatedName = name;
  }
}

Widget wrapWithTestApp(Widget child) {
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
      'ql_user_name': 'Ramesh Patel',
      'ql_selected_city': 'Gandhinagar',
      'ql_language': 'en',
    });
  });

  testWidgets('AccountScreen renders citizen details and allows editing', (tester) async {
    final mockClient = MockAccountApiClient(
      currentProfile: ProfileModel(
        id: 'CITIZEN-001',
        phone: '+919876543210',
        name: 'Ramesh Patel',
        language: 'en',
        role: 'CITIZEN',
        priorityStrikes: 0,
      ),
    );

    await tester.pumpWidget(wrapWithTestApp(AccountScreen(client: mockClient)));
    await tester.pumpAndSettle();

    // Check title and details
    expect(find.text('My Account'), findsOneWidget);
    expect(find.text('Ramesh Patel'), findsWidgets);
    expect(find.text('+919876543210'), findsWidgets);
    expect(find.text('Gandhinagar'), findsOneWidget);

    // Edit full name
    final nameField = find.widgetWithText(TextField, 'Full Name (Citizen / Beneficiary)');
    expect(nameField, findsOneWidget);

    await tester.enterText(nameField, 'Suresh Patel');
    await tester.pumpAndSettle();

    // Scroll to and tap Save & Update Details
    final saveButton = find.text('Save & Update Details');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Verify client method was called with new name
    expect(mockClient.updateProfileCalled, isTrue);
    expect(mockClient.updatedName, 'Suresh Patel');

    // Verify SharedPreferences updated
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('ql_user_name'), 'Suresh Patel');
  });
}
