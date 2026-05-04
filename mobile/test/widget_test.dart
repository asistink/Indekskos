import 'package:flutter_test/flutter_test.dart';
import 'package:indekskos_mobile/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const IndekskosApp());
    expect(find.text('Indekskos'), findsOneWidget);
  });
}
