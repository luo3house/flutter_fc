// ignore_for_file: avoid_function_literals_in_foreach_calls

import 'package:flutter/widgets.dart';

typedef DisposeFunctionOrAny = dynamic;

// lifecycle of State class
const hookUseSetState = "UseSetState";
const hookUseIsMounted = "UseIsMounted";
const hookUseDidChangeDependencies = "UseDidChangeDependencies";
const hookUseReassemble = "UseReassemble";
const hookUseDispose = "UseDispose";
const hookUseDangerousAfterRebuild = "UseDangerousAfterRebuild";

abstract class StateDispatcher {
  static StateDispatcher? currentDispatcher;

  Function([Function()?]) useSetState();

  bool Function() useIsMounted();

  Element useElement();

  useDidChangeDependencies(Function()? Function() effect);

  useReassemble(Function() effect);

  useDispose(Function() effect);

  useDiff(DisposeFunctionOrAny Function() effect, [List? deps]);

  T useMemo<T>(T Function() factory, [List? deps]);

  useDangerousAfterRebuild(DisposeFunctionOrAny Function() factory,
      [List? deps]);
}

class StateDispatcherOfFCElement implements StateDispatcher {
  final FCElement element;
  final bool creation;
  final memmoizedHooks = <FCHook>[];
  var pointer = 0;
  StateDispatcherOfFCElement(this.element, this.creation);

  FCHook next(String name) {
    final hook = element.hooks.elementAt(pointer++);
    assert(hook.name == name, "expected hook is $name, but got ${hook.name}");
    return hook;
  }

  @override
  useDidChangeDependencies(Function()? Function() effect) {
    const name = hookUseDidChangeDependencies;
    final hook = creation ? FCHook(name) : next(name);
    memmoizedHooks.add(hook);
  }

  @override
  useDispose(Function() effect) {
    const name = hookUseDispose;
    final hook = creation ? FCHook(name) : next(name);
    memmoizedHooks.add(hook);
  }

  @override
  bool Function() useIsMounted() {
    return () => element.mounted;
  }

  @override
  useReassemble(Function() effect) {
    const name = hookUseDispose;
    final hook = creation ? FCHook(name) : next(name);
    memmoizedHooks.add(hook);
  }

  @override
  Function([Function()?]) useSetState() {
    return ([fn]) {
      fn?.call();
      element.markNeedsBuild();
    };
  }

  @override
  T useMemo<T>(T Function() factory, [List? deps]) {
    const name = hookUseDispose;
    final hook = creation ? FCHook(name) : next(name);
    final hookDeps = hook.deps;
    if (creation ||
        deps == null ||
        hookDeps == null ||
        !ListUtil.shallowEq(hookDeps, deps)) {
      hook.memoizedState = factory();
    }
    hook.deps = deps;
    memmoizedHooks.add(hook);
    return hook.memoizedState as T;
  }

  @override
  useDiff(Function() effect, [List? deps]) {
    const name = hookUseDispose;
    final hook = creation ? FCHook(name) : next(name);
    final hookDeps = hook.deps;
    if (creation ||
        deps == null ||
        hookDeps == null ||
        !ListUtil.shallowEq(hookDeps, deps)) {
      hook.destroy?.call();
      final newDestroy = effect();
      if (newDestroy is Function()) hook.destroy = newDestroy;
    }
    hook.deps = deps;
    memmoizedHooks.add(hook);
  }

  @override
  Element useElement() {
    return element;
  }

  @override
  useDangerousAfterRebuild(DisposeFunctionOrAny Function() factory,
      [List? deps]) {
    const name = hookUseDangerousAfterRebuild;
    final hook = creation ? FCHook(name) : next(name);
    final hookDeps = hook.deps;
    hook.create =
        factory is DisposeFunctionOrAny Function()? Function() ? factory : null;
    hook.isStale = creation ||
        deps == null ||
        hookDeps == null ||
        !ListUtil.shallowEq(hookDeps, deps);
    hook.deps = deps;
    memmoizedHooks.add(hook);
  }
}

abstract class FCWidget extends Widget {
  const FCWidget({super.key});

  Widget build(BuildContext context);

  @override
  Element createElement() => FCElement(this);
}

class FCElement<T extends FCWidget> extends ComponentElement {
  final errHookLengthMismatch = AssertionError("hook length mismatch");

  FCElement(super.widget) {
    assert(widget is FCWidget, "widget should be descendant of FCWidget");
  }

  T get fcWidget => super.widget as T;

  final hooks = <FCHook>[];

  var _hasInit = false;
  var isFirstBuild = true;

  @protected
  beforeFirstRebuild() {}

