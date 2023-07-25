import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_fc/src/fc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets("useState", (tester) async {
    final Demo = forwardRef((props, ref) {
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

  testWidgets("useEffect", (tester) async {
    final effectSignals = <bool>[];
    final show = ValueNotifier(false);
    final numValue = ValueNotifier(0);
    final Demo = forwardRef((int? props, ref) {
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
    final Demo = forwardRef((int? props, ref) {
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

  testWidgets("useMemo", (tester) async {
    final numValue = ValueNotifier(0);
    final Demo = defineFC((int? value) {
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
    final Demo = forwardRef((props, ref) {
      final textControllerRef = useRef(0);
      final (_, setState) = useState(0);
      update() => setState(Random().nextInt(100) + 1000);
      return GestureDetector(
        key: ref,
        onTap: () {
          textControllerRef.current++;
          update();
        },
        child: Text(textControllerRef.current.toString()),
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

  testWidgets("useBuildContext", (tester) async {
    final con = BoxConstraints.loose(const Size(100, 200));
    final Demo = defineFC((props) {
      final context = useBuildContext();
      useEffect(() {
        expect((context.findRenderObject() as RenderBox).constraints, con);
        return () {};
      });
      return const SizedBox();
    });

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ConstrainedBox(
          constraints: con,
          child: Demo(),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  });
}
