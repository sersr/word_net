import 'package:flutter/material.dart';
import 'package:flutter_nop/flutter_nop.dart';
import 'package:word_net/modules/utils/equatable.dart';

class HomeState {
  final currentSelected = ''.cs;

  final currentPath = EqWrap(const <String>[]).cs;

  final _dirDisplays = <String, AutoListenNotifier<bool>>{};

  AutoListenNotifier<bool> getDisplay(String item) {
    return _dirDisplays.putIfAbsent(item, () => false.cs);
  }

  void remove(String item) {
    _dirDisplays.remove(item);
  }

  void resetDisplayState() {
    _dirDisplays.clear();
  }

  void updatePaths() {
    final paths = currentPath.value.value;
    int count = 0;
    while (count <= paths.length) {
      final path = paths.sublist(0, count).join('');
      final notifier = getDisplay(path);

      notifier.value = true;
      count++;
    }
  }

  final bodyTextSpan = const TextSpan().cs;
}
