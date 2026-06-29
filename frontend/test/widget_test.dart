import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aimusic_app/main.dart';

void main() {
  testWidgets('App splash smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
