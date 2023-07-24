# () => Text("FC in Flutter")

[![Pub Version](https://img.shields.io/pub/v/flutter_fc)](https://pub.dev/packages/flutter_fc)

An easy way to create Functional Components (FC) in Flutter.

*The FC is in development.*

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

## Define a Counter FC

```dart
final Counter = defineFC((props) {
  final (counter, setCounter) = useState(0);
  return ElevatedButton(
    onPressed: () => setCounter(counter + 1),
    child: Text("Counter: $counter"),
  );
});
```

## Lint

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
```

## Acknowledgement

React

Dart 3

## License

MIT (c) 2023-present, Luo3House.
