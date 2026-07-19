import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_phoenix_technician/main.dart';

void main() {
  testWidgets('Technician App smoke test - shows login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: TechnicianApp()));
    expect(find.text('Project Phoenix'), findsOneWidget);
  });
}
