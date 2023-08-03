import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:nop/nop.dart';
import 'package:word_net/_router/routes.dart';
import 'package:word_net/modules/home/providers/provider.dart';

void main() async {
  Hive.init('hive');
  Routes.init();
  Log.logPathFn = (path) => path;

  router.put(() => HomeProvider());

  final app = MaterialApp.router(
    routerConfig: router,
  );

  runApp(app);
}
