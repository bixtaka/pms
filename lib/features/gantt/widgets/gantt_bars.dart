import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../application/product_gantt_progress_service.dart';
import '../presentation/gantt_constants.dart';
import '../presentation/gantt_utils.dart';

/// 計画バー（予定期間を表すボーダーのみのバー）
/// 実績バーと区別しやすいように、塗りつぶしではなくボーダーのみ表示
class GanttPlannedBar extends StatelessWidget {
  final double width;
  final Color color;

  const GanttPlannedBar({
    super.key,
    required this.width,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: kGanttPlannedBarHeight,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(kGanttPlannedBarRadius),
        border: kGanttPlannedBarBorderWidth > 0
            ? Border.all(
                color: kGanttPlannedBarBorderColor,
                width: kGanttPlannedBarBorderWidth,
              )
            : null,
      ),
    );
  }
}

/// 実績バー（実際の進捗を表す太いバー）
class GanttActualBar extends StatelessWidget {
  final ProductGanttBar bar;
  final DateTime startDate;
  final int totalDays;
  final double dayWidth;
  final double rowHeight;

  const GanttActualBar({
    super.key,
    required this.bar,
    required this.startDate,
    required this.totalDays,
    required this.dayWidth,
    required this.rowHeight,
  });

  @override
  Widget build(BuildContext context) {
    final geo = computeRangeGeometry(
      rangeStart: bar.startDate,
      rangeEnd: bar.endDate,
      startDate: startDate,
      totalDays: totalDays,
      dayWidth: dayWidth,
    );
    if (geo == null) return const SizedBox.shrink();
    if (bar.status == GanttBarStatus.notStarted) return const SizedBox.shrink();

    final color = bar.status == GanttBarStatus.done
        ? kGanttActualDoneColor
        : kGanttActualInProgressColor;
    final double minWidth = math.max(kGanttActualBarMinWidth, dayWidth * 0.8);
    final double rawWidth = geo.width;
    final double width = rawWidth < minWidth ? minWidth : rawWidth;
    final double left =
        rawWidth < minWidth ? geo.left - (minWidth - rawWidth) / 2 : geo.left;

    return Positioned(
      left: left,
      // 計画バーの高さが24px, 実績バーが12pxなので、差分12px。
      // (rowHeight - kGanttActualBarHeight) / 2 で中央寄せされるが、
      // 計画バーも中央寄せされている前提で、計画バーの内部に収まるように同じく中央寄せで良い。
      top: (rowHeight - kGanttActualBarHeight) / 2,
      child: Container(
        width: width,
        height: kGanttActualBarHeight,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(kGanttActualBarRadius),
          // ボーダー廃止（シンプルでモダンな見た目へ）
        ),
      ),
    );
  }
}

/// 今日の日付を示す縦線
class GanttTodayLine extends StatelessWidget {
  final DateTime startDate;
  final int totalDays;
  final double dayWidth;
  final Color? color;
  final double lineWidth;

  const GanttTodayLine({
    super.key,
    required this.startDate,
    required this.totalDays,
    required this.dayWidth,
    this.color,
    this.lineWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayBase = DateTime(today.year, today.month, today.day);
    final offset = todayBase.difference(startDate).inDays;
    if (offset < 0 || offset >= totalDays) {
      return const SizedBox.shrink();
    }
    final lineColor = color ?? Colors.red.withValues(alpha: 0.6);
    return Positioned(
      left: offset * dayWidth,
      top: 0,
      bottom: 0,
      child: Container(width: lineWidth, color: lineColor),
    );
  }
}

/// 予定完了日の縦ライン（行内のみ）
class GanttPlannedEndLine extends StatelessWidget {
  final DateTime? plannedEnd;
  final double progress;
  final DateTime startDate;
  final int totalDays;
  final double dayWidth;
  final double rowHeight;

  const GanttPlannedEndLine({
    super.key,
    required this.plannedEnd,
    required this.progress,
    required this.startDate,
    required this.totalDays,
    required this.dayWidth,
    required this.rowHeight,
  });

  @override
  Widget build(BuildContext context) {
    if (plannedEnd == null) return const SizedBox.shrink();

    final startBase = DateTime(startDate.year, startDate.month, startDate.day);
    final endBase = DateTime(plannedEnd!.year, plannedEnd!.month, plannedEnd!.day);
    final offset = endBase.difference(startBase).inDays;

    if (offset < 0 || offset >= totalDays) {
      return const SizedBox.shrink();
    }

    final lineColor = _plannedLineColor();
    return Positioned(
      left: (offset + 0.5) * dayWidth,
      top: 4,
      child: Container(
        width: 2,
        height: rowHeight - 8,
        decoration: BoxDecoration(
          color: lineColor,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  Color _plannedLineColor() {
    final now = DateTime.now();
    final todayBase = DateTime(now.year, now.month, now.day);
    final endBase = plannedEnd != null
        ? DateTime(plannedEnd!.year, plannedEnd!.month, plannedEnd!.day)
        : null;

    if (progress >= 1.0) {
      // 完了済み
      return Colors.green.withValues(alpha: 0.7);
    }
    if (endBase != null && endBase.isBefore(todayBase)) {
      // 予定超過
      return Colors.red.withValues(alpha: 0.7);
    }
    // 予定内
    return Colors.grey.withValues(alpha: 0.5);
  }
}
