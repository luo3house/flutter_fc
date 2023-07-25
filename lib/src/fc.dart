import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'utils.dart';

typedef FC<Props> = Widget Function(Props? props);
typedef ForwardRefFC<Props> = Widget Function(Props? props, Key? ref);
typedef MemoizedFC<Props> = Widget Function({Props? props, Key? ref, Key? key});

const _effectFlagUpdate = 1 << 7;

var _kFCIndex = 0;
_FCDispatcher? _kCurrentDispatcher;
int _nextFCId() => ++_kFCIndex;

abstract class _FCDispatcher {
  final List<Hook> memoizedHooks = [];
  (T, Function(T value)) useState<T>(T init);
  T useMemo<T>(T Function() factory, List? deps);
  useEffect(Function()? Function() effectFn, List? deps);
  BuildContext useBuildContext();
  FCRef<T> useRef<T>(T init);
}

class Hook {
  final String name;
  final int effectFlag;
  Function()? Function()? create;
  Function()? dispose;
  List? deps;
  dynamic value;
  bool effectStale = false;
  Hook(this.name, [this.effectFlag = 0]);
}

class _FcMountDispatcher extends _FCDispatcher {
  final _FCStatefulWidgetState state;
  _FcMountDispatcher(this.state);

  @override
  useEffect(Function()? Function() effectFn, List? deps) {
    final hook = Hook("useEffect", _effectFlagUpdate);
    memoizedHooks.add(hook
      ..deps = deps
      ..create = effectFn
      ..effectStale = true);
  }

  @override
  T useMemo<T>(T Function() factory, List? deps) {
    final value = factory();
    memoizedHooks.add(Hook("useMemo")
      ..deps = deps
      ..value = value);
    return value;
  }

  @override
  FCRef<T> useRef<T>(T init) {
    final ref = FCRef<T>(init);
    memoizedHooks.add(Hook("useRef")..value = ref);
    return ref;
  }

  @override
  (T, Function(T value)) useState<T>(T init) {
    final hook = Hook("useState");
    final value = init;
    memoizedHooks.add(hook..value = value);
    return (
      value,
      (T value) {
        if (hook.value == value) return;
        hook.value = value;
        state.requestSetState();
      }
    );
  }

  @override
  BuildContext useBuildContext() {
    return state.context;
  }
}

class _FcUpdateDispatcher extends _FCDispatcher {
  final _FCStatefulWidgetState state;
  var hookIndex = 0;
  _FcUpdateDispatcher(this.state) {
    memoizedHooks.addAll(state.hooks ?? []);
  }

  Hook retrieveHook(String name) {
    assert(memoizedHooks.length >= hookIndex + 1,
        "should have at least ${hookIndex + 1} hooks but got ${memoizedHooks.length}");
    final hook = memoizedHooks[hookIndex];
    if (hook.name != name) {
      assert(false, "expected Hook($name) but got Hook(${hook.name})");
    }
    hookIndex++;
    return hook;
  }

  @override
  useEffect(Function()? Function() effectFn, List? deps) {
    final hook = retrieveHook("useEffect");
    if (hook.deps == null || deps == null) {
      hook.effectStale = true;
    } else {
      hook.effectStale = !ListUtil.shallowEq(hook.deps ?? const [], deps);
    }
    memoizedHooks.add(hook
      ..deps = deps
      ..create = effectFn);
  }

  @override
  T useMemo<T>(T Function() factory, List? deps) {
    final hook = retrieveHook("useMemo");
    if (!ListUtil.shallowEq(hook.deps ?? const [], deps ?? const [])) {
      hook
        ..deps = deps
        ..value = factory();
    }
    memoizedHooks.add(hook);
    return hook.value;
  }

  @override
  FCRef<T> useRef<T>(T init) {
    final hook = retrieveHook("useRef");
    memoizedHooks.add(hook);
    return hook.value as FCRef<T>;
  }

  @override
  (T, Function(T value)) useState<T>(T init) {
    final hook = retrieveHook("useState");
    memoizedHooks.add(hook);
    return (
      hook.value,
      (T value) {
        if (hook.value == value) return;
        hook.value = value;
        state.requestSetState();
      }
    );
  }

  @override
  BuildContext useBuildContext() {
    return state.context;
  }
}

mixin _FCWidget<Props> on Widget {
  String get name;
  ForwardRefFC<Props> get builder;
  Props? get props;
  Key? get ref;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    if (props is FCProps) {
      return (props as FCProps).debugFillProperties(properties);
    }
    super.debugFillProperties(properties);
  }

  @override
  Type get runtimeType => FCType("${super.runtimeType.toString()}\$name");
}

class _FCStatelessWidget<Props> extends StatelessWidget with _FCWidget<Props> {
  @override
  final String name;
  @override
  final ForwardRefFC<Props> builder;
  @override
  final Props? props;
  @override
  final Key? ref;

  _FCStatelessWidget(this.builder, this.props, this.ref, this.name,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return builder(props, ref);
  }
}

class _FCStatefulWidget<Props> extends StatefulWidget with _FCWidget<Props> {
  @override
  final String name;
  @override
  final ForwardRefFC<Props> builder;
  @override
  final Props? props;
  @override
  final Key? ref;

