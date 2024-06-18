import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_fc/flutter_fc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fc/src/fc_compat_v0.dart';

void main() async {
  testWidgets("defineFC", (tester) async {
    final Demo = defineFC((context, props) => const Text("A"));
    final key = ObjectKey(Demo);
    await tester.pumpWidget(MaterialApp(home: Demo(key: key)));
    expect(find.byKey(key), findsOneWidget);
  });

  testWidgets("forwardRef", (tester) async {
    final Demo = defineFC((context, props) => const Text("A"));
    final key = ObjectKey(Demo);
    await tester.pumpWidget(MaterialApp(home: Demo(key: key)));
    expect(find.byKey(key), findsOneWidget);
  });

  testWidgets("useEffect", (tester) async {
    final effectSignals = <bool>[];
    final show = ValueNotifier(false);
    final numValue = ValueNotifier(0);
    final Demo = forwardRef((context, int? props, ref) {
      useEffect(() {
        effectSignals.add(true);
        return () => effectSignals.add(false);
      }, [props]);
      return const SizedBox();
    });
    await tester.pumpWidget(MaterialApp(
      home: ValueListenableBuilder(
        valueListenable: show,
        builder: (_, show, __) => show
            ? ValueListenableBuilder(
                valueListenable: numValue,
                builder: (_, numValue, __) => Demo(props: numValue))
            : const SizedBox(),
      ),
    ));
    // create & dispose
    show.value = true;
    await tester.pumpAndSettle();
    show.value = false;
    await tester.pumpAndSettle();
    expect(effectSignals, [true, false]);
    effectSignals.clear();

    // create & update
    show.value = true;
    await tester.pumpAndSettle();
    numValue.value = 1;
    await tester.pumpAndSettle();
    expect(effectSignals, [true, false, true]);
  });

  testWidgets("useEffect no deps", (tester) async {
    final effectSignals = <bool>[];
    final numValue = ValueNotifier(0);
    final Demo = forwardRef((context, int? props, ref) {
      useEffect(() {
        effectSignals.add(true);
        return () => effectSignals.add(false);
      });
      return const SizedBox();
    });
    await tester.pumpWidget(MaterialApp(
      home: ValueListenableBuilder(
        valueListenable: numValue,
        builder: (_, numValue, __) => Demo(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(effectSignals, [true]);
    numValue.value++;
    await tester.pumpAndSettle();
    expect(effectSignals, [true, false, true]);
    numValue.value++;
    await tester.pumpAndSettle();
    expect(effectSignals, [true, false, true, false, true]);
  });

  testWidgets("useBuildContext", (tester) async {
    final fontSize = Random().nextInt(20) + 10.0;
    final Demo = defineFC((context, props) {
      final context = useBuildContext();
      expect(DefaultTextStyle.of(context).style.fontSize, fontSize);
      return const SizedBox();
    });

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DefaultTextStyle(
          style: TextStyle(fontSize: fontSize),
          child: Demo(),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  });

  testWidgets("useImperativeHandle", (tester) async {
    final stringSignals = <void>[];
    final Child = defineFC((context, Ref<Function?>? ref) {
      assert(ref != null);
      useImperativeHandle(ref!, () {
        return () => stringSignals.add(null);
      });
      return const SizedBox();
    });
    final Parent = defineFC((context, props) {
      final ref = useRef<Function()?>();
      useEffect(() {
        ref.value?.call();
        return () {};
      });
      return Child(props: ref);
    });

    final numValue = ValueNotifier(0);
    await tester.pumpWidget(MaterialApp(
      home: ValueListenableBuilder(
        valueListenable: numValue,
        builder: (_, __, ___) => Parent(),
      ),
    ));

    await tester.pumpAndSettle();
    expect(stringSignals.length, 1);

    numValue.value++;
    await tester.pumpAndSettle();
    expect(stringSignals.length, 2);
  });
}
