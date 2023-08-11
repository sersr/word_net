import 'package:flutter/material.dart';
import 'package:flutter_nop/flutter_nop.dart';
import 'package:word_net/modules/utils/equatable.dart';

class HomeState {
  final currentSelected = ''.cs;

  final currentPath = EqWrap(const <String>[]).cs;

  final _dirDisplays = <EqWrap, AutoListenNotifier<bool>>{};

  AutoListenNotifier<bool> getDisplay(List<String> path) {
    return _dirDisplays.putIfAbsent(EqWrap(path), () => false.cs);
  }

  void remove(List<String> path) {
    _dirDisplays.remove(EqWrap(path));
  }

  void resetDisplayState() {
    _dirDisplays.clear();
  }

  void updatePaths() {
    final paths = currentPath.value.value;
    int count = 0;
    while (count <= paths.length) {
      final path = paths.sublist(0, count);
      final notifier = getDisplay(path);

      notifier.value = true;
      count++;
    }
  }

  final bodyTextSpan = const TextSpan().cs;
}
