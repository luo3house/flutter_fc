# () => Text("FC in Flutter")

[![Pub Version](https://img.shields.io/pub/v/flutter_fc)](https://pub.dev/packages/flutter_fc)
[![Github Action](https://github.com/luo3house/flutter_fc/actions/workflows/test.yaml/badge.svg)](https://github.com/luo3house/flutter_fc/actions/workflows/test.yaml)

An easy way to create Functional Components (FC) in Flutter, with composable hooks.

*The FC is in development.*

## Features

- ⏱️ Never wait code generation
- 🖨️ Never verbosing State***Widget classes
- 📄 Tiny implementations
- 🪝 With powerful composable hooks
- 🐇 Speed up developing
- 🧱 Hot reload
- ⚛️ React style friendly

![About 50% shrink](./image/fc.jpg)

## Install

For destructuring records type. Dart 3 or greater version is required.

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

### Define Props

Destructuring records & named records have been supported since Dart 3.

```dart
// dectructure named records instead of verbosing props class.
Widget _MyWidget(({int value, bool? enabled})? props) {
  assert(props != null);
  final (:value, enabled: propsEnabled) = props!;
  final enabled = useMemo(() => propsEnabled ?? false, [propsEnabled]);
  return const SizedBox();
}
final MyWidget = defineFC(_MyWidget);

// Use
MyWidget(props: (
  value: 10,
  enabled: false,
));
```

### Hot Reload

Dynamic closures are not reassembled during hot reload.To apply hot reload, move the function out of scope.

```dart
// [NO] Define from closure.
final Counter = defineFC((props) {
  final (counter, setCounter) = useState(0);
  return ElevatedButton(
    onPressed: () => setCounter(counter + 1),
      child: Text("Counter: $counter"),
  );
});

// [OK] Define from const function
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
analyzer:
  errors:
    body_might_complete_normally_nullable: ignore

linter:
  rules:
    non_constant_identifier_names: false
```

## Acknowledgement

React

Dart 3

If this library saves your time, please give a star ⭐️, love from luo<3house.

## License

MIT (c) 2023-present, Luo3House.
