// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:flutter_fc/flutter_fc.dart';

class BasicSwitchTest extends StatelessWidget {
  static final BasicSwitch = defineFC(
    (bool? propsSW) {
      final (sw, setSW) = useState(false);
      useEffect(() {
        if (propsSW != null) setSW(propsSW);
        return () {};
      }, [propsSW]);

      return Row(mainAxisSize: MainAxisSize.min, children: [
        Switch(value: sw, onChanged: (_) => setSW(!sw)),
        const SizedBox(width: 5),
        Text(sw ? "On" : 'Off'),
      ]);
    },
  );

  static final controlled = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("Uncontrolled"),
        BasicSwitch(),
        const Text("Controlled"),
        ValueListenableBuilder(
          valueListenable: controlled,
          builder: (_, sw, __) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(value: sw, onChanged: (_) => controlled.value = !sw),
              const Text("Toggle Checkbox"),
              BasicSwitch(sw),
            ],
          ),
        ),
      ],
    );
  }
}

final Counter = defineFC((props) {
  final (counter, setCounter) = useState(0);
  return ElevatedButton(
    onPressed: () => setCounter(counter + 1),
    child: Text("Counter: $counter"),
  );
});

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      body: Column(children: [
        BasicSwitchTest(),
        const SizedBox(height: 10),
        Counter(),
      ]),
    ),
  ));
}
