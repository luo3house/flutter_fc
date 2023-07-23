import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'utils.dart';

var _kFCIndex = 0;
_FCDispatcher? _kCurrentDispatcher;

abstract class _FCDispatcher {
  final List<Hook> memoizedHooks = [];
  (T, Function(T value)) useState<T>(T init);
  T useMemo<T>(T Function() factory, List? deps);
  useEffect(Function()? Function() effectFn, List? deps);
  FCRef<T> useRef<T>(T init);
}

class Hook {
  final String flag;
  Function()? Function()? create;
  Function()? dispose;
  List? deps;
  dynamic value;
  bool effectStale = false;
  Hook(this.flag);
}

class _FcMountDispatcher extends _FCDispatcher {
  final _FCWidgetState state;
  _FcMountDispatcher(this.state);

  @override
  useEffect(Function()? Function() effectFn, List? deps) {
    final hook = Hook("useEffect");
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
}

class _FcUpdateDispatcher extends _FCDispatcher {
  final _FCWidgetState state;
  var hookIndex = 0;
  _FcUpdateDispatcher(this.state) {
    memoizedHooks.addAll(state.hooks ?? []);
  }

  Hook retrieveHook(String flag) {
    assert(memoizedHooks.length >= hookIndex + 1, "should have at least ${hookIndex + 1} hooks but got ${memoizedHooks.length}");
    final hook = memoizedHooks[hookIndex];
    if (hook.flag != flag) {
      assert(false, "expected Hook($flag) but got Hook(${hook.flag})");
    }
    hookIndex++;
    return hook;
  }

  @override
  useEffect(Function()? Function() effectFn, List? deps) {
    final hook = retrieveHook("useEffect");
    hook.effectStale = !ListUtil.shallowEq(hook.deps ?? const [], deps ?? const []);
    memoizedHooks.add(hook
      ..deps = deps
      ..create = effectFn);
  }

  @override
  T useMemo<T>(T Function() factory, List? deps) {
    final hook = retrieveHook("useMemo");
    if (ListUtil.shallowEq(hook.deps ?? const [], deps ?? const [])) {
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
}

class _FCWidget<Props> extends StatefulWidget {
  late final Type fcType;
  final Widget Function(Props? props) builder;
  final Props? props;

  _FCWidget(this.builder, this.props, String name, {super.key}) {
    fcType = FCType(name);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    if (props is FCProps) {
      return (props as FCProps).debugFillProperties(properties);
    }
    super.debugFillProperties(properties);
  }

  @override
  Type get runtimeType => fcType;

  @override
  State<StatefulWidget> createState() {
    return _FCWidgetState<Props>();
  }
}

class _FCWidgetState<Props> extends State<_FCWidget<Props>> {
  late _FCDispatcher owner;
  List<Hook>? hooks;

  void requestSetState() => setState(() {});

  void _flushFrameEffects() {
    final hooks = this.hooks;
    if (mounted && hooks != null) {
      for (var i = 0; i < hooks.length; i++) {
        final hook = hooks[i];
        if (hook.flag == 'useEffect' && hook.effectStale) {
          hook.effectStale = false;
          hook.dispose?.call();
          hook.dispose = hook.create?.call();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final builder = widget.builder;
    final props = widget.props;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => _flushFrameEffects());
    if (hooks == null) {
      _kCurrentDispatcher = _FcMountDispatcher(this);
    } else {
      _kCurrentDispatcher = _FcUpdateDispatcher(this);
    }
    final built = builder(props);
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
  T value;
  FCRef(this.value);
}

abstract class FCProps {
  void debugFillProperties(DiagnosticPropertiesBuilder properties);
}

(T, Function(T value)) useState<T>(T init) {
  return _getCurrentDispatcher().useState(init);
}

T useMemo<T>(T Function() factory, List? deps) {
  return _getCurrentDispatcher().useMemo(factory, deps);
}

useEffect(Function()? Function() effectFn, List? deps) {
  return _getCurrentDispatcher().useEffect(effectFn, deps);
}

FCRef<T> useRef<T>(T init) {
  return _getCurrentDispatcher().useRef(init);
}

Widget Function([Props? props]) defineFC<Props>(Widget Function(Props? props) delegate) {
  final name = "defineFC_${++_kFCIndex}";
  return ([props]) => _FCWidget(delegate, props, name);
}
