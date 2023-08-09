import 'package:flutter/material.dart';
import 'package:flutter_fc/flutter_fc.dart';

Widget _Counter(props) {
  final (counter, setCounter) = useState(0);
  return ElevatedButton(
    onPressed: () => setCounter(counter + 1),
    child: Text("Counter: $counter"),
  );
}

final Counter = defineFC(_Counter);

var flag = 0;

// reproduction: reload, reload again, should clean up hooks and perform "useMemo" rebuild
Widget _ErrTest(props) {
  flag++;
  final value = flag > 1 ? useMemo(() => 1, []) : useRef(0).current;
  return Text("$value");
}

final ErrTest = defineFC(_ErrTest);

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      body: SafeArea(
        child: Column(children: [
          Counter(),
          ErrTest(),
        ]),
      ),
    ),
  ));
}
