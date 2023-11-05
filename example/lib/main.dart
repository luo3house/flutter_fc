import 'package:flutter/material.dart';
import 'package:flutter_fc/flutter_fc.dart';

void main() {
  runApp(const MaterialApp(
    home: SafeArea(
      child: SkipErrorAfterReassembleTestScreen(),
    ),
  ));
}

class CounterScreen extends FCWidget {
  const CounterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // sdk 2.x interop
    // final (counter, setCounter) = useState(0);
    final state = useState(0);
    final counter = state.$1, setCounter = state.$2;

    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => setCounter(counter + 1),
          child: Text("Counter: $counter"),
        ),
      ),
    );
  }
}

/// cause error on tap
class ErrorTestScreen extends FCWidget {
  static var flag = 0;

  const ErrorTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    flag++;
    final value = flag > 1 ? useMemo(() => 1, []) : useRef(0).current;
    final tuple = useState(const Object());
    final update = tuple.$2;
    return GestureDetector(
      onTap: () => update(Object()),
      child: Text("$value"),
    );
  }
}

/// value memoized with no deps, should be re-derived after reassemble
class SkipErrorAfterReassembleTestScreen extends FCWidget {
  const SkipErrorAfterReassembleTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = useMemo(() => DateTime.now(), const []);
    return Scaffold(
      body: Column(
        children: [
          Text("$now"),
          DangerousFC(),
        ],
      ),
    );
  }
}

class DangerousFC extends FCWidget {
  static var flag = 0;
  @override
  Widget build(BuildContext context) {
    flag++;
    final rs = flag % 2 == 0 ? useMemo(() => 1, const []) : useRef(2).current;
    return Text("$rs%");
  }
}

/// ```jsx
/// const Child = () => {
///   const fn = useContext(ParentContext);
///   useEffect(() => fn(), []);
///   return <></>;
/// };
/// const Parent = () => {
///   const [c, setC] = useState(0);
///   return (
///     <ParentContext.Provider value={() => setC(c + 1)}>
///       <Child />
///       <div>c = {c}</div>
///     </ParentContext.Provider>
///   );
/// };
/// ```
class OverlayHierScreen extends FCWidget {
  static final Child = defineFC((Function()? callParent) {
    useEffect(() => callParent?.call());
    return const SizedBox();
  });

  const OverlayHierScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // sdk 2.x interop
    // final (counter, setCounter) = useState(0);
    final state = useState(0);
    final counter = state.$1, setCounter = state.$2;

    return Overlay(
      initialEntries: [
        OverlayEntry(
          builder: (_) => Scaffold(
            body: Stack(children: [
              Child(props: () => setCounter(counter + 1)),
              Text("counter = $counter"),
            ]),
          ),
        ),
      ],
    );
  }
}
