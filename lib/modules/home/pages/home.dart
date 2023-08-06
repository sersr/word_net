import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
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
        title: const Text('基础汉英类义词典'),
      ),
      body: Cs(() {
        final indexs = provider.indexs;

        if (indexs.isEmpty) return const SizedBox();

        final left = CustomScrollView(
          slivers: [
            for (var index in indexs)
              SliverToBoxAdapter(child: Dir(title: index)),
          ],
        );
        // final left = ListView.builder(
        //   itemBuilder: (context, index) {
        //     final item = indexs[index];

        //     return Dir(title: item);
        //   },
        //   itemCount: indexs.length,
        // );

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

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final scrollController = ScrollController();
  late HomeProvider controller;

  bool _enabled() {
    assert(mounted);

    if (scrollController.hasClients) {
      final position = scrollController.position;
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      return position.activity!.velocity == 0;
    }

    return true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    controller = context.grass();
    controller.parser.showEnabledFn = _enabled;
  }

  @override
  void dispose() {
    controller.parser.showEnabledFn = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Cs(() {
      final span = controller.state.bodyTextSpan.value;

      final data = controller.currentString;

      final child = SingleChildScrollView(
          controller: scrollController,
          key: ValueKey(data),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
          child: Text.rich(span));

      return SelectionArea(child: child);
    });
  }
}

class Dir extends StatefulWidget {
  Dir({
    super.key,
    required this.title,
  }) : paths = [title];

  const Dir._paths({
    required this.title,
    required this.paths,
  });

  final String title;
  final List<String> paths;

  String get currentPath => paths.join('');

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
    _updateDisplay();
  }

  bool _init = false;
  void _updateDisplay() {
    final newDisplay = homeProvider.state.getDisplay(widget.currentPath);
    if (!_init) {
      _init = true;
      newDisplay.addListener(_listener);
      display = newDisplay;
      _listener();
      return;
    }
    if (display != newDisplay) {
      display.removeListener(_listener);
      newDisplay.addListener(_listener);
      display = newDisplay;
      _listener();
    }
  }

  void _listener() {
    if (!animationController.isAnimating) {
      animationController.value = display.value ? 1.0 : 0.0;
    }
  }

  @override
  void didUpdateWidget(covariant Dir oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!const DeepCollectionEquality().equals(widget.paths, oldWidget.paths)) {
      homeProvider.state.remove(oldWidget.currentPath);
      _updateDisplay();
    }
  }

  @override
  void dispose() {
    animationController.dispose();
    display.removeListener(_listener);
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
      final style =
          homeProvider.inSelectedTree(widget.paths) ? displayStyle : null;
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

      Widget itemBuilder(BuildContext context, int index) {
        final item = items[index];

        if (homeProvider.isFile(item)) {
          return IndexItem(
            item: item,
            style: style,
            paths: widget.paths,
          );
        }

        return Dir._paths(
          title: item,
          paths: [...widget.paths, item],
        );
      }

      Widget body = Padding(
        padding: const EdgeInsets.only(left: 16),
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: itemBuilder,
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

class IndexItem extends StatefulWidget {
  const IndexItem({
    super.key,
    required this.item,
    required this.style,
    required this.paths,
  });

  final String item;
  final TextStyle? style;
  final List<String> paths;

  @override
  State<IndexItem> createState() => _IndexItemState();
}

class _IndexItemState extends State<IndexItem> {
  late HomeProvider homeProvider;
  late AutoListenNotifier<String> currentSelected;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    homeProvider = context.grass();
    _update();
  }

  bool _init = false;
  void _update() {
    final newCurrent = homeProvider.state.currentSelected;
    if (!_init) {
      _init = true;
      newCurrent.addListener(_listener);
      currentSelected = newCurrent;
      _listener();
      return;
    }

    if (newCurrent != currentSelected) {
      currentSelected.removeListener(_listener);
      newCurrent.addListener(_listener);
      currentSelected = newCurrent;
    }
  }

  void _listener() {
    if (homeProvider.isCurrentSelected(widget.item) && !homeProvider.ignore) {
      SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
        if (!mounted || !homeProvider.isCurrentSelected(widget.item)) return;
        final renderObject = context.findRenderObject();
        RenderAbstractViewport.maybeOf(renderObject)
            ?.showOnScreen(descendant: renderObject);
      });
    }
  }

  @override
  void dispose() {
    currentSelected.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Cs(() {
      var style = widget.style;
      if (!homeProvider.isCurrentSelected(widget.item)) {
        style = null;
      }
      return BaseButton(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(widget.item, style: style),
        ),
        onTap: () {
          homeProvider.onPressed(widget.item);
          homeProvider.updatePath(widget.paths);
        },
      );
    });
  }
}
