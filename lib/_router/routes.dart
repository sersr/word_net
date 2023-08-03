import 'package:flutter/material.dart';
import 'package:flutter_nop/router.dart';
import 'package:nop_annotations/annotation/router.dart';

import '../modules/home/pages/home.dart';

part 'routes.g.dart';

@RouterMain(page: HomePage)
// ignore: unused_element
abstract class _Routes {}

NRouter get router => Routes.router;
