import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_nop/flutter_nop.dart';

import '../../../_router/routes.dart';

class TextParser {
  TextParser({this.getData, required void Function(String item) this.onTap});
  TextParser._() : getData = null;

  final String Function(String item)? getData;

  void Function(String item)? onTap;

  static final none = TextParser._();

  bool Function()? showEnabledFn;

  static final _reg =
      RegExp('(<.*?>)(.*?)</font>', multiLine: true, dotAll: true);

  static final _regBold =
      RegExp('\\*\\*(.*)\\*\\*', multiLine: true, dotAll: true);

  TextSpan parseStyle(String text) {
    final matchs = _reg.allMatches(text);
    final spans = <TextSpan>[];

    var start = 0;

    for (var match in matchs) {
      final value = match[1]!;
      final end = match.end;

      if (start < match.start) {
        final current = text.substring(start, match.start);
        spans.add(_parseLink(current, null));
      }

      final color = switch (value) {
        '<font color="red">' => Colors.red,
        '<font color="sky blue">' => Colors.lightBlue,
        '<font color="orange">' => Colors.orange,
        '<font color="#ffc000">' => const Color(0x00ffc000),
        _ => null,
      };

      final current = match[2]!;

      spans.add(_parseBold(color, current));

      start = end;
    }
    if (start < text.length) {
      final current = text.substring(start);
      spans.add(_parseLink(current, null));
    }
    return TextSpan(children: spans);
  }

  TextSpan _parseBold(Color? color, String text) {
    final bolds = _regBold.allMatches(text);
    if (bolds.isEmpty) {
      return _parseLink(text, TextStyle(color: color));
    } else {
      final children = <TextSpan>[];
      var start = 0;
      final style = TextStyle(fontWeight: FontWeight.bold, color: color);
      for (var match in bolds) {
        final value = match[1]!;
        final end = match.end;

        if (start < match.start) {
          final current = text.substring(start, match.start);
          children.add(_parseLink(current, null));
        }
        children.add(_parseLink(value, style));
        start = end;
      }

      if (start < text.length) {
        final current = text.substring(start);
        children.add(_parseLink(current, null));
      }
      return TextSpan(children: children);
    }
  }

  static final _regLink =
      RegExp('\\[\\[(.*?)\\]\\]', multiLine: true, dotAll: true);

  OverlayMixinDelegate? delegate;

