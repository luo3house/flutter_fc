// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_fc/flutter_fc.dart';
import 'package:flutter_fc/flutter_fc_experimental.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fc/src/fc_compat_v0.dart';

void main() {
  testWidgets("setState in useEffect", (tester) async {
    final Demo = defineFC((context, props) {
      final (counter, setCounter) = useState(0);
      useEffect(() {
        setCounter(1);
        return () {};
      }, []);
      return Text(counter.toString());
    });

    await tester.pumpWidget(MaterialApp(home: Demo()));
    await tester.pumpAndSettle();
    expect(find.text("1"), findsOneWidget);
  });

  testWidgets("setState in useImperativeHandle", (tester) async {
    final Child = defineFC((context, Ref? ref) {
      assert(ref != null);
      final (counter, setCounter) = useState(0);
      useImperativeHandle(ref!, () {
        setCounter(1); // delayed
        return counter;
      });
      return Text(counter.toString());
    });

    final Parent = defineFC((context, props) {
      final ref = useRef(0);
      useEffect(() {
        expect(ref.value, 0);
        return () {};
      });
      return Child(props: ref);
    });

    await tester.pumpWidget(MaterialApp(home: Parent()));
    await tester.pumpAndSettle();
  });
}
