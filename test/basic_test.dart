import 'package:flutter/material.dart';
import 'package:flutter_fc/src/fc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets("Stateless", (tester) async {
    final Demo = defineStatelessFC((props) => const Text("A"));
    final key = ObjectKey(Demo);
    await tester.pumpWidget(MaterialApp(home: Demo(key: key)));
    expect(find.byKey(key), findsOneWidget);
  });

  testWidgets("Stateless forwardRef", (tester) async {
    final Demo = forwardRefStateless(
        (props, ref) => Form(key: ref, child: const SizedBox()));
    final ref = GlobalKey<FormState>();
    await tester.pumpWidget(MaterialApp(home: Demo(ref: ref)));
    expect(ref.currentState is FormState, true);
  });

  testWidgets("Stateful", (tester) async {
    final Demo = defineStatelessFC((props) => const Text("A"));
    final key = ObjectKey(Demo);
    await tester.pumpWidget(MaterialApp(home: Demo(key: key)));
    expect(find.byKey(key), findsOneWidget);
  });

  testWidgets("Stateful forwardRef", (tester) async {
    final Demo = defineStatelessFC((props) => const Text("A"));
    final key = ObjectKey(Demo);
    await tester.pumpWidget(MaterialApp(home: Demo(key: key)));
    expect(find.byKey(key), findsOneWidget);
  });
}
