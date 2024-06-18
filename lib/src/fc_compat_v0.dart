import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'fc_core.dart';
import 'fc_lib.dart';
export 'fc_foundation.dart' show useState;

typedef WidgetKeyBuilder<Props> = Widget Function(
    BuildContext context, Props? props, Key? key);
typedef MemoizedFC<Props> = Widget Function({Props? props, Key? ref, Key? key});
typedef ForwardRefFC<Props> = Widget Function(
    BuildContext context, Props? props, Key? ref);
typedef FC<Props> = Widget Function(BuildContext context, Props? props);

var kFCIndex = 0;
int nextFCId() => ++kFCIndex;

class FCPropsWidget<Props> extends Widget implements FCWidget {
  final String name;
  final WidgetKeyBuilder<Props> builder;
  final Props props;
  final Key? ref;

  const FCPropsWidget(
    this.builder,
    this.props,
    this.ref,
    this.name, {
    super.key,
  });

  @override
  Type get runtimeType => FCType("${super.runtimeType}\$$name");

  @override
  Element createElement() => FCElement<FCPropsWidget>(this);

  @override
  Widget build(BuildContext context) {
    return builder(context, props, ref);
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

  @override
  String toString() {
    return "${super.toString()}(fullName=$fullName)";
  }
}

BuildContext useBuildContext() {
  return useElement();
}

useEffect(Function()? Function() effect, [List? deps]) {
  if (kDebugMode) {
    print("""
[flutter_fc] useEffect is deprecated as it may cause errors 
when setting parent's state while building child. 
Please use "useDiff" with "addPostFrameCallback" instead.
""");
  }
  useDangerousAfterRebuild(effect, deps);
}

MemoizedFC<Props> defineFC<Props>(FC<Props> fn) {
  final name = "defineFC_${nextFCId()}";
  return ({props, ref, key}) => FCPropsWidget(
      (context, props, ref) => fn(context, props), props, ref, name,
      key: key);
}

MemoizedFC<Props> forwardRef<Props>(ForwardRefFC<Props> fn) {
  final name = "forwardRefStatefulFC_${nextFCId()}";
  return ({props, ref, key}) {
    return FCPropsWidget((context, props, key) {
      return fn(context, props, ref);
    }, props, ref, name);
  };
}

useImperativeHandle<T>(Ref<T> ref, T Function() create) {
  useEffect(() {
    ref.value = create();
    return () => ref.value = null;
  }, [ref]);
}
