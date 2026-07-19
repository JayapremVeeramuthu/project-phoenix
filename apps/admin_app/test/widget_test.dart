import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_phoenix_admin/main.dart';

void main() {
  testWidgets('Admin App smoke test - shows login screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: AdminApp(),
      ),
    );

    // Verify that the login screen header text is present
    expect(find.text('Phoenix Admin Portal'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
