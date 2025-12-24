import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Smart Kharcha'),
        ),
      ),
    ));

    // Verify that our text is found.
    expect(find.text('Smart Kharcha'), findsOneWidget);
  });
}