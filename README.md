# () => Text("FC in Flutter")

[![Pub Version](https://img.shields.io/pub/v/flutter_fc)](https://pub.dev/packages/flutter_fc)
[![Github Action](https://github.com/luo3house/flutter_fc/actions/workflows/test.yaml/badge.svg)](https://github.com/luo3house/flutter_fc/actions/workflows/test.yaml)

An easy way to create Functional Components (FC) in Flutter, with composable hooks.

*The FC has been deployed in some production app builds. FC aims to save your time.*

## Features

- ⏱️ No need to generate codes
- 🖨️ No need to verbose StateXXXWidget & State\<XXX> classes
- 📄 Tiny implementations without external deps
- 🪝 Built-in powerful composable hooks
- 🐇 Speed up developing
- 🎯 Focus on performance optimization
- 🧱 Hot reload
- ⚛️ React style friendly

## Install

```yaml
dependencies:
  flutter_fc: ^1.0.0
```

## Quick Start

No need to create a StatefulWidget class and a State for it.

```dart
class Counter extends FCWidget {
  const Counter({super.key});

  @override
  Widget build(BuildContext context) {
    final (counter, setCounter) = useState(0);
    return ElevatedButton(
      onPressed: () => setCounter(counter + 1),
        child: Text("Counter: $counter"),
    );
  }
}
```

Dynamically create a temporary widget type, Not recommended.

```dart
final Counter = defineFC((context, props) {
  final (counter, setCounter) = useState(0);
  return ElevatedButton(
    onPressed: () => setCounter(counter + 1),
      child: Text("Counter: $counter"),
  );
});
```

## Using hooks

### useState

Create or restore with initial value stored in element, and get a function to let it update and rebuild.

```dart
final (loading, setLoading) = useState(false);
```

`useSetState` instead in case of just want to trigger an rebuild.

```dart
final update = useSetState();

update(); // trigger an rebuild
```

### useIsMounted

Return a function, call to get whether element is mounted.

```dart
final isMounted = useIsMounted();

Timer(const Duration(seconds: 3), () {
  if (isMounted()) {
    // element is still present
  }
});
```

### useElement

Retrieve current building element. It inherits `BuildContext` so...

```dart
final context = useElement();
final theme = Theme.of(context);
final navigator = Navigator.of(context);
```


### useDidChangeDependencies

Post a callback, called on element's dependencies were changed.

### useReassemble

Post a callback, called on element receives reassemble directive.

```dart
useReassemble(() => textController.clear());
```

### useDispose

Post a callback, called before element unmounts.

```dart
final timer = useMemo(() => Timer(...));
useDispose(timer.cancel);
```

### useDiff

Post a callback, called on dependencies are different from before.

```dart
final (flag, setFlag) = useState(false);
useDiff(() {
  print("Flag is changed to: $flag");

  // DO NOT TRIGGER UPDATE HERE setFlag(false);
}, [flag]);
```

### useMemo

Give a factory to create value, get the same object on each build until dependencies were changed.

```dart
final (percent, setPercent) = useState(20);
final prettierPercent = useMemo(() => "${percent} %", [percent]);
```

### useRef

Create or restore with initial value stored in a `Ref`, which holds the value only.

```dart
final timerRef = useRef<Timer>(); // nullable

final flagRef = useRefMust(false); // not null
```

### useValue

Create or restore with initial value stored in an `ValueNotifier`, which update listeners on its value has changed.

```dart
final loading = useValue(() => false);

setLoading(bool newValue) => loading.value = newValue;

return ValueListenableBuilder(
  valueListenable: loading,
  builder: (context, flag, child) => flag
    ? const Text("Loading") 
    : const SizedBox(),
);
```

### useDisposable

Create or restore a disposable instance. It may be called with `.disposed()` if it inherits from `ChangeNotifier` or `StreamSink`,

Commonly used descendant classes:
- ChangeNotifier
- ValueNotifier
- StreamController
- FocusNode
- TextEditingController

```dart
// auto disposed on unmount
final controller = useDisposable(() => TextEditingController());
```


## Acknowledgement

React

Dart 3

## License

MIT (c) 2023-present, Luo3House.
