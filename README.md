# () => Text("FC in Flutter")

An easy way to create Functional Components (FC) in Flutter.

*The FC is in development.*

## Install

```yaml
dependencies:
  flutter_fc: <latest version>
```

## Lint

To avoid variable namings from linter, include FC preset.

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

## Acknowledgement

React

## License

MIT (c) 2023-present, Luo3House.
