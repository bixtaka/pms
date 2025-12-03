import 'package:flutter/material.dart';

/// 共通ガントバーの基底モデル
abstract class GanttBar {
  final DateTime start;
  final DateTime end; // 閉区間 [start, end]
  final Color color;
  final double radius;
  final double height;

  const GanttBar({
    required this.start,
    required this.end,
    required this.color,
    this.radius = 4,
    this.height = 12,
  });
}

/// 作業中（実績：進行中）
class ActualWorkingBar extends GanttBar {
  const ActualWorkingBar({
    required super.start,
    required super.end,
    Color color = const Color(0xFFF5A623),
    double radius = 6.0,
    double height = 12.0,
  }) : super(color: color, radius: radius, height: height);
}

/// 完了（実績：完了済み）
class ActualDoneBar extends GanttBar {
  const ActualDoneBar({
    required super.start,
    required super.end,
    Color color = const Color(0xFF4A90E2),
    double radius = 6.0,
    double height = 12.0,
  }) : super(color: color, radius: radius, height: height);
}

/// 計画バー（UI専用）
class PlanBar extends GanttBar {
  const PlanBar({
    required super.start,
    required super.end,
    Color color = const Color(0xFFBDBDBD),
    double radius = 4.0,
    double height = 6.0,
  }) : super(color: color, radius: radius, height: height);
}

/// 日次進捗の簡易入力
class DailyProgressEntry {
  final DateTime date;
  final int doneQty;
  final bool hasRecord;

  const DailyProgressEntry({
    required this.date,
    required this.doneQty,
    required this.hasRecord,
  });
}
