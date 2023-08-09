import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_nop/flutter_nop.dart';

import '../../utils/overlay_delegate.dart';

class TextParser {
  TextParser({this.getData, required void Function(String item) this.onTap});
  TextParser._() : getData = null;

  final String Function(String item)? getData;

  void Function(String item)? onTap;

  RenderParagraph? Function()? getText;

  static final none = TextParser._();

  bool Function()? showEnabledFn;

  static final _reg =
      RegExp('(<.*?>)(.*?)</font>', multiLine: true, dotAll: true);

  static final _regBold =
      RegExp('\\*\\*(.*)\\*\\*', multiLine: true, dotAll: true);

  static int getTextSpanLength(TextSpan span) {
    var length = 0;
    if (span.text?.isNotEmpty == true) {
      length += span.text!.length;
    }
    if (span.children?.isNotEmpty == true) {
      for (var child in span.children!) {
        if (child is TextSpan) {
          length += getTextSpanLength(child);
        }
      }
    }
    return length;
  }

  TextSpan parseStyle(String text) {
    return runZoned(() {
      return _parseStyle(text);
    }, zoneValues: {'fullText': text});
  }

  TextSpan _parseStyle(String text) {
    final matchs = _reg.allMatches(text);
    final spans = <TextSpan>[];

    var start = 0;

    var textStart = 0;

    for (var match in matchs) {
      final value = match[1]!;
      final end = match.end;

      if (start < match.start) {
        final current = text.substring(start, match.start);
        final span = _parseLink(textStart, current, null);
        textStart += getTextSpanLength(span);
        spans.add(span);
      }

      final color = switch (value) {
        '<font color="red">' => Colors.red,
        '<font color="sky blue">' => Colors.lightBlue,
        '<font color="orange">' => Colors.orange,
        '<font color="#ffc000">' => const Color(0x00ffc000),
        _ => null,
      };

      final current = match[2]!;
      final span = _parseBold(textStart, color, current);
      textStart += getTextSpanLength(span);
      spans.add(span);
      start = end;
    }
    if (start < text.length) {
      final current = text.substring(start);
      final span = _parseLink(textStart, current, null);
      textStart += getTextSpanLength(span);
      spans.add(span);
    }
    return TextSpan(children: spans);
  }

  TextSpan _parseBold(int textStart, Color? color, String text) {
    final bolds = _regBold.allMatches(text);
    if (bolds.isEmpty) {
      return _parseLink(textStart, text, TextStyle(color: color));
    } else {
      final children = <TextSpan>[];
      var start = 0;
      final style = TextStyle(fontWeight: FontWeight.bold, color: color);
      for (var match in bolds) {
        final value = match[1]!;
        final end = match.end;

        if (start < match.start) {
          final current = text.substring(start, match.start);
          final span = _parseLink(textStart, current, null);
          textStart += getTextSpanLength(span);
          children.add(span);
        }
        final span = _parseLink(textStart, value, style);
        textStart += getTextSpanLength(span);
        children.add(span);
        start = end;
      }

      if (start < text.length) {
        final current = text.substring(start);
        final span = _parseLink(textStart, current, null);
        textStart += getTextSpanLength(span);
        children.add(span);
      }
      return TextSpan(children: children);
    }
  }

  static final _regLink =
      RegExp('\\[\\[(.*?)\\]\\]', multiLine: true, dotAll: true);

  OverlayMixinDelegate? delegate;

  TextSpan _parseLink(int textStart, String text, TextStyle? style) {
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
        textStart += current.length;
        children.add(TextSpan(text: current));
      }
      final localStart = textStart;

      textStart += value.length;
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
            final text = getText?.call();
            var offset = event.position;
            var height = 0.0;
            var width = 0.0;
            if (text != null) {
              final textPosition = TextPosition(offset: localStart);

              final textPositionEnd =
                  TextPosition(offset: localStart + value.length);

              final textOffset =
                  text.getOffsetForCaret(textPosition, Rect.zero);
              height = text.getFullHeightForCaret(textPosition) ?? 0;

              final endOffset =
                  text.getOffsetForCaret(textPositionEnd, Rect.zero);

              if (endOffset.dx < textOffset.dx) {
                width = text.size.width - textOffset.dx;
              } else {
                width = endOffset.dx - textOffset.dx;
              }

              offset = text.localToGlobal(textOffset);
            }

            currentDelegate = getDelegate(content!, offset, height, width);
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
}
