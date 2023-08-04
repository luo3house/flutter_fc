import 'package:flutter/material.dart';
import 'package:flutter_fc/src/fc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets("defineFC", (tester) async {
    final Demo = defineFC((props) => const Text("A"));
    final key = ObjectKey(Demo);
    await tester.pumpWidget(MaterialApp(home: Demo(key: key)));
    expect(find.byKey(key), findsOneWidget);
  });

  testWidgets("forwardRef", (tester) async {
    final Demo = defineFC((props) => const Text("A"));
    final key = ObjectKey(Demo);
    await tester.pumpWidget(MaterialApp(home: Demo(key: key)));
    expect(find.byKey(key), findsOneWidget);
  });
}
