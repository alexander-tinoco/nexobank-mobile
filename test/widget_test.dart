import 'package:flutter_test/flutter_test.dart';
import 'package:nexobank_mobile/main.dart';

void main() {
  testWidgets('NexoBankApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NexoBankApp());
    expect(find.text('NexoBank'), findsOneWidget);
  });
}
