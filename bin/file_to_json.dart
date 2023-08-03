import 'dart:convert';

import 'package:args/args.dart';
import 'package:nop/nop.dart';

import 'path.dart';

void main(List<String> args) {
  final parser = ArgParser();

  parser.addOption('output', abbr: 'o', help: '生成 json 文件的输出位置.');
  parser.addOption('path', abbr: 'p', help: 'word_net 数据库的根目录文件夹');
  parser.addFlag('help', abbr: 'h');

  final results = parser.parse(args);
  final help = results['help'] as bool;

  if (help) {
    Log.w(parser.usage);
    return;
  }
  final outputName = results['output'];
  final pathName = results['path'];

  final root = switch (pathName) {
    String path => current.childDirectory(path),
    _ => current.childDirectory('data'),
  };
  Log.w('path: ${root.path}', onlyDebug: false);

  if (!root.existsSync()) {
    Log.e('error path: ${root.path}.', onlyDebug: false);
    return;
  }

  final map = autoGen(root);

  final output = switch (outputName) {
    String file => current.childFile(file),
    _ => current.childDirectory('assets').childFile('word_net.json'),
  };

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
