import 'package:flutter/material.dart';
import 'package:flutter_nop/change_notifier.dart';
import 'package:flutter_nop/router.dart';
import 'package:word_net/modules/home/providers/provider.dart';

import '../../widgets/button.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('基础汉英类意词典'),
      ),
      body: Cs(() {
        final indexs = provider.indexs;

        if (indexs.isEmpty) return const SizedBox();
        final left = ListView.builder(
          itemBuilder: (context, index) {
            final item = indexs[index];

            // TextStyle? style;
            // if (provider.isCurrentSelected(item)) {
            //   style = const TextStyle(color: Colors.blue);
            // }
            return Dir(
              currentPath: item,
              title: item,
            );
            // return Container(
            //   padding:
            //       const EdgeInsets.symmetric(vertical: 5.0, horizontal: 8.0),
            //   child: BaseButton(
            //     onTap: () {
            //       provider.onPressed(item);
            //     },
            //     child: Container(
            //       alignment: Alignment.centerLeft,
            //       padding: const EdgeInsets.symmetric(
            //           vertical: 10.0, horizontal: 6.0),
            //       child: Text(item, style: style),
            //     ),
            //   ),
            // );
          },
          itemCount: indexs.length,
        );

        Widget right;

        if (provider.currentIsFile) {
          final data = provider.currentString;
          right = SingleChildScrollView(
            key: ValueKey(data),
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
            child: Text(data),
          );
        } else {
          right = const SizedBox();
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 200, child: left),
            const VerticalDivider(width: 1),
            Expanded(child: right),
          ],
        );
      }),
    );
  }
}

class Dir extends StatefulWidget {
  const Dir({
    super.key,
    required this.currentPath,
    required this.title,
  });
  final String currentPath;
  final String title;
  @override
  State<Dir> createState() => _DirState();
}

class _DirState extends State<Dir> with SingleTickerProviderStateMixin {
  final display = false.cs;

  late AnimationController animationController;
  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 240));

    animationController.addStatusListener(_updateDisplayState);
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  void _updateDisplayState(AnimationStatus status) {
    display.value = switch (status) {
      AnimationStatus.dismissed => false,
      _ => true,
    };
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.grass<HomeProvider>();
    const displayStyle = TextStyle(color: Colors.blue, fontSize: 14.0);
    return Cs(() {
      final items = controller.getItems(widget.currentPath);
      final style = display.value ? displayStyle : null;
      Widget top = BaseButton(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            alignment: Alignment.centerLeft,
            child: Text(widget.title, style: style),
          ),
        ),
        onTap: () {
          switch (animationController.status) {
            case AnimationStatus.forward || AnimationStatus.completed:
              animationController.reverse();
            case AnimationStatus.reverse || AnimationStatus.dismissed:
              animationController.forward();
          }
        },
      );

      if (!display.value) {
        return top;
      }

      Widget body = Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var item in items)
              controller.isFile(item)
                  ? BaseButton(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(item,
                            style: controller.isCurrentSelected(item)
                                ? displayStyle
                                : null),
                      ),
                      onTap: () {
                        controller.onPressed(item);
                      },
                    )
                  : Dir(currentPath: '${widget.currentPath}$item', title: item)
          ],
        ),
      );

      body = ClipRect(
          child: SizeTransition(sizeFactor: animationController, child: body));

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [top, body],
      );
    });
  }
}
