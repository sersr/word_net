import 'package:flutter/material.dart';
import 'package:flutter_nop/change_notifier.dart';
import 'package:flutter_nop/router.dart';
import 'package:nop/utils.dart';
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

            return Dir(currentPath: item, title: item);
          },
          itemCount: indexs.length,
        );

        Widget divider = Cs(() {
          return MouseRegion(
            cursor: _cursor.value,
            child: const VerticalDivider(width: 8, thickness: 3),
          );
        });

        divider = GestureDetector(
          onHorizontalDragUpdate: onUpdate,
          onHorizontalDragCancel: onCancel,
          onHorizontalDragEnd: onEnd,
          onHorizontalDragStart: onStart,
          child: divider,
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Cs(() => SizedBox(width: barWidth.value, child: left)),
            divider,
            const Expanded(child: _Body()),
          ],
        );
      }),
    );
  }

  final barWidth = 200.0.cs;

  final _cursor = SystemMouseCursors.grab.cs;

  double _rawOffset = 200;

  void onUpdate(DragUpdateDetails details) {
    final delta = details.primaryDelta ?? 0.0;
    _rawOffset = _rawOffset + delta;
    barWidth.value = _rawOffset.maxThan(100);
  }

  void onCancel() {
    _cursor.value = SystemMouseCursors.grab;
  }

  void onEnd(DragEndDetails details) {
    _cursor.value = SystemMouseCursors.grab;
  }

  void onStart(DragStartDetails details) {
    _cursor.value = SystemMouseCursors.grabbing;
  }
}

class _Body extends StatelessWidget {
  const _Body();
  @override
  Widget build(BuildContext context) {
    final controller = context.grass<HomeProvider>();

    return Cs(() {
      final span = controller.state.bodyTextSpan.value;

      final data = controller.currentString;
      return SingleChildScrollView(
          key: ValueKey(data),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
          child: Text.rich(span));
    });
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
  late AutoListenNotifier<bool> display;
  late HomeProvider homeProvider;

  late AnimationController animationController;
  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 240));

    animationController.addStatusListener(_updateDisplayState);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    homeProvider = context.grass();
    display = homeProvider.state.getDisplay(widget.currentPath);
    if (!animationController.isAnimating && display.value) {
      animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant Dir oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentPath != oldWidget.currentPath) {
      homeProvider.state.remove(oldWidget.currentPath);
      display = homeProvider.state.getDisplay(widget.currentPath);
    }
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
    const displayStyle = TextStyle(color: Colors.blue, fontSize: 14.0);
    return Cs(() {
      final items = homeProvider.getItems(widget.currentPath);
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
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final item = items[index];

            if (homeProvider.isFile(item)) {
              return Cs(() {
                TextStyle? style;
                if (homeProvider.isCurrentSelected(item)) {
                  style = displayStyle;
                }

                return BaseButton(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(item, style: style),
                  ),
                  onTap: () {
                    homeProvider.onPressed(item);
                  },
                );
              });
            }

            return Dir(currentPath: '${widget.currentPath}$item', title: item);
          },
          itemCount: items.length,
        ),
      );

      body = SizeTransition(
        axisAlignment: -0.5,
        sizeFactor: animationController,
        child: body,
      );

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [top, body],
      );
    });
  }
}
