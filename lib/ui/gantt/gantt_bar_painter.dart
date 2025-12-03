import 'package:flutter/material.dart';

import 'gantt_bar_models.dart';

/// 単一のガントバーを描画する CustomPainter。
class GanttBarPainter extends CustomPainter {
  final GanttBar bar;
  final DateTime chartStart;
  final double dayWidth;

  GanttBarPainter({
    required this.bar,
    required this.chartStart,
    required this.dayWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = bar.color.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    final startOffset = bar.start.difference(chartStart).inDays * dayWidth;
    final endOffset =
        bar.end.difference(chartStart).inDays * dayWidth + dayWidth;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        startOffset,
        0,
        endOffset - startOffset,
        bar.height,
      ),
      Radius.circular(bar.radius),
    );

    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant GanttBarPainter oldDelegate) {
    return oldDelegate.bar != bar ||
        oldDelegate.dayWidth != dayWidth ||
        oldDelegate.chartStart != chartStart;
  }
}
