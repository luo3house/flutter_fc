import 'package:flutter/material.dart';
import 'package:flutter_fc/src/fc.dart';
import 'package:flutter_test/flutter_test.dart';

class _MyFCWidget extends FCWidget {
  final String name;
  const _MyFCWidget(this.name);

  @override
  Widget build() {
    final (text, setText) = useState<String?>(null);
    final greetings = useMemo(() => "Hello $name", [name]);
    useEffect(() {
      if (name == "Dart") setText("Based on Dart 3");
    }, [name]);
    return Text(text ?? greetings);
  }
}

void main() {
  testWidgets("FCWidget shim", (tester) async {
    final name = ValueNotifier("Flutter");
    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder(
          valueListenable: name,
          builder: (_, name, __) => _MyFCWidget(name),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("Hello Flutter"), findsOneWidget);
    name.value = "World";
    await tester.pumpAndSettle();
    expect(find.text("Hello World"), findsOneWidget);
    name.value = "Dart";
    await tester.pumpAndSettle();
    expect(find.text("Based on Dart 3"), findsOneWidget);
  });
}
