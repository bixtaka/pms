import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// ガントチャート用のユーティリティ関数とヘルパークラス
///
/// gantt_screen.dart から抽出したユーティリティ群。

/// 日付を日付部分のみに正規化
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// 日付セルビルダーの型定義
typedef DayCellBuilder = Widget Function(
  BuildContext context,
  DateTime date,
  int index,
);

/// 月のスパン（タイムラインヘッダー用）
class MonthSpan {
  final int month;
  final int startIndex;
  final int endIndex;

  const MonthSpan({
    required this.month,
    required this.startIndex,
    required this.endIndex,
  });

  int get length => endIndex - startIndex + 1;
}

/// バーの位置計算結果
class TaskGeometry {
  final double left;
  final double width;

  const TaskGeometry({required this.left, required this.width});
}

/// ステータスマトリクス用の製品表示モデル
class MatrixProduct {
  final String id;
  final String label;
  final String code;
  final String memberType;

  const MatrixProduct({
    required this.id,
    required this.label,
    required this.code,
    required this.memberType,
  });
}

/// ステータスマトリクス用の工程ステップ表示モデル
class MatrixStep {
  final String id;
  final String label;
  final String groupName;

  const MatrixStep({
    required this.id,
    required this.label,
    required this.groupName,
  });
}

/// 工程ヘッダーグループ（ステータスマトリクス用）
class ProcessHeaderGroup {
  final String groupName;
  final List<MatrixStep> steps;

  ProcessHeaderGroup({
    required this.groupName,
    required this.steps,
  });
}

/// デバッグ用のメインスクロールコントローラー作成
ScrollController createMainScrollController() {
  final controller = ScrollController();
  controller.addListener(() {
    debugPrint('[GANTT MAIN] offset=${controller.offset}');
  });
  return controller;
}

/// デバッグ用のヘッダースクロールコントローラー作成
ScrollController createHeaderScrollController() {
  final controller = ScrollController();
  controller.addListener(() {
    debugPrint('[GANTT HEADER] offset=${controller.offset}');
  });
  return controller;
}

/// タスクの期間をピクセル座標に変換
TaskGeometry? computeRangeGeometry({
  required DateTime? rangeStart,
  required DateTime? rangeEnd,
  required DateTime startDate,
  required int totalDays,
  required double dayWidth,
}) {
  if (rangeStart == null || rangeEnd == null) return null;
  final chartEnd = DateTime(startDate.year, startDate.month, startDate.day)
      .add(Duration(days: totalDays));

  // 完全に範囲外なら非表示
  if (rangeEnd.isBefore(startDate) || rangeStart.isAfter(chartEnd)) {
    return null;
  }

  // 表示範囲にクランプして「見える部分だけ」描画する
  final effectiveStart =
      rangeStart.isBefore(startDate) ? startDate : rangeStart;
  final effectiveEnd =
      rangeEnd.isAfter(chartEnd) ? chartEnd : rangeEnd;

  int startOffsetDays = effectiveStart.difference(startDate).inDays;
  int durationDays = effectiveEnd.difference(effectiveStart).inDays + 1;

  if (durationDays <= 0) return null;

  final left = startOffsetDays * dayWidth;
  final width = durationDays * dayWidth;
  return TaskGeometry(left: left, width: width);
}

/// 日付フォーマット (M/d)
String formatDateShort(DateTime d) => '${d.month}/${d.day}';

/// 最も近いズームインデックスを取得
int nearestDayZoomIndex(double width, List<double> zoomLevels) {
  var bestIndex = 0;
  var bestDiff = double.infinity;
  for (var i = 0; i < zoomLevels.length; i++) {
    final diff = (zoomLevels[i] - width).abs();
    if (diff < bestDiff) {
      bestDiff = diff;
      bestIndex = i;
    }
  }
  return bestIndex;
}
