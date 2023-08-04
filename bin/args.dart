import 'package:args/args.dart';
import 'package:nop/nop.dart';

import 'path.dart';

(Directory root, File output)? getPaths(List<String> args) {
  final parser = ArgParser();

  parser.addOption('output', abbr: 'o', help: '生成 json 文件的输出位置.');
  parser.addOption('path', abbr: 'p', help: 'word_net 数据库的根目录文件夹');
  parser.addFlag('help', abbr: 'h');

  final results = parser.parse(args);
  final help = results['help'] as bool;

  if (help) {
    Log.w(parser.usage);
    return null;
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
    return null;
  }
  final output = switch (outputName) {
    String file => current.childFile(file),
    _ => current.childDirectory('assets').childFile('word_net.json'),
  };

  return (root, output);
}
