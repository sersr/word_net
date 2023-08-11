import 'package:flutter/material.dart';
import 'package:flutter_nop/change_notifier.dart';
import 'package:flutter_nop/router.dart';
import 'package:nop/utils.dart';
import 'package:word_net/modules/home/providers/provider.dart';
import 'package:word_net/modules/home/widgets/search_widget.dart';

import '../widgets/content_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late HomeProvider provider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    provider = context.grass();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = Cs(() {
      final indexs = provider.indexs;

      if (indexs.isEmpty) return const SizedBox();

      final left = CustomScrollView(
        slivers: [
          for (var index in indexs)
            SliverToBoxAdapter(child: Dir(title: index)),
        ],
      );

      final size = MediaQuery.of(context).size;
      if (size.width < barWidth.value + 100) {
        if (provider.currentString.isNotEmpty) {
          return const ContentBody();
        }
        return left;
      }
      // final left = ListView.builder(
      //   itemBuilder: (context, index) {
      //     final item = indexs[index];

      //     return Dir(title: item);
      //   },
      //   itemCount: indexs.length,
      // );

      Widget divider = const MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        child: Padding(
          padding: EdgeInsets.only(left: 8),
          child: VerticalDivider(width: 2, thickness: 2),
        ),
      );

      divider = GestureDetector(
        onHorizontalDragUpdate: onUpdate,
        child: divider,
      );

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Cs(() => SizedBox(width: barWidth.value, child: left)),
          divider,
          const Expanded(child: ContentBody()),
        ],
      );
    });

    child = Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SearchWidget(),
          const Divider(height: 1, thickness: 1),
          Expanded(child: child),
        ],
      ),
    );
    TextField;

    child = Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) {
          final scope = FocusScope.of(context);
          if (scope.hasFocus) {
            scope.unfocus();
          }
          // SystemChannels.textInput.invokeMethod('TextInput.hide');
          provider.parser.delegate?.close();
        },
        child: child);

    return child;
    // return Stack(
    //   children: [
    //     child,
    //     Positioned.fill(
    //         child: IgnorePointer(
    //       child: CustomPaint(
    //         painter: ScreenLine(),
    //       ),
    //     ))
    //   ],
    // );
  }

  final barWidth = 200.0.cs;

  double _rawOffset = 200;

  void onUpdate(DragUpdateDetails details) {
    final delta = details.primaryDelta ?? 0.0;
    final size = MediaQuery.of(context).size;
    final max = size.width - 100;
    _rawOffset = _rawOffset + delta;
    _rawOffset = _rawOffset.minThan(max);
    barWidth.value = _rawOffset.maxThan(40);
  }
}
