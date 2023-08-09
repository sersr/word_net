import 'package:flutter/material.dart';

mixin InitOnceMixin<T extends StatefulWidget> on State<T> {
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_init) {
      _init = true;
      initOnce();
    }
  }

  void initOnce() {}
}
