import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smoke test — empty material app builds', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Houseiana'))),
      ),
    );
    expect(find.text('Houseiana'), findsOneWidget);
  });
}