  @override
  void reassemble() {
    super.reassemble();
    for (final hook in hooks.only(hookUseReassemble)) {
      hook.create?.call();
    }
  }

  @override
  void update(covariant Widget newWidget) {
    super.update(newWidget);
    rebuild(force: true);
  }

  @override
  void rebuild({bool force = false}) {
    if (!_hasInit) {
      _hasInit = true;
      beforeFirstRebuild();
    }
    super.rebuild(force: force);
    didAfterRebuild();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final hook in hooks.only(hookUseDidChangeDependencies)) {
      hook.destroy?.call();
      hook.destroy = hook.create?.call();
    }
  }

  @override
  void unmount() {
    super.unmount();
    hooks.only(hookUseDispose).forEach((hook) => hook.create?.call());
    hooks.removeWhere((hook) {
      hook.destroy?.call();
      hook.clear();
      return true;
    });
  }

  @override
  Widget build() {
    final creation = this.isFirstBuild;
    this.isFirstBuild = false;
    final dispatcher = StateDispatcher.currentDispatcher =
        StateDispatcherOfFCElement(this, creation);
    Widget result;
    try {
      result = fcWidget.build(this);
      if (creation) {
        hooks.clear();
        hooks.addAll(dispatcher.memmoizedHooks);
      } else if (hooks.length != dispatcher.memmoizedHooks.length) {
        throw FCError(
            "hook length mismatch, expected ${hooks.length} but got ${dispatcher.memmoizedHooks.length}");
      }
    } catch (e) {
      isFirstBuild = true;
      if (e is FCError) {
        dispatcher.memmoizedHooks
            .only(hookUseDispose)
            .forEach((hook) => hook.destroy?.call());
        dispatcher.memmoizedHooks.forEach((hook) => hook.clear());
        dispatcher.memmoizedHooks.clear();
      }
      rethrow;
    } finally {
      StateDispatcher.currentDispatcher = null;
    }
    return result;
  }

  didAfterRebuild() {
    hooks.only(hookUseDangerousAfterRebuild).forEach((hook) {
      if (hook.isStale) {
        hook.destroy?.call();
        hook.destroy = hook.create?.call();
        hook.isStale = false;
      }
    });
  }
}

class FCError extends AssertionError {
  FCError([super.message]);
}

class FCHook {
  final String name;
  Function()? Function()? create;
  dynamic memoizedState;
  Function()? destroy;
  List? deps;
  var isStale = false;
  FCHook(this.name);

  clear() {
    create = null;
    memoizedState = null;
    destroy = null;
    deps = null;
    isStale = false;
  }

  @override
  String toString() {
    return "${super.toString()} ${{
      "create": create,
      "memoizedState": memoizedState,
      "destroy": destroy,
      "deps": deps,
      "isStale": isStale,
    }}";
  }
}

extension FCHookListExt on Iterable<FCHook> {
  Iterable<FCHook> only(String name) => where((hook) => hook.name == name);
}

class ListUtil {
  ListUtil._();

  static bool eq<T>(List<T> a1, List<T> a2, bool Function(T a, T b) test) {
    if (a1.length != a2.length) return false;
    for (var i = 0; i < a1.length; i++) {
      if (!test(a1.elementAt(i), a2.elementAt(i))) {
        return false;
      }
    }
    return true;
  }

  /// perform == for each items in 2 Lists.
  ///
  /// If need deep equals, try operator override
  static bool shallowEq(List a1, List a2) {
    return eq(a1, a2, (a, b) => a == b);
  }
}

StateDispatcher get currentDispatcher {
  return StateDispatcher.currentDispatcher!;
}

Function([Function()?]) useSetState() {
  return currentDispatcher.useSetState();
}

bool Function() useIsMounted() {
  return currentDispatcher.useIsMounted();
}

Element useElement() {
  return currentDispatcher.useElement();
}

useDidChangeDependencies(Function()? Function() effect) {
  return currentDispatcher.useDidChangeDependencies(effect);
}

useReassemble(Function() effect) {
  return currentDispatcher.useReassemble(effect);
}

useDispose(Function() effect) {
  return currentDispatcher.useDispose(effect);
}

useDiff(DisposeFunctionOrAny Function() effect, [List deps = const []]) {
  return currentDispatcher.useDiff(effect, deps);
}

T useMemo<T>(T Function() factory, [List deps = const []]) {
  return currentDispatcher.useMemo(factory, deps);
}

useDangerousAfterRebuild(DisposeFunctionOrAny Function() effect, [List? deps]) {
  return currentDispatcher.useDangerousAfterRebuild(effect, deps);
}
