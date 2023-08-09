import 'package:flutter/material.dart';
import 'package:flutter_nop/router.dart';
import 'package:word_net/modules/home/providers/provider.dart';
import 'package:word_net/modules/widgets/init_once_mixin.dart';

class ContentWidget extends StatefulWidget {
  const ContentWidget({super.key});

  @override
  State<ContentWidget> createState() => _ContentWidgetState();
}

class _ContentWidgetState extends State<ContentWidget> with InitOnceMixin {
  late HomeProvider homeProvider;

  @override
  void initOnce() {
    homeProvider = context.grass();
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
