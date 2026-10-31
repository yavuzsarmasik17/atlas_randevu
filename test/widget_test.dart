
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Ovo Randevu temel test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Ovo Randevu'),
          ),
        ),
      ),
    );

    expect(find.text('OvoRandevu'), findsOneWidget);
  });
}
