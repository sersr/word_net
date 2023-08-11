import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:nop/nop.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:word_net/_router/routes.dart';
import 'package:word_net/modules/home/providers/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await getApplicationDocumentsDirectory().then((value) {
    Hive.init(join(value.path, 'hive'));
  });

  Routes.init();
  Log.logPathFn = (path) => path;

  router.put(() => HomeProvider());

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarBrightness: Brightness.light,
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  final app = MaterialApp.router(
    title: '基础汉英类义词典',
    debugShowCheckedModeBanner: false,
    routerConfig: router,
  );

  runApp(app);
}
