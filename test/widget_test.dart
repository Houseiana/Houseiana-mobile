import 'package:flutter_test/flutter_test.dart';
import 'package:houseiana_mobile_app/app.dart';

void main() {
  testWidgets('App builds smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HouseianaApp());
    expect(find.text('Houseiana'), findsOneWidget);
  });
}