  _FCStatefulWidget(this.builder, this.props, this.ref, this.name, {super.key});

  @override
  State<StatefulWidget> createState() {
    return _FCStatefulWidgetState<Props>();
  }
}

class _FCStatefulWidgetState<Props> extends State<_FCStatefulWidget<Props>> {
  late _FCDispatcher owner;
  List<Hook>? hooks;

  void requestSetState() => setState(() {});

  void _flushUpdateEffects() {
    final hooks = this.hooks;
    if (mounted && hooks != null) {
      for (var i = 0; i < hooks.length; i++) {
        final hook = hooks[i];
        if (hook.effectFlag & _effectFlagUpdate > 0 && hook.effectStale) {
          hook.effectStale = false;
          hook.dispose?.call();
          hook.dispose = hook.create?.call();
        }
      }
    }
  }

  void _disposeEffects() {
    final hooks = this.hooks;
    if (hooks != null) {
      for (var i = 0; i < hooks.length; i++) {
        final hook = hooks[i];
        hook.dispose?.call();
        hook.dispose = null;
      }
    }
  }

  @override
  void dispose() {
    _disposeEffects();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final builder = widget.builder;
    final props = widget.props;
    WidgetsBinding.instance
        .addPostFrameCallback((timeStamp) => _flushUpdateEffects());
    if (hooks == null) {
      _kCurrentDispatcher = _FcMountDispatcher(this);
    } else {
      _kCurrentDispatcher = _FcUpdateDispatcher(this);
    }
    final built = builder(props, widget.ref);
    hooks = _kCurrentDispatcher!.memoizedHooks;
    return built;
  }
}

class FCType implements Type {
  final String name;
  FCType(this.name);

  String get fullName => "FCType_$name";

  @override
  int get hashCode => fullName.hashCode;

  @override
  bool operator ==(Object other) {
    return other is FCType && other.name == name;
  }
}

_FCDispatcher _getCurrentDispatcher() {
  final dispatcher = _kCurrentDispatcher;
  assert(dispatcher != null, "can use hooks outside build");
  return dispatcher!;
}

class FCRef<T> {
  T current;
  FCRef(this.current);
}

abstract class FCProps {
  void debugFillProperties(DiagnosticPropertiesBuilder properties);
}

/// useState acquires a mutable value
/// and a function to mutate and ask for an update
///
/// ```dart
/// final (num, setNum) = useState(0);
/// ```
(T, Function(T value)) useState<T>(T init) {
  return _getCurrentDispatcher().useState(init);
}

/// useMemo acquires a computed value
/// that will not compute again if items in deps are not changed
///
/// ```dart
/// final swText = useMemo(() => sw ? 'On' : 'Off', [sw])
/// ```
T useMemo<T>(T Function() factory, List? deps) {
  return _getCurrentDispatcher().useMemo(factory, deps);
}

/// useEffect posts a callback after mount or update
/// that will not called again if items in deps are not changed
///
/// ```dart
/// useEffect(() {
///   final subscribe = brightness.listen(() {
///     print("brightness change: ${brightness.value}");
///   });
///   return () => subscribe.cancel();
/// }, [sw]);
/// ```
useEffect(Function()? Function() effectFn, [List? deps]) {
  return _getCurrentDispatcher().useEffect(effectFn, deps);
}

/// useRef acquires a value holder object
/// that is mutable but never asks for updates.
///
/// ```dart
/// final textController = useRef(TextController());
/// textController.current;
///
/// final myKey = useRef(GlobalKey<MyStatefulWidgetState>());
/// myKey.current;
/// ```
FCRef<T> useRef<T>(T init) {
  return _getCurrentDispatcher().useRef(init);
}

/// bound to flutter, useBuildContext retrieve state's context
BuildContext useBuildContext() {
  return _getCurrentDispatcher().useBuildContext();
}

/// define a Stateful FC,
/// hooks are allowed to use during function call
MemoizedFC<Props> defineFC<Props>(FC<Props> fn) {
  final name = "defineStatefulFC_${_nextFCId()}";
  return ({props, ref, key}) =>
      _FCStatefulWidget((props, ref) => fn(props), props, ref, name, key: key);
}

/// define a Stateless FC as like a [Builder] delegate.
///
/// Typically used for optimizing performance.
///
/// DO NOT use any hooks in function call.
MemoizedFC<Props> defineStatelessFC<Props>(FC<Props> fn) {
  final name = "defineStatelessFC_${_nextFCId()}";
  return ({props, ref, key}) =>
      _FCStatelessWidget((props, ref) => fn(props), props, ref, name, key: key);
}

/// define a Stateful FC with ref forwarded from outside
MemoizedFC<Props> forwardRef<Props>(ForwardRefFC<Props> fn) {
  final name = "forwardRefStatefulFC_${_nextFCId()}";
  return ({props, ref, key}) => _FCStatefulWidget(
      ([props, ref, key]) => fn(props, ref), props, ref, name);
}

/// define a Stateless FC with ref forwarded from outside
MemoizedFC<Props> forwardRefStateless<Props>(ForwardRefFC<Props> fn) {
  final name = "forwardRefStatelessFC_${_nextFCId()}";
  return ({props, ref, key}) => _FCStatelessWidget(
      ([props, ref, key]) => fn(props, ref), props, ref, name);
}
