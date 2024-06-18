import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_fc/flutter_fc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fc/src/fc_compat_v0.dart';

void main() {
  testWidgets("useState", (tester) async {
    final Demo = forwardRef((context, props, ref) {
      final (counter, setCounter) = useState(0);
      return GestureDetector(
        key: ref,
        onTap: () => setCounter(counter + 1),
        child: Text(counter.toString()),
      );
    });
    final ref = ObjectKey(Demo);
    await tester.pumpWidget(MaterialApp(home: Demo(ref: ref)));
    expect(find.text("0"), findsOneWidget);
    // tap 3 times
    await Future.forEach(
      List.generate(3, (_) => 0),
      (_) async {
        await tester.tap(find.byKey(ref));
        await tester.pumpAndSettle();
      },
    );
    expect(find.text("3"), findsOneWidget);
  });

  testWidgets("useMemo", (tester) async {
    final numValue = ValueNotifier(0);
    final Demo = defineFC((context, int? value) {
      value ??= 0;
      final text = useMemo(() => (value! * 2).toString(), [value]);
      return Text(text);
    });

    await tester.pumpWidget(MaterialApp(
      home: ValueListenableBuilder(
        valueListenable: numValue,
        builder: (_, numValue, __) => Demo(props: numValue),
      ),
    ));
    expect(find.text("0"), findsOneWidget);

    numValue.value++;
    await tester.pumpAndSettle();
    expect(find.text("2"), findsOneWidget);

    numValue.value++;
    await tester.pumpAndSettle();
    expect(find.text("4"), findsOneWidget);

    numValue.value++;
    await tester.pumpAndSettle();
    expect(find.text("6"), findsOneWidget);
  });

  testWidgets("useRef", (tester) async {
    final Demo = forwardRef((context, props, ref) {
      final textControllerRef = useRefMust(0);
      final (_, setState) = useState(0);
      update() => setState(Random().nextInt(100) + 1000);
      return GestureDetector(
        key: ref,
        onTap: () {
          textControllerRef.value++;
          update();
        },
        child: Text(textControllerRef.value.toString()),
      );
    });
    final ref = ObjectKey(Demo);

    await tester.pumpWidget(MaterialApp(home: Demo(ref: ref)));
    await tester.tap(find.byKey(ref));
    await tester.pumpAndSettle();
    expect(find.text("1"), findsOneWidget);

    await tester.tap(find.byKey(ref));
    await tester.pumpAndSettle();
    expect(find.text("2"), findsOneWidget);
  });
}
