part of 'fc.dart';

/// Class level widget to support a `const` midified Function Component.
/// Hooks are available during `build()`
///
/// ```dart
/// class MyFCWidget extends FCWidget {
///   final String name;
///
///   @override
///   build() {
///     final greetings = useMemo(() => "Hello $name", [name]);
///     return Text(greetings);
///   }
/// }
/// ```
abstract class FCWidget extends Widget implements _FCWidget {
  const FCWidget({super.key});

  @override
  Element createElement() {
    return _FCElement(this);
  }
}
