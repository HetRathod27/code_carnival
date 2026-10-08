import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/theme.dart';
import 'package:mobile/features/browse/city_selection_screen.dart';
import 'package:mobile/features/browse/offices_screen.dart';
import 'package:mobile/api/client.dart';
import 'package:mobile/l10n/app_localizations.dart';

class MockOfficesClient extends ApiClient {
  final List<OfficeModel> sampleOffices;
  MockOfficesClient(this.sampleOffices);

  @override
  Future<List<OfficeModel>> fetchOffices() async {
    return sampleOffices;
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
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('CitySelectionScreen renders Gujarat cities and search filter works', (tester) async {
    await tester.pumpWidget(wrapWithTestApp(const CitySelectionScreen(allowBack: false)));
    await tester.pumpAndSettle();

    // Verify header and primary cities are present
    expect(find.text('Select City / શહેર પસંદ કરો'), findsOneWidget);
    expect(find.text('Gandhinagar'), findsOneWidget);
    expect(find.text('Ahmedabad'), findsOneWidget);
    expect(find.text('Surat'), findsOneWidget);

    // Filter by search query
    await tester.enterText(find.byType(TextField), 'Gandhi');
    await tester.pumpAndSettle();

    expect(find.text('Gandhinagar'), findsOneWidget);
    expect(find.text('Ahmedabad'), findsNothing);
    expect(find.text('Surat'), findsNothing);
  });

  testWidgets('Selecting a city saves to SharedPreferences and OfficesScreen filters by city', (tester) async {
    // 1. Select Gandhinagar
    await tester.pumpWidget(wrapWithTestApp(const CitySelectionScreen(allowBack: false)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gandhinagar'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('ql_selected_city'), equals('Gandhinagar'));

    // 2. Open OfficesScreen with Gandhinagar and Ahmedabad centres
    final mockList = [
      OfficeModel(
        id: 'gmc-1',
        name: 'Sector 21 Jan Seva Kendra',
        address: 'Shopping Centre, Sector 21, Gandhinagar - 382021',
        timezone: 'Asia/Kolkata',
        openTime: '09:00',
        closeTime: '17:00',
      ),
      OfficeModel(
        id: 'amc-1',
        name: 'Bodakdev Civic Centre',
        address: 'Judges Bungalow Road, Bodakdev, Ahmedabad - 380054',
        timezone: 'Asia/Kolkata',
        openTime: '09:00',
        closeTime: '17:00',
      ),
    ];

    await tester.pumpWidget(wrapWithTestApp(OfficesScreen(client: MockOfficesClient(mockList))));
    await tester.pumpAndSettle();

    // Gandhinagar centre should be visible, Ahmedabad centre filtered out
    expect(find.text('Sector 21 Jan Seva Kendra'), findsOneWidget);
    expect(find.text('Bodakdev Civic Centre'), findsNothing);
    expect(find.text('Gandhinagar'), findsOneWidget);
    expect(find.text('1 Centres'), findsOneWidget);
  });
}