  TextSpan _parseLink(String text, TextStyle? style) {
    final matchs = _regLink.allMatches(text);
    if (matchs.isEmpty) return TextSpan(text: text, style: style);
    final children = <TextSpan>[];

    var start = 0;

    const color = Color.fromARGB(255, 95, 34, 200);
    style = const TextStyle(color: color, fontWeight: FontWeight.w600);

    for (var match in matchs) {
      final value = match[1]!;
      final end = match.end;
      if (start < match.start) {
        var current = text.substring(start, match.start);
        if (current.startsWith('\n')) {
          current = ' $current';
        }
        children.add(TextSpan(text: current));
      }

      if (getData == null) {
        children.add(
          TextSpan(
            text: value,
            style: style,
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                if (onTap != null) {
                  onTap!(value);
                }
              },
          ),
        );
      } else {
        Widget? content;
        Timer? cancelTimer;

        OverlayMixinDelegate? currentDelegate;

        bool hover = false;

        void cancel() {
          cancelTimer?.cancel();
          hover = true;
          currentDelegate?.show();
        }

        bool enter = false;
        void onExit() {
          cancelTimer?.cancel();
          enter = false;
          if (currentDelegate?.active == false) {
            currentDelegate!.close();
            currentDelegate = null;
            delegate = null;
            return;
          }

          cancelTimer = Timer(const Duration(milliseconds: 400), () {
            if (hover) return;

            final current = currentDelegate;

            if (current?.closed == true) {
              currentDelegate = null;
              return;
            }

            current?.hide().whenComplete(() {
              if (hover) return;
              if (current.closed || current.showStatus) return;
              if (current == delegate) {
                delegate = null;
              }
              current.close();
            });
          });
        }

        void onEnter(PointerEnterEvent event) {
          if (content == null) {
            final data = getData!(value);
            if (data.isEmpty) return;

            final span = none.parseStyle(data);
            final jump = onTap;
            if (jump != null) {
              none.onTap = (value) {
                jump(value);
                delegate?.close();
                delegate = null;
              };
            }

            content = SingleChildScrollView(
              key: ValueKey(data),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
              child: Text.rich(span),
            );
            content = SelectionArea(child: content!);

            content = Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              child: content,
            );

            content = MouseRegion(
              onEnter: (p) {
                cancel();
              },
              onExit: (_) {
                hover = false;
                onExit();
              },
              child: content,
            );
          }

          cancelTimer?.cancel();

          if (currentDelegate == null || currentDelegate?.closed == true) {
            currentDelegate = getDelegate(content!, event.position);
          }

          if (delegate != null && delegate != currentDelegate) {
            delegate!.close();
          }

          currentDelegate!.show();
          delegate = currentDelegate;
        }

        bool scheduled = false;

        bool ignore = false;
        void loopEnter(PointerEnterEvent event) {
          final enabled = showEnabledFn?.call() ?? true;

          enter = true;
          if (!enabled) {
            ignore = false;
            if (scheduled) return;

            SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
              if (!enter) return;
              scheduled = false;
              if (ignore) return;
              loopEnter(event);
            });
            scheduled = true;
            return;
          }
          ignore = true;
          onEnter(event);
        }

        final textSpan = TextSpan(
          text: value,
          style: style,
          mouseCursor: SystemMouseCursors.click,
          onEnter: loopEnter,
          onExit: (p) => onExit(),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              if (onTap != null) {
                currentDelegate?.close();
                currentDelegate = null;
                delegate = null;
                onTap!(value);
              }
            },
        );

        children.add(textSpan);
      }
      start = end;
    }
    if (start < text.length) {
      var current = text.substring(start);

      if (current.startsWith('\n')) {
        current = current.replaceAll(RegExp('\n+'), '');
        current = ' $current';
      }
      children.add(TextSpan(text: current));
    }
    return TextSpan(children: children);
  }

  OverlayMixinDelegate<OverlayMixin>? getDelegate(
      Widget content, Offset position) {
    late final OverlayVerticalPannels pannels;
    pannels = OverlayVerticalPannels(builders: [
      (context) {
        final data = MediaQuery.of(context);
        final size = data.size;

        Widget child = GestureDetector(
          onTap: () {},
          child: FadeTransition(
            opacity: pannels.controller,
            child: content,
          ),
        );

        var dx = position.dx;
        final dy = position.dy;

        var right = 20.0;
        var left = dx - 8;
        Alignment alignment = Alignment.topLeft;

        final closedRight = dx >= size.width / 2;
        final closedBottom = dy >= size.height * 2 / 3;
        if (closedRight) {
          left = 8;
          alignment = Alignment.topRight;
          right = size.width - dx + 5;
        }
        var top = dy;
        var bottom = 20.0;
        if (closedBottom) {
          if (closedRight) {
            alignment = Alignment.bottomRight;
          } else {
            alignment = Alignment.bottomLeft;
          }

          bottom = size.height - dy + 5;
          top = 20;
        }

        child = Container(
          alignment: alignment,
          child: child,
        );
        child = Positioned(
          left: left,
          top: top,
          right: right,
          bottom: bottom,
          child: child,
        );
        // }

        return Stack(
          children: [child],
        );
      }
    ]);

    final delegate = OverlayMixinDelegate(
        pannels, const Duration(milliseconds: 220),
        delayDuration: const Duration(milliseconds: 300));

    delegate.overlay = OverlayObserverState(overlayGetter: () {
      return router.routerDelegate.navigatorKey.currentState?.overlay;
    });
    return delegate;
  }
}
