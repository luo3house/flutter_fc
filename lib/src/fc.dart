import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'utils.dart';
part 'shim.dart';

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
  useImperativeHandle<T>(FCRef<T> ref, T Function() fn);
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

abstract class _FCDispatcherOwner {
  BuildContext get context;
  List<Hook>? get memoizedHooks;
  void requestUpdate();
}

class _FCMountDispatcher extends _FCDispatcher {
  final _FCDispatcherOwner owner;
  _FCMountDispatcher(this.owner);

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
        owner.requestUpdate();
      }
    );
  }

  @override
  useImperativeHandle<T>(FCRef<T> ref, T Function() fn) {
    memoizedHooks.add(Hook("useImperativeHandle", _effectFlagUpdate)
      ..effectStale = true
      ..create = () {
        ref.current = fn();
        return null;
      });
  }

  @override
  BuildContext useBuildContext() {
    return owner.context;
  }
}

class _FcUpdateDispatcher extends _FCDispatcher {
  final _FCDispatcherOwner owner;
  var hookIndex = 0;
  _FcUpdateDispatcher(this.owner) {
    memoizedHooks.addAll(owner.memoizedHooks ?? const []);
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
        owner.requestUpdate();
      }
    );
  }

  @override
  useImperativeHandle<T>(FCRef<T> ref, T Function() fn) {
    final hook = retrieveHook("useImperativeHandle");
    memoizedHooks.add(hook
      ..effectStale = true
      ..create = () {
        ref.current = fn();
        return null;
      });
  }

  @override
  BuildContext useBuildContext() {
    return owner.context;
  }
}

class _FCPropsWidget<Props> extends Widget implements _FCWidget {
  final String name;
  final ForwardRefFC<Props> builder;
  final Props? props;
  final Key? ref;

  const _FCPropsWidget(
    this.builder,
    this.props,
    this.ref,
    this.name, {
    super.key,
  });

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    if (props is FCProps) {
      return (props as FCProps).debugFillProperties(properties);
    }
    super.debugFillProperties(properties);
  }

  @override
  Type get runtimeType => FCType("${super.runtimeType.toString()}\$$name");

  @override
  Element createElement() => _FCElement<_FCPropsWidget>(this);

  @override
  Widget build(BuildContext context) => builder(props, ref);
}

/// [StatelessElement]
/// [StatefulElement]
class _FCElement<T extends _FCWidget> extends ComponentElement
    implements _FCDispatcherOwner {
  late _FCDispatcher dispatcher;
  @override
  List<Hook>? memoizedHooks;

  var _reassembled = false;

  _FCElement(super.widget);

  @override
  _FCWidget get widget => super.widget as _FCWidget;

  @override
  BuildContext get context => this;

  @override
  void requestUpdate() => markNeedsBuild();

  @override
  void rebuild({bool force = false}) {
    super.rebuild(force: force);
    _flushUpdateEffects();
  }

  @override
  void update(covariant Widget newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    rebuild(force: true);
  }

  @override
  void unmount() {
    super.unmount();
    _disposeEffects();
  }

  @override
  void reassemble() {
    _reassembled = true;
    super.reassemble();
  }

  @override
  Widget build() => _buildWithHooks();

  void _flushUpdateEffects() {
    final hooks = this.memoizedHooks;
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
    final hooks = this.memoizedHooks;
    if (hooks != null) {
      for (var i = 0; i < hooks.length; i++) {
        final hook = hooks[i];
        hook.dispose?.call();
        hook.dispose = null;
      }
    }
  }

  Widget _buildWithHooks() {
    final reassembledJust = _reassembled;
    _reassembled = false;
    if (memoizedHooks == null) {
      _kCurrentDispatcher = _FCMountDispatcher(this);
    } else {
      _kCurrentDispatcher = _FcUpdateDispatcher(this);
    }
    try {
      final built = widget.build(this);
      memoizedHooks = _kCurrentDispatcher!.memoizedHooks;
      return built;
    } catch (e) {
      if (reassembledJust) {
        memoizedHooks = null;
        final built = widget.build(this);
        memoizedHooks = _kCurrentDispatcher!.memoizedHooks;
        return built;
      } else {
        rethrow;
      }
    } finally {
      _kCurrentDispatcher = null;
    }
  }
}

abstract class _FCWidget implements Widget {
  Widget build(BuildContext context);
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

  @override
  String toString() {
    return "${super.toString()}(fullName=$fullName)";
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

/// useImperativeHandle exposes a value instantiated from fn
///
/// this effect always called on each update
///
/// ```dart
/// final Child = defineFC((FCRef<Function?>? ref) {
///   assert(ref != null);
///   useImperativeHandle(ref!, () => () => print("child call"));
///   return const SizedBox();
/// });
///
/// final Parent = defineFC((props) {
///   final ref = useRef<Function()?>(null);
///   useEffect(() {
///     // parent call child
///     ref.current?.call();
///   });
///   return Child(props: ref);
/// });
/// ```
useImperativeHandle<T>(FCRef<T> ref, T Function() fn) {
  return _getCurrentDispatcher().useImperativeHandle(ref, fn);
}

/// bound to flutter, useBuildContext retrieve state's context
BuildContext useBuildContext() {
  return _getCurrentDispatcher().useBuildContext();
}

/// define a Stateful FC,
/// hooks are allowed to use during function call
MemoizedFC<Props> defineFC<Props>(FC<Props> fn) {
  final name = "defineFC_${_nextFCId()}";
  return ({props, ref, key}) =>
      _FCPropsWidget((props, ref) => fn(props), props, ref, name, key: key);
}

/// define a Stateful FC with ref forwarded from outside
MemoizedFC<Props> forwardRef<Props>(ForwardRefFC<Props> fn) {
  final name = "forwardRefStatefulFC_${_nextFCId()}";
  return ({props, ref, key}) =>
      _FCPropsWidget(([props, ref, key]) => fn(props, ref), props, ref, name);
}
