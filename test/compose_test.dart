import 'package:flutter/material.dart';
import 'package:flutter_fc/src/fc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets("setState in useEffect", (tester) async {
    final Demo = defineFC((props) {
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
    final Child = defineFC((FCRef? ref) {
      assert(ref != null);
      final (counter, setCounter) = useState(0);
      useImperativeHandle(ref!, () {
        setCounter(1); // delayed
        return counter;
      });
      return Text(counter.toString());
    });

    final Parent = defineFC((props) {
      final ref = useRef(0);
      useEffect(() {
        expect(ref.current, 0);
        return () {};
      });
      return Child(props: ref);
    });

    await tester.pumpWidget(MaterialApp(home: Parent()));
    await tester.pumpAndSettle();
  });
}
