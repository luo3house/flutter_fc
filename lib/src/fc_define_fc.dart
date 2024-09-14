import 'package:flutter/widgets.dart';

import 'fc_core.dart';
export 'fc_foundation.dart' show useState;

typedef WidgetKeyBuilder<Props> = Widget Function(
    BuildContext context, Props? props, Key? key);
typedef MemoizedFC<Props> = Widget Function({Props? props, Key? ref, Key? key});
typedef ForwardRefFC<Props> = Widget Function(
    BuildContext context, Props? props, Key? ref);
typedef FC<Props> = Widget Function(BuildContext context, Props? props);

var kDangerousFCIndex = 0;
int nextFCId() => ++kDangerousFCIndex;

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

MemoizedFC<Props> defineFC<Props>(FC<Props> fn) {
  final name = "defineFC_${nextFCId()}";
  return ({props, ref, key}) => FCPropsWidget(
      (context, props, ref) => fn(context, props), props, ref, name,
      key: key);
}
