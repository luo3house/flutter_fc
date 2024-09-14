import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'fc_core.dart';
import 'fc_define_fc.dart';
import 'fc_lib.dart';
export 'fc_foundation.dart' show useState;

typedef WidgetKeyBuilder<Props> = Widget Function(
    BuildContext context, Props? props, Key? key);
typedef MemoizedFC<Props> = Widget Function({Props? props, Key? ref, Key? key});
typedef ForwardRefFC<Props> = Widget Function(
    BuildContext context, Props? props, Key? ref);
typedef FC<Props> = Widget Function(BuildContext context, Props? props);

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
