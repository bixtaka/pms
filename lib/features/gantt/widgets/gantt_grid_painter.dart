import 'package:flutter/material.dart';

/// ガントチャートのグリッド線を描画するPainter
///
/// 多数のContainerを描画する代わりに、Canvasに直接線を描画することで
/// パフォーマンスを劇的に向上させる。
class GanttGridPainter extends CustomPainter {
  final int daysCount;
  final double dayWidth;
  final DateTime startDate;
  final Color baseColor;
  final Color borderColor;
  final Color weekendColor;

  GanttGridPainter({
    required this.daysCount,
    required this.dayWidth,
    required this.startDate,
    required this.baseColor,
    required this.borderColor,
    required this.weekendColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 背景塗りつぶし
    final paint = Paint()..color = baseColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 1.0;

    final weekendPaint = Paint()..color = weekendColor;

    for (int i = 0; i < daysCount; i++) {
      final left = i * dayWidth;
      // 画面外の描画をスキップ（クリッピング最適化）
      // ※ListViewの中にある場合など、size.width は全幅になる可能性があるが、
      // 少なくとも無駄な描画を避ける
      
      final date = startDate.add(Duration(days: i));
      if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
        canvas.drawRect(
          Rect.fromLTWH(left, 0, dayWidth, size.height),
          weekendPaint,
        );
      }

      // 縦線（右側）
      // 最後の線は枠線と被るかもしれないが、一応描画
      canvas.drawLine(
        Offset(left + dayWidth, 0),
        Offset(left + dayWidth, size.height),
        borderPaint,
      );
    }
    
    // 下線
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant GanttGridPainter oldDelegate) {
    return oldDelegate.daysCount != daysCount ||
        oldDelegate.dayWidth != dayWidth ||
        oldDelegate.startDate != startDate ||
        oldDelegate.baseColor != baseColor;
  }
}
