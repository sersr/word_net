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

  final bodyTextSpan = const TextSpan().cs;
}
