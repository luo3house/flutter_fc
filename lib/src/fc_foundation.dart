import 'dart:async';

import 'package:flutter/foundation.dart';

import 'fc_core.dart';
import 'fc_lib.dart';

typedef SetStateFunction<T> = Function(T);

(T, SetStateFunction<T>) useState<T>(T init) {
  final ref = useRefMust(init);
  final setState = useSetState();
  return (
    ref.value,
    (newValue) {
      ref.value = newValue;
      setState();
    },
  );
}

ValueNotifier<T> useValue<T>(T Function() factory) {
  final notifier = useMemo(() => ValueNotifier(factory()));
  useDispose(notifier.dispose);
  return notifier;
}

/// Create an object and post a dispose handler for it.
///
/// [ChangeNotifier], [StreamSink] can be automatically disposed.
T useDisposable<T>(T Function() factory,
    {Function(T)? dispose, List deps = const []}) {
  final value = useMemo(factory, deps);
  useDiff(() {
    final onDispose = dispose ?? _defaultDispose;
    return () => onDispose.call(value);
  }, [value]);
  return value;
}

_defaultDispose(dynamic object) {
  var disposed = false;
  if (object is ChangeNotifier) {
    disposed = true;
    object.dispose();
  } else if (object is StreamSink) {
    disposed = true;
    object.close();
  }
  if (disposed) {
    if (kDebugMode) {
      print("dynamic object (${object.runtimeType}) auto-disposed");
    }
  }
}
