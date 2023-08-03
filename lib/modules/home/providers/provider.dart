import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_nop/flutter_nop.dart';
import 'package:hive/hive.dart';
import 'package:word_net/modules/home/providers/state.dart';
import 'package:word_net/modules/utils/equatable.dart';

class HomeProvider with NopLifecycle {
  final _boxNotifier = AutoListenNotifier<Box?>(null);
  final _boxFileNotifier = AutoListenNotifier<Box?>(null);
  final state = HomeState();

  @override
  void nopInit() async {
    final box = await Hive.openBox('word_net_indexs');
    final fileBox = await Hive.openBox('word_net_file');
    if (box.get('indexs') == null) {
      final data = await rootBundle.loadString('assets/word_net.json');
      var map = json.decode(data) as Map;
      final list = map.keys.toList();
      list.sort();

      const first = '0本资料库基本信息';
      final firstIndex = list.indexOf(first);

      if (firstIndex != -1) {
        list.removeAt(firstIndex);

        // list.insert(0, first); // 放在开头
        list.add(first); // 放在最后
      }

      for (var MapEntry(:String key, :Map value) in map.entries) {
        await _autoGen(value, key, box, fileBox);
      }
      await box.put('indexs', list);
    }

    if (!mounted) {
      box.close();
      fileBox.close();
    } else {
      _boxNotifier.value = box;
      _boxFileNotifier.value = fileBox;
    }
  }

  Future<void> _autoGen(Map map, String prefix, Box box, Box file) async {
    final keys =
        map.keys.map((e) => '$e'.replaceAll(RegExp('.md\$'), '')).toList();
    keys.sort();

    await box.put(prefix, keys);

    for (var MapEntry(:String key, :value) in map.entries) {
      key = key.replaceAll(RegExp('.md\$'), '');

      if (value is Map) {
        final childPrefix = '$prefix$key';
        await _autoGen(value, childPrefix, box, file);
      } else if (value is String) {
        await file.put(key, value);
      }
    }
  }

  List<String> get indexs {
    final value = _boxNotifier.value;
    if (value == null) return const [];
    return value.get('indexs', defaultValue: const []);
  }

  bool get currentIsFile => isFile(state.currentSelected.value);

  bool isFile(String item) {
    final value = _boxFileNotifier.value;
    if (value == null) return true;

    return value.get(item) != null;
  }

  bool get currentIsDir {
    final value = _boxNotifier.value;
    if (value == null) return true;
    return value.get(state.currentSelected.value) != null;
  }

  List<String> get currentItem => getItems(state.currentSelected.value);

  String get currentString => getData(state.currentSelected.value);

  List<String> getItems(String item) {
    final value = _boxNotifier.value;
    if (value == null) return const [];
    return value.get(item, defaultValue: const <String>[]);
  }

  String getData(String item) {
    final value = _boxFileNotifier.value;
    if (value == null) return '';
    return value.get(item, defaultValue: '');
  }

  void onPressed(String current) {
    state.currentSelected.value = current;
  }

  void updatePath(List<String> newPath) {
    state.currentPath.value = EqWrap(newPath);
  }

  bool isCurrentSelected(String item) {
    return state.currentSelected.value == item;
  }

  @override
  void nopDispose() {
    final box = _boxNotifier.value;
    _boxNotifier.value = null;
    box?.close();
  }
}
