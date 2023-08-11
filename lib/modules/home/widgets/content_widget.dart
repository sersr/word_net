import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_nop/flutter_nop.dart';
import 'package:flutter_nop/router.dart';
import 'package:word_net/modules/widgets/init_once_mixin.dart';

import '../../utils/overlay_delegate.dart';
import '../../widgets/button.dart';
import '../providers/provider.dart';

class ContentBody extends StatefulWidget {
  const ContentBody({super.key});

  @override
  State<ContentBody> createState() => _ContentBodyState();
}

class _ContentBodyState extends State<ContentBody> {
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

    controller.parser.getText = getText;

    if (!_init) {
      SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
        _init = true;
      });
    }
  }

  bool _init = false;
  final _key = GlobalKey();

  RenderParagraph? getText() {
    if (!_init) return null;
    if (!mounted) return null;

    final textContext = _key.currentContext;

    // // 不使用 RichText, Text多了一些配置，所以找到的第一个 renderObject 并不是 RenderParagraph
    // final box = textContext?.findRenderObject();
    // if (box is RenderParagraph) {
    //   return box;
    // }
    RenderParagraph? paragraph;

    void vistor(BuildContext element) {
      if (paragraph != null) return;
      element.visitChildElements((element) {
        if (paragraph != null) return;
        final text = element.findRenderObject();
        if (text is RenderParagraph) {
          paragraph = text;
          return;
        }

        vistor(element);
      });
    }

    if (textContext != null) {
      vistor(textContext);
    }

    return paragraph;
  }

  @override
  void dispose() {
    controller.parser.showEnabledFn = null;
    if (controller.parser.getText == getText) {
      controller.parser.getText = null;
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = Cs(() {
      final span = controller.state.bodyTextSpan.value;

      final data = controller.currentString;

      final child = SingleChildScrollView(
        controller: scrollController,
        key: ValueKey(data),
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 16.0),
        child: Text.rich(key: _key, span),
      );

      return SizedBox.expand(child: SelectionArea(child: child));
    });

    final path = Cs(() {
      final currentPath = controller.state.currentPath.value.value;

      final currentSelected = controller.state.currentSelected.value;
      if (currentPath.isEmpty && currentSelected.isEmpty) {
        return const SizedBox();
      }

      final children = <Widget>[];

      final it = currentPath.iterator;
      const slashStyle = TextStyle(fontSize: 12, color: Colors.grey);

      final parent = <String>[];
      if (it.moveNext()) {
        children.add(PartPath(paths: const [], title: it.current));

        parent.add(it.current);
      }

      while (it.moveNext()) {
        final current = it.current;
        children.add(const Text('/', style: slashStyle));
        children.add(PartPath(paths: List.of(parent), title: current));
        parent.add(current);
      }

      if (currentSelected.isNotEmpty) {
        children.add(const Text('/', style: slashStyle));
        children.add(PartPath(paths: List.of(parent), title: currentSelected));
      }

      Widget child = Row(children: children);
      child = SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        scrollDirection: Axis.horizontal,
        child: child,
      );

      child = Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              offset: Offset(0, 2),
              color: Color.fromARGB(255, 234, 234, 234),
              blurRadius: 1,
            ),
          ],
          color: Color.fromARGB(255, 251, 251, 251),
        ),
        child: child,
      );
      return child;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Expanded(child: path)]),
        Expanded(child: body),
      ],
    );
  }
}

class PartPath extends StatefulWidget {
  const PartPath({super.key, required this.paths, required this.title});
  final String title;
  final List<String> paths;

  @override
  State<PartPath> createState() => _PartPathState();
}

class _PartPathState extends State<PartPath> with InitOnceMixin {
  final _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    GestureBinding.instance.pointerRouter.addGlobalRoute(_handlePointerEvent);
  }

  late HomeProvider homeProvider;
  @override
  void initOnce() {
    homeProvider = context.grass();
  }

  @override
  void dispose() {
    current?.close();
    current = null;
    GestureBinding.instance.pointerRouter
        .removeGlobalRoute(_handlePointerEvent);
    super.dispose();
  }

  static OverlayMixinDelegate? delegate;
  OverlayMixinDelegate? current;

  void _handlePointerEvent(PointerEvent event) {
    if (!_ignore && event is PointerDownEvent) {
      current?.close();
      current = null;
    }
  }

  bool _ignore = false;
  void show() {
    if (!mounted) return;
    if (current == null || current?.closed == true) {
      delegate?.close();

      final box = _key.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) return;

      final offset = box.localToGlobal(Offset.zero);

      Widget content;
      if (widget.paths.isEmpty) {
        content = Cs(() {
          final indexs = homeProvider.indexs;

          if (indexs.isEmpty) return const SizedBox();

          return CustomScrollView(
            slivers: [
              for (var index in indexs)
                SliverToBoxAdapter(child: Dir(title: index)),
            ],
          );
        });
      } else {
        content = Dir.scrollable(title: widget.title, paths: widget.paths);
      }

      content = Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
        child: content,
      );

      content = Listener(
        onPointerDown: (_) {
          _ignore = true;
        },
        onPointerCancel: (_) {
          _ignore = false;
        },
        onPointerUp: (_) {
          _ignore = false;
        },
        child: content,
      );

      content = MouseRegion(
        onEnter: (_) {
          _ignore = true;
        },
        onExit: (_) {
          _ignore = false;
        },
        child: content,
      );

      current = getDelegate(content, offset, box.size.height, box.size.width,
          delay: Duration.zero, getOverlay: () {
        if (!mounted) return null;
        return Overlay.maybeOf(context);
      });
    }

    current!.show();
    delegate = current;
  }

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 12, color: Colors.lightBlue);

    Widget child = Text(key: _key, widget.title, style: style);

    child = GestureDetector(onTap: show, child: child);

    child = MouseRegion(cursor: SystemMouseCursors.click, child: child);
    return child;
  }
}

class Dir extends StatefulWidget {
  Dir({
    super.key,
    required this.title,
  })  : paths = [title],
        isScrollable = false;

  const Dir._paths({
    required this.title,
    required this.paths,
  }) : isScrollable = false;
  const Dir.scrollable({
    super.key,
    required this.title,
    required this.paths,
  }) : isScrollable = true;

  final String title;
  final List<String> paths;

  final bool isScrollable;

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
    final newDisplay = homeProvider.state.getDisplay(widget.paths);
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
      homeProvider.state.remove(oldWidget.paths);
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
      final items = homeProvider.getItems(widget.paths);
      final style =
          homeProvider.inSelectedTree(widget.paths) ? displayStyle : null;
      Widget top = BaseButton(
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 8.0, bottom: 8.0),
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

      if (!display.value && !widget.isScrollable) {
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
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics:
              widget.isScrollable ? null : const NeverScrollableScrollPhysics(),
          itemBuilder: itemBuilder,
          itemCount: items.length,
        ),
      );

      if (!widget.isScrollable) {
        body = SizeTransition(
          axisAlignment: -0.5,
          sizeFactor: animationController,
          child: body,
        );
      }

      if (widget.isScrollable) {
        return body;
      }

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
          final path = _PartPathState.delegate;
          if (path != null && !path.closed) {
            path.close();
            _PartPathState.delegate = null;
            homeProvider.jump(widget.item);
          } else {
            homeProvider.onPressed(widget.item);
          }
          homeProvider.updatePath(widget.paths);
        },
      );
    });
  }
}
