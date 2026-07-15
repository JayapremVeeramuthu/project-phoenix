import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_phoenix_customer/main.dart';

void main() {
  testWidgets('ProjectPhoenixApp builds and starts successfully',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ProjectPhoenixApp(),
      ),
    );
    await tester.pump(); // Let GoRouter pump the initial frame

    // Verify that the splash screen is shown by checking for 'PROJECT PHOENIX'
    expect(find.text('PROJECT PHOENIX'), findsOneWidget);

    // Let the splash screen initialization finish so timers are cleaned up
    await tester.pump(const Duration(seconds: 3));
  });
}
