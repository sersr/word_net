import 'dart:convert';

import 'package:nop/nop.dart';

import 'args.dart';
import 'path.dart';

void main(List<String> args) {
  final paths = getPaths(args);
  if (paths == null) return;
  final (root, output) = paths;

  final map = autoGen(root);

  output.createSync(recursive: true);
  final jsonData = json.encode(map);
  output.writeAsStringSync(jsonData);
  Log.w('output: ${output.path} done.', onlyDebug: false);
}

Map autoGen(Directory dir) {
  final files = dir.listSync(recursive: false, followLinks: false);
  final child = <String, dynamic>{};

  for (var file in files) {
    if (file is Directory) {
      final nextChild = autoGen(file);
      child[file.basename] = nextChild;
      continue;
    }
    if (file is! File || !file.basename.endsWith('.md')) continue;

    final data = file.readAsStringSync();
    child[file.basename] = data;
  }
  return child;
}
