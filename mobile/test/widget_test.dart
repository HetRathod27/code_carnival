import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('Citizen App smoke test - language picker appears on first run', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: QueueLessCitizenApp()));
    await tester.pumpAndSettle();

    // Verify QueueLess branding and language options appear
    expect(find.text('QueueLess'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('ગુજરાતી (Gujarati)'), findsOneWidget);
    expect(find.text('हिन्दी (Hindi)'), findsOneWidget);
  });
}
