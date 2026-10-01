import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:padosi_pro/main.dart';

void main() {
  testWidgets('App starts without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: PadosiProApp()),
    );
    // App should start on splash screen
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
