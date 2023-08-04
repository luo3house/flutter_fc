# () => Text("FC in Flutter")

[![Pub Version](https://img.shields.io/pub/v/flutter_fc)](https://pub.dev/packages/flutter_fc)
[![Github Action](https://github.com/luo3house/flutter_fc/actions/workflows/test.yaml/badge.svg)](https://github.com/luo3house/flutter_fc/actions/workflows/test.yaml)

An easy way to create Functional Components (FC) in Flutter, with composable hooks.

*The FC is in development.*

## Features

- ⏱️ No code generation
- 🖨️ No classes verbosing
- 📄 Tiny implementations
- 🧭 Function oriented
- 🪝 With powerful composable hooks
- 🐇 Speed up developing
- 🧱 Hot reload

## Install

For destructing records type. Dart 3 or greater version is required.

```yaml
# ensure dart version >= 3
environment:
  sdk: '^3.0.0'

dependencies:
  flutter_fc: <latest version>
```

## Equip Powerful Hooks

Currently supports these hooks as following:

- useState
- useEffect
- useMemo
- useRef
- useImperativeHandle
- useBuildContext

## Quick Example: Define a Counter FC

```dart
final Counter = defineFC((props) {
  final (counter, setCounter) = useState(0);
  return ElevatedButton(
    onPressed: () => setCounter(counter + 1),
    child: Text("Counter: $counter"),
  );
});

void main() {
  runApp(MaterialApp(home: Counter()));
}
```

## Development Tips

### Hot Reload

Dynamic closures are not reassembled during hot reload.

```dart
// CounterFC will NOT schedule a rebuild after a hot reload.
final Counter = defineFC((props) {
  final (counter, setCounter) = useState(0);
  return ElevatedButton(
    onPressed: () => setCounter(counter + 1),
      child: Text("Counter: $counter"),
  );
});
```

To apply hot reload, split the function as a constant field.

```dart
// After moving outside, widget editied within function will be applied during hot reload.
_Counter(props) {
  final (counter, setCounter) = useState(0);
  return ElevatedButton(
    onPressed: () => setCounter(counter + 1),
      child: Text("Counter: $counter"),
  );
}
final Counter = defineFC(_Counter);
```

### Ignore Naming Warnings

To avoid IDE lint warnings, include FC preset.

```yaml
# analysis_options.yaml
include: package:flutter_fc/lints.yaml
```

or configure manually.

```yaml
linter:
  rules:
    non_constant_identifier_names: false
    body_might_complete_normally_nullable: false
```

## Acknowledgement

React

Dart 3

## License

MIT (c) 2023-present, Luo3House.
