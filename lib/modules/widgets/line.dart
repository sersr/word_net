import 'package:flutter/material.dart';

/// 为视图添加尺寸刻度
class ScreenLine extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var start = 0.0;
    final painter = Paint()..color = Colors.cyan;
    const style = TextStyle(color: Colors.black);
    while (start < size.height) {
      canvas.drawRect(Rect.fromLTWH(0, start - 1, 10, 2), painter);
      final text = TextPainter(
        text: TextSpan(text: '$start', style: style),
        textDirection: TextDirection.ltr,
      );
      text.layout();
      final height = text.height;
      text.paint(canvas, Offset(12, start - 1 - height / 2));
      start += 50;
    }

    start = 0;
    while (start < size.width) {
      canvas.drawRect(Rect.fromLTWH(start - 1, 0, 2, 10), painter);
      final text = TextPainter(
        text: TextSpan(text: '$start', style: style),
        textDirection: TextDirection.ltr,
      );
      text.layout();
      final width = text.width;
      text.paint(canvas, Offset(start - 1 - width / 2, 12));
      start += 50;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
