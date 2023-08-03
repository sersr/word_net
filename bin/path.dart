import 'package:file/local.dart';
import 'package:file/file.dart';
export 'package:file/local.dart';
export 'package:file/file.dart';

const fs = LocalFileSystem();

Directory get current => fs.currentDirectory;
