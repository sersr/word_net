import 'package:nop/nop.dart';

import 'args.dart';
import 'path.dart';

void main(List<String> args) {
  final paths = getPaths(args);
  if (paths == null) return;
  final (root, _) = paths;

  final styles = <String>{};
  void gen(Directory dir) {
    final files = dir.listSync(recursive: false, followLinks: false);

    final reg = RegExp('(<.*?>)', multiLine: true, dotAll: true);
    for (var file in files) {
      if (file is Directory) {
        gen(file);
        continue;
      }
      if (file is! File || !file.basename.endsWith('.md')) continue;

      final data = file.readAsStringSync();
      final matchs = reg.allMatches(data);
      for (var match in matchs) {
        styles.add(match[1]!);
      }
    }
  }

  gen(root);

  Log.w(styles);
}
