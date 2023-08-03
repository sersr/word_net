import 'package:equatable/equatable.dart';

class EqWrap<T> with EquatableMixin {
  EqWrap(this.value);
  final T value;

  @override
  late final List<Object?> props = [value];
}
