import 'fc_core.dart';

Ref<T> useRef<T>([T? init]) {
  return useMemo(() => Ref()..value = init);
}

RefMust<T> useRefMust<T>(T init) {
  return useMemo(() => RefMust(init));
}

class Ref<T> {
  T? value;
  Ref([T? value]);
}

class RefMust<T> {
  T value;
  RefMust(this.value);
}
