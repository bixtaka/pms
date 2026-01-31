import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/gantt_models.dart';
import '../presentation/gantt_constants.dart';
import '../presentation/group_plan_offset.dart';

/// ガントチャート画面の状態を管理するNotifier
/// 
/// 日付スケール、ズームレベル、展開状態、表示範囲などを管理。
class GanttScreenStateNotifier extends ChangeNotifier {
  /// 現在の表示モード（製品別/工種別）
  GanttViewMode viewMode = GanttViewMode.byProcess;
  
  /// 製品別ビューのサブモード
  ProductViewMode productViewMode = ProductViewMode.schedule;
  
  /// 日付スケール（日/週/2週/月）
  GanttDateScale dateScale = GanttDateScale.month;
  
  /// 日ビューのズームインデックス（0:標準, 1:中, 2:最大）
  int dayZoomIndex = 0;
  
  /// 日ビュー用のセル幅
  double dayCellWidth = kGanttDayZoomLevels[0];
  
  /// 週/2週/月ビュー用の基準幅
  double scaleDayWidth = kGanttMinScaleDayWidth;
  
  /// 表示開始日
  DateTime startDate = DateTime.now().subtract(const Duration(days: 3));
  
  /// 表示終了日
  DateTime endDate = DateTime.now().add(const Duration(days: 14));
  
  /// 展開中の製品ID
  final Set<String> expandedProductIds = <String>{};
  
  /// グループの展開状態
  final Map<String, bool> groupExpanded = {};
  
  /// 工程グループの計画バーオフセット
  final Map<String, GroupPlanOffset> groupPlanOffsets = {};
  
  /// キーワードフィルタ
  String keyword = '';

  /// 現在の日幅を取得
  double get dayWidth {
    switch (dateScale) {
      case GanttDateScale.day:
        return dayCellWidth;
      case GanttDateScale.week:
      case GanttDateScale.twoWeeks:
      case GanttDateScale.month:
        return scaleDayWidth;
    }
  }

  /// 日ビューかどうか
  bool get isDayView => dateScale == GanttDateScale.day;

  /// 表示日数
  int get totalDays {
    final displayEnd = displayEndDate;
    final displayStart = displayStartDate;
    return displayEnd.difference(displayStart).inDays + 1;
  }

  /// 表示開始日（パディング込み）
  DateTime get displayStartDate {
    if (isDayView) {
      return startDate;
    }
    return startDate.subtract(const Duration(days: kTimelinePaddingDaysBefore));
  }

  /// 表示終了日（パディング込み）
  DateTime get displayEndDate {
    if (isDayView) {
      return _getDayViewDisplayEnd();
    }
    return endDate.add(const Duration(days: kTimelinePaddingDaysAfter));
  }

  DateTime _getDayViewDisplayEnd() {
    const int kZoom1Days = 45;
    const int kZoom2Days = 35;
    
    if (dayZoomIndex == 0) {
      return endDate.add(const Duration(days: kDayViewPaddingAfterDays));
    }
    if (dayZoomIndex == 1) {
      return startDate.add(const Duration(days: kZoom1Days));
    }
    return startDate.add(const Duration(days: kZoom2Days));
  }

  /// グループが展開されているかどうか
  bool isGroupExpanded(String groupId) => groupExpanded[groupId] ?? false;

  /// グループの展開状態をトグル
  void toggleGroupExpanded(String groupId) {
    final current = groupExpanded[groupId] ?? false;
    groupExpanded[groupId] = !current;
    notifyListeners();
  }

  /// 製品の展開状態をトグル
  void toggleProductExpanded(String productId) {
    if (expandedProductIds.contains(productId)) {
      expandedProductIds.remove(productId);
    } else {
      expandedProductIds.add(productId);
    }
    notifyListeners();
  }

  /// 製品が展開されているかどうか
  bool isProductExpanded(String productId) => 
      expandedProductIds.contains(productId);

  /// 表示モードを設定
  void setViewMode(GanttViewMode mode) {
    if (viewMode != mode) {
      viewMode = mode;
      notifyListeners();
    }
  }

  /// 日付スケールを設定
  void setDateScale(GanttDateScale scale) {
    if (dateScale != scale) {
      dateScale = scale;
      notifyListeners();
    }
  }

  /// 日ビューをズームイン
  void zoomInDayWidth() {
    if (dayZoomIndex < kGanttDayZoomLevels.length - 1) {
      dayZoomIndex++;
      dayCellWidth = kGanttDayZoomLevels[dayZoomIndex];
      notifyListeners();
    }
  }

  /// 日ビューをズームアウト
  void zoomOutDayWidth() {
    if (dayZoomIndex > 0) {
      dayZoomIndex--;
      dayCellWidth = kGanttDayZoomLevels[dayZoomIndex];
      notifyListeners();
    }
  }

  /// スケールビューをズームイン
  void zoomInScaleWidth() {
    if (scaleDayWidth < kGanttMaxScaleDayWidth) {
      scaleDayWidth = (scaleDayWidth + 4).clamp(kGanttMinScaleDayWidth, kGanttMaxScaleDayWidth);
      notifyListeners();
    }
  }

  /// スケールビューをズームアウト
  void zoomOutScaleWidth() {
    if (scaleDayWidth > kGanttMinScaleDayWidth) {
      scaleDayWidth = (scaleDayWidth - 4).clamp(kGanttMinScaleDayWidth, kGanttMaxScaleDayWidth);
      notifyListeners();
    }
  }

  /// 日付範囲を更新
  void updateDateRange(DateTime newStart, DateTime newEnd) {
    startDate = newStart;
    endDate = newEnd;
    notifyListeners();
  }

  /// キーワードフィルタを設定
  void setKeyword(String value) {
    if (keyword != value) {
      keyword = value;
      notifyListeners();
    }
  }

  /// 製品ビューモードを設定
  void setProductViewMode(ProductViewMode mode) {
    if (productViewMode != mode) {
      productViewMode = mode;
      notifyListeners();
    }
  }
}

/// ガントチャート状態のProvider
final ganttScreenStateProvider = ChangeNotifierProvider.autoDispose<GanttScreenStateNotifier>((ref) {
  return GanttScreenStateNotifier();
});
