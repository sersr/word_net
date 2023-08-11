import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_nop/flutter_nop.dart';
import 'package:flutter_nop/router.dart';
import 'package:word_net/modules/home/providers/provider.dart';
import 'package:word_net/modules/utils/overlay_delegate.dart';
import 'package:word_net/modules/widgets/button.dart';
import 'package:word_net/modules/widgets/init_once_mixin.dart';

class SearchWidget extends StatefulWidget {
  const SearchWidget({super.key});

  @override
  State<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget>
    with InitOnceMixin, WidgetsBindingObserver {
  OverlayMixinDelegate? delegate;

  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    GestureBinding.instance.pointerRouter.addGlobalRoute(_handlePointerEvent);
    WidgetsBinding.instance.addObserver(this);
  }

  late HomeProvider homeProvider;
  @override
  void initOnce() {
    homeProvider = context.grass();
  }

  @override
  void didChangeMetrics() {
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      final box = _key.currentContext?.findRenderObject();

      if (box is! RenderBox) return;
      final size = box.size;
      _width.value = size.width;
    });
  }

  @override
  void dispose() {
    delegate?.close();
    focusNode.dispose();

    GestureBinding.instance.pointerRouter
        .removeGlobalRoute(_handlePointerEvent);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool _ignore = false;

  void _setIgnore(bool value) {
    _ignore = value;
  }

  void _handlePointerEvent(PointerEvent event) {
    if (!_ignore && event is PointerDownEvent) {
      SchedulerBinding.instance.scheduleFrame();
      SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
        if (!focusNode.hasFocus && !_ignore) {
          delegate?.close();
          delegate = null;
        }
      });
    }
  }

  final editController = TextEditingController();

  final dataNotifier = ''.cs;

  final _width = 100.0.cs;

  final _key = GlobalKey();

  void searchContent() {
    final box = _key.currentContext?.findRenderObject();
    if (box is! RenderBox) return;
    final size = box.size;
    _width.value = size.width;

    final position = box.localToGlobal(Offset.zero);

    final text = editController.text;

    if (delegate == null || delegate?.closed == true) {
      Widget content = Cs(() {
        if (dataNotifier.value.isEmpty) return const SizedBox();
        final items = homeProvider.getFiles(dataNotifier.value);

        if (items.isEmpty) return const SizedBox();
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
          shrinkWrap: true,
          itemBuilder: (context, index) {
            final item = items[index];
            Widget child = Text(
              item,
              style: const TextStyle(
                color: Color.fromARGB(255, 69, 69, 69),
                fontSize: 14,
              ),
            );

            child = BaseButton(
              onTap: () {
                homeProvider.onSearchTap(item);
                delegate?.close();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: child,
              ),
            );
            return child;
          },
          itemCount: items.length,
        );
      });

      content = Material(
        color: const Color.fromARGB(255, 251, 251, 251),
        elevation: 5,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(15),
          bottom: Radius.circular(12),
        ),
        child: content,
      );

      content = Listener(
        onPointerDown: (_) {
          _setIgnore(true);
        },
        onPointerCancel: (_) {
          _setIgnore(false);
        },
        onPointerUp: (_) {
          _setIgnore(false);
        },
        child: content,
      );

      content = MouseRegion(
        onEnter: (_) {
          _setIgnore(true);
        },
        onExit: (_) {
          _setIgnore(false);
        },
        child: content,
      );
      final child = content;

      content = Cs(() {
        if (_width.value <= 0) return const SizedBox();
        return Container(
          width: _width.value,
          alignment: Alignment.topLeft,
          child: child,
        );
      });
      delegate = getDelegate(content, position, size.height, size.width,
          delay: Duration.zero, getOverlay: () {
        if (!mounted) return null;
        return Overlay.maybeOf(context);
      });
    }

    delegate!.show();
    dataNotifier.value = text;
  }

  @override
  Widget build(BuildContext context) {
    Widget logo = const Text(
      '基础汉英类义词典',
      style: TextStyle(color: Color.fromARGB(255, 37, 37, 37), fontSize: 18),
    );

    logo = Container(
      padding: const EdgeInsets.only(left: 8, right: 12),
      child: logo,
    );

    Widget search = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: const Text(
        '搜索',
        style: TextStyle(color: Colors.white),
      ),
    );

    search = SearchButton(
      onTap: () {
        focusNode.requestFocus();
        searchContent();
      },
      child: search,
    );

    Widget content = TextField(
      controller: editController,
      key: _key,
      focusNode: focusNode,
      onChanged: (_) {
        searchContent();
      },
      onSubmitted: (_) {
        searchContent();
      },
      onTap: () {
        searchContent();
      },
      cursorColor: const Color.fromARGB(220, 91, 91, 91),
      style:
          const TextStyle(color: Color.fromARGB(255, 50, 50, 52), fontSize: 15),
      decoration: InputDecoration(
        isCollapsed: true,
        hintText: '搜索词根',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 214, 214, 214),
          ),
          gapPadding: 0,
        ),
        focusColor: const Color.fromARGB(255, 214, 214, 214),
        contentPadding:
            const EdgeInsets.only(left: 12, right: 2, top: 6, bottom: 6),
        suffix: search,
        hintStyle: const TextStyle(
          color: Color.fromARGB(255, 7, 77, 86),
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
      ),
    );

    content = Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(right: 12),
      child: content,
    );

    return SizedBox(
      height: 60,
      child: Row(
        children: [logo, Expanded(child: content)],
      ),
    );
  }
}

class SearchItem extends StatelessWidget {
  const SearchItem({super.key, required this.item});
  final String item;
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
