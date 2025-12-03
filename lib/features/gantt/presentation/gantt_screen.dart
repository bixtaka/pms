import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/project.dart';
import '../../process_spec/domain/process_group.dart';
import '../../process_spec/domain/process_step.dart';
import '../../process_spec/presentation/process_colors.dart';
import '../application/gantt_providers.dart';
import '../application/product_gantt_progress_service.dart';
import '../../products/presentation/product_inspection_screen.dart';
import 'group_plan_offset.dart';

/// 工種種別
enum ProcessType { coreAssembly, coreWeld, jointAssembly, jointWeld, other }

/// 表示モード（製品別 / 工種別）
enum GanttViewMode { byProduct, byProcess }

/// ガントの横方向ズーム。日/週/月ボタンで切り替える。
/// day: 1日あたりの幅を広くして細かく見る（表示日数少なめ）
/// month: 幅を狭くして長期間を見る（表示日数多め）
enum GanttDateScale { day, week, month }

/// 計画バーのドラッグモード（スライド／左右リサイズ）
enum _DragMode { move, resizeLeft, resizeRight }

/// 製品別タブのビュー切り替え
enum ProductViewMode { schedule, processStatus }

/// 工程ステータスマトリクス用ステータス
enum ProcessCellStatus { notStarted, inProgress, done }

class _MatrixProduct {
  final String id;
  final String label;

  const _MatrixProduct({
    required this.id,
    required this.label,
  });
}

class _MatrixStep {
  final String id;
  final String label;
  final String groupName;

  const _MatrixStep({
    required this.id,
    required this.label,
    required this.groupName,
  });
}

class _ProcessHeaderGroup {
  final String groupName;
  final List<_MatrixStep> steps;

  _ProcessHeaderGroup({
    required this.groupName,
    required this.steps,
  });
}

/// 1タスク（工種）を表すモデル
class GanttTask {
  final String id;
  final String name;
  final ProcessType type;
  final DateTime start;
  final DateTime end;
  final double progress;
  // 製品全体の予定完了日（製品レベルの予定を工程にも共有する）
  final DateTime? plannedEnd;
  // SPEC の process_steps への紐付け（工程別ビューで使用）
  final String? stepId;
  final String? stepKey;
  final String? stepLabel;
  final int? stepSort;
  // SPEC の process_groups への紐付け（工程別ビューで使用）
  final String? processGroupId;
  final String? processGroupKey;
  final String? processGroupLabel;
  final int? processGroupSort;

  const GanttTask({
    required this.id,
    required this.name,
    required this.type,
    required this.start,
    required this.end,
    required this.progress,
    this.plannedEnd,
    this.stepId,
    this.stepKey,
    this.stepLabel,
    this.stepSort,
    this.processGroupId,
    this.processGroupKey,
    this.processGroupLabel,
    this.processGroupSort,
  });
}

/// 製品行モデル（複数タスクを内包）
class GanttProduct {
  final String id;
  final String code;
  final String name;
  final String memberType;
  final double progress;
  final int quantity;
  final List<GanttTask> tasks;

  const GanttProduct({
    required this.id,
    required this.code,
    required this.name,
    this.memberType = '',
    required this.progress,
    required this.quantity,
    required this.tasks,
  });
}

/// 行の種類：製品ヘッダ or タスク行
enum GanttRowKind { productHeader, taskRow }

/// 左ペイン／右タイムライン両方で使う行定義
class GanttRowEntry {
  final GanttRowKind kind;
  final GanttProduct product;
  final GanttTask? task;

  const GanttRowEntry.productHeader(this.product)
    : kind = GanttRowKind.productHeader,
      task = null;

  const GanttRowEntry.taskRow(this.product, this.task)
    : kind = GanttRowKind.taskRow;
}

// 工程別ビュー用の親子ツリー行モデル。
// 親: process_groups（一級の工程グループ。一次加工／コア部／…）
// 子: process_steps（各グループ配下の工程ステップ。切断／ショット／UT／…）
// ガント画面では、左ペイン・右ペインともにこの rows を使って
// 折りたたみ可能なツリー構造として表示する。
abstract class ProcessTreeRow {
  const ProcessTreeRow();
}

class ProcessGroupRow extends ProcessTreeRow {
  final String groupId;
  final String groupKey;
  final String label;
  final int sortOrder;
  final List<GanttTask> tasks; // そのグループに属する全タスク

  const ProcessGroupRow({
    required this.groupId,
    required this.groupKey,
    required this.label,
    required this.sortOrder,
    required this.tasks,
  });
}

class ProcessStepRow extends ProcessTreeRow {
  final String groupId;
  final String stepId;
  final String stepKey;
  final String label;
  final int sortOrder;
  final List<GanttTask> tasks; // そのステップに属するタスク

  const ProcessStepRow({
    required this.groupId,
    required this.stepId,
    required this.stepKey,
    required this.label,
    required this.sortOrder,
    required this.tasks,
  });
}

class ProcessVisibleRow {
  final bool isGroup;
  final ProcessGroupRow? groupRow;
  final ProcessStepRow? stepRow;

  const ProcessVisibleRow.group(this.groupRow)
      : isGroup = true,
        stepRow = null;

  const ProcessVisibleRow.step(this.stepRow)
      : isGroup = false,
        groupRow = null;
}

/// バーの位置計算結果
class _TaskGeometry {
  final double left;
  final double width;

  const _TaskGeometry({required this.left, required this.width});
}

// ガント行高さを左右で揃える共通定数
const double kGanttRowHeight = 44.0;
const double _leftPaneWidth = 280.0;
const double _processStepIndent = 24.0;
const List<double> _dayZoomLevels = [32.0, 48.0, 64.0];
const int _dayViewPaddingAfterDays = 21; // 日ビュー専用の表示余白（日数）
const int _timelinePaddingDaysBefore = 7;
const int _timelinePaddingDaysAfter = 7;
const int _timelineExtraScrollableDays = 14;
const double _miniMapDayWidth = 3.0;
const double _miniMapHeight = 40.0;
const Color kGanttPlannedBarColor = Color(0xFFCFD8DC);
const Color kGanttActualInProgressColor = Color(0xFFFFB300);
const Color kGanttActualDoneColor = Color(0xFF42A5F5);
const double kGanttPlannedBarHeight = 4.0;
const double kGanttActualBarHeight = 8.0;
const double kGanttPlannedBarRadius = 4.0;
const double kGanttActualBarRadius = 3.0;
const double kGanttActualBarMinWidth = 6.0;

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
typedef DayCellBuilder = Widget Function(
  BuildContext context,
  DateTime date,
  int index,
);

class _MonthSpan {
  final int month;
  final int startIndex;
  final int endIndex;

  const _MonthSpan({
    required this.month,
    required this.startIndex,
    required this.endIndex,
  });

  int get length => endIndex - startIndex + 1;
}

ScrollController _createMainScrollController() {
  final controller = ScrollController();
  controller.addListener(() {
    debugPrint('[GANTT MAIN] offset=${controller.offset}');
  });
  return controller;
}

ScrollController _createHeaderScrollController() {
  final controller = ScrollController();
  controller.addListener(() {
    debugPrint('[GANTT HEADER] offset=${controller.offset}');
  });
  return controller;
}

class GanttScreen extends ConsumerStatefulWidget {
  final Project project;

  const GanttScreen({super.key, required this.project});

  @override
  ConsumerState<GanttScreen> createState() => _GanttScreenState();
}

class _GanttScreenState extends ConsumerState<GanttScreen> {
  // タイムライン幅調整
  // 行高さは左リストと右ガントで共通化し、ズレを防ぐ
  static const double _rowHeight = kGanttRowHeight;
  static const double _timelineMonthRowHeight = 18;
  static const double _timelineDayRowHeight = 18;
  ProductViewMode _productViewMode = ProductViewMode.schedule;
  // 日付スケール
  GanttDateScale _dateScale = GanttDateScale.month;
  int _dayZoomIndex = 0; // 日ビューのズーム段階（0:標準,1:中,2:最大）
  double _dayCellWidth = _dayZoomLevels[0]; // 日ビュー用の可変セル幅（ズーム）

  double get _dayWidth {
    switch (_dateScale) {
      case GanttDateScale.day:
        return _dayCellWidth;
      case GanttDateScale.week:
        return 32;
      case GanttDateScale.month:
        return 16;
    }
  }

  bool get _isDayView => _dateScale == GanttDateScale.day;

  DateTime _getDayViewDisplayStart(int zoomIndex) {
    final d = _startDate;
    debugPrint(
      '[_getDayViewDisplayStart] zoomIndex=$zoomIndex, start=$d',
    );
    return d;
  }

  DateTime _getDayViewDisplayEnd(int zoomIndex) {
    const int kZoom1Days = 45;
    const int kZoom2Days = 35;

    // ズーム0（最小ズーム／縮小）は実データ全期間をベースに表示
    // 必要であれば UI 用に少しだけ先を見せる（余白）
    if (zoomIndex == 0) {
      final d = _endDate.add(
        const Duration(days: _dayViewPaddingAfterDays),
      );
      debugPrint(
        '[_getDayViewDisplayEnd] zoomIndex=0, end=$d (endDate=$_endDate, padding=$_dayViewPaddingAfterDays)',
      );
      return d;
    }

    if (zoomIndex == 1) {
      final d = _startDate.add(const Duration(days: kZoom1Days));
      debugPrint(
        '[_getDayViewDisplayEnd] zoomIndex=1, end=$d (start=$_startDate, +$kZoom1Days days)',
      );
      return d;
    }

    final d = _startDate.add(const Duration(days: kZoom2Days));
    debugPrint(
      '[_getDayViewDisplayEnd] zoomIndex>=2, end=$d (start=$_startDate, +$kZoom2Days days)',
    );
    return d;
  }

  DateTime _startDate = DateTime.now().subtract(
    const Duration(days: 3),
  ); // デフォルト
  DateTime _endDate = DateTime.now().add(const Duration(days: 14));
  int _totalDays = 18;
  DateTime get _displayStartDate {
    if (_isDayView) {
      return _getDayViewDisplayStart(_dayZoomIndex);
    }
    return _startDate.subtract(const Duration(days: _timelinePaddingDaysBefore));
  }

  DateTime get _displayEndDate {
    if (_isDayView) {
      return _getDayViewDisplayEnd(_dayZoomIndex);
    }
    return _endDate.add(const Duration(days: _timelinePaddingDaysAfter));
  }

  // スクロール同期用
  final ScrollController _leftScroll = ScrollController();
  final ScrollController _rightListScroll = ScrollController();
  final ScrollController _rightScroll = _createMainScrollController();
  final ScrollController _rightHeaderScroll = _createHeaderScrollController();
  bool _isSyncingVertical = false;
  bool _isSyncingHorizontal = false;

  // 展開状態
  final Set<String> _expandedProductIds = <String>{};
  final Map<String, bool> _groupExpanded = {}; // key: groupId, value: 展開中かどうか

  // フィルタUI用（ダミー）
  String _selectedProjectName = '工事A';
  String _keyword = '';
  int _viewRangeIndex = 1; // 日/週/月ダミー
  // 初期表示を工種別に。運用上製品別を初期に戻したい場合は byProduct に戻してください。
  GanttViewMode _viewMode = GanttViewMode.byProcess;
  // 工程別ビューの「計画バー（Plan）」用オフセット。
  // shiftDays: 元の期間から全体を何日スライドしたか。
  // startExtra/endExtra: 左右端を何日延長・短縮したか。
  // UI 専用の状態であり、現場実績（process_progress_daily）には影響しない。
  final Map<String, GroupPlanOffset> _groupPlanOffsets = {};
  // ドラッグ中の状態
  String? _draggingGroupKey;
  double _dragAccumulatedDx = 0.0;
  GroupPlanOffset _dragStartOffset = const GroupPlanOffset();
  _DragMode? _dragMode;

  bool _isGroupExpanded(String groupId) => _groupExpanded[groupId] ?? false;

  void _toggleGroupExpanded(String groupId) {
    setState(() {
      final current = _groupExpanded[groupId] ?? false;
      _groupExpanded[groupId] = !current;
    });
  }

  List<Widget> _buildDayCells(
    BuildContext context,
    List<DateTime> dates,
    DayCellBuilder cellBuilder,
  ) {
    return List<Widget>.generate(dates.length, (index) {
      final date = dates[index];
      return SizedBox(
        width: _dayWidth,
        child: cellBuilder(context, date, index),
      );
    });
  }

  void _changeDayWidth(double newWidth) {
    final oldWidth = _dayCellWidth;
    if (oldWidth == newWidth) return;

    double oldOffset = 0.0;
    double viewport = 0.0;
    double maxExtent = 0.0;
    if (_rightScroll.hasClients) {
      oldOffset = _rightScroll.offset;
      viewport = _rightScroll.position.viewportDimension;
      maxExtent = _rightScroll.position.maxScrollExtent;
    }

    final oldTotalWidth = _totalDays * oldWidth;
    final centerX = oldOffset + viewport / 2;
    final centerRatio =
        oldTotalWidth == 0 ? 0.0 : (centerX / oldTotalWidth).clamp(0.0, 1.0);

    setState(() {
      _dayCellWidth = newWidth;
    });

    if (_rightScroll.hasClients) {
      final newTotalWidth = _totalDays * newWidth;
      final newCenterX = newTotalWidth * centerRatio;
      final target =
          (newCenterX - viewport / 2).clamp(0.0, maxExtent == 0 ? 0.0 : _rightScroll.position.maxScrollExtent);
      _rightScroll.jumpTo(target);
    }
  }

  void _zoomInDayWidth() {
    final nextIndex = (_dayZoomIndex + 1).clamp(0, _dayZoomLevels.length - 1);
    if (nextIndex == _dayZoomIndex) return;
    _dayZoomIndex = nextIndex;
    debugPrint('[zoom] direction=+1, dayWidth=$_dayCellWidth -> zoomIndex=$_dayZoomIndex');
    _changeDayWidth(_dayZoomLevels[_dayZoomIndex]);
  }

  void _zoomOutDayWidth() {
    final prevIndex = (_dayZoomIndex - 1).clamp(0, _dayZoomLevels.length - 1);
    if (prevIndex == _dayZoomIndex) return;
    _dayZoomIndex = prevIndex;
    debugPrint('[zoom] direction=-1, dayWidth=$_dayCellWidth -> zoomIndex=$_dayZoomIndex');
    _changeDayWidth(_dayZoomLevels[_dayZoomIndex]);
  }

  @override
  void initState() {
    super.initState();
    _rightScroll.addListener(() {
      _syncHorizontalScroll(_rightScroll, _rightHeaderScroll);
    });
    _rightHeaderScroll.addListener(() {
      _syncHorizontalScroll(_rightHeaderScroll, _rightScroll);
    });
    _leftScroll.addListener(() {
      if (!_rightListScroll.hasClients) return;
      _syncVerticalScroll(_leftScroll, _rightListScroll);
    });
    _rightListScroll.addListener(() {
      if (!_leftScroll.hasClients) return;
      _syncVerticalScroll(_rightListScroll, _leftScroll);
    });
  }

  @override
  void dispose() {
    _leftScroll.dispose();
    _rightListScroll.dispose();
    _rightScroll.dispose();
    _rightHeaderScroll.dispose();
    super.dispose();
  }

  void _syncVerticalScroll(ScrollController source, ScrollController target) {
    if (_isSyncingVertical) return;
    _isSyncingVertical = true;
    try {
      final offset = source.offset;
      if (offset <= target.position.maxScrollExtent &&
          offset >= target.position.minScrollExtent) {
        target.jumpTo(offset);
      }
    } catch (_) {
      // ignore errors during sync
    }
    _isSyncingVertical = false;
  }

  void _syncHorizontalScroll(ScrollController source, ScrollController target) {
    if (_isSyncingHorizontal) return;
    if (!source.hasClients || !target.hasClients) return;
    _isSyncingHorizontal = true;
    try {
      final offset = source.offset.clamp(
        target.position.minScrollExtent,
        target.position.maxScrollExtent,
      );
      target.jumpTo(offset);
    } catch (_) {
      // ignore sync errors
    }
    _isSyncingHorizontal = false;
  }

  double _computeHeaderDragScale(ScrollController controller) {
    if (!controller.hasClients) return 1.0;

    final viewport = controller.position.viewportDimension;
    final maxScroll = controller.position.maxScrollExtent;

    if (viewport <= 0 || maxScroll <= 0) {
      return 1.0; // スクロールできない場合は等倍
    }

    return maxScroll / viewport;
  }

  int _computeDaysCount({
    required int visibleDays,
    required double availableWidth,
  }) {
    if (_isDayView) {
      // 日ビューでも表示幅が狭すぎてスクロールできなくならないよう、
      // 必ず「見せたい日数」と「表示に必要な最小日数」の大きい方を使う。
      final requiredDays =
          (availableWidth / _dayWidth).ceil().clamp(1, 365) as int;
      return visibleDays > requiredDays ? visibleDays : requiredDays;
    }

    final requiredDays =
        (availableWidth / _dayWidth).ceil().clamp(1, 365) as int;
    final minScrollableDays =
        (visibleDays + _timelineExtraScrollableDays).clamp(1, 365) as int;
    return requiredDays > minScrollableDays
        ? requiredDays
        : minScrollableDays;
  }

  String _memberTypePrefix(String memberType) {
    switch (memberType.toLowerCase()) {
      case 'column':
        return 'column_';
      case 'girder':
        return 'girder_';
      case 'beam':
        return 'beam_';
      case 'intermediate':
        return 'intermediate_';
      default:
        return '';
    }
  }

  List<GanttTask> _filterAndOrderTasksByMemberType(
    GanttProduct product,
    List<ProcessGroup> groups,
    List<ProcessStep> steps,
  ) {
    final prefix = _memberTypePrefix(product.memberType);
    final stepsMap = {for (final s in steps) s.id: s};
    final groupsMap = {for (final g in groups) g.id: g};

    final filtered = prefix.isEmpty
        ? product.tasks
        : product.tasks.where((t) => t.id.startsWith(prefix)).toList();

    filtered.sort((a, b) {
      final stepA = stepsMap[a.id];
      final stepB = stepsMap[b.id];
      final groupA = stepA != null ? groupsMap[stepA.groupId] : null;
      final groupB = stepB != null ? groupsMap[stepB.groupId] : null;

      final groupSortA = groupA?.sortOrder ?? 9999;
      final groupSortB = groupB?.sortOrder ?? 9999;
      if (groupSortA != groupSortB) {
        return groupSortA.compareTo(groupSortB);
      }

      final stepSortA = stepA?.sortOrder ?? 9999;
      final stepSortB = stepB?.sortOrder ?? 9999;
      if (stepSortA != stepSortB) {
        return stepSortA.compareTo(stepSortB);
      }

      return a.name.compareTo(b.name);
    });

    return filtered;
  }

  List<GanttRowEntry> _buildRowEntries(
    List<GanttProduct> products,
    List<ProcessGroup> groups,
    List<ProcessStep> steps,
  ) {
    final entries = <GanttRowEntry>[];
    for (final product in products) {
      entries.add(GanttRowEntry.productHeader(product));
      if (_expandedProductIds.contains(product.id)) {
        final orderedTasks =
            _filterAndOrderTasksByMemberType(product, groups, steps);
        for (final task in orderedTasks) {
          entries.add(GanttRowEntry.taskRow(product, task));
        }
      }
    }
    return entries;
  }

  Color _taskBaseColorByLabel(String label) =>
      ProcessColors.fromProcessNames(label);

  _TaskGeometry? _computeTaskGeometry(
    GanttTask task,
    DateTime startDate,
    int totalDays,
    double dayWidth,
  ) {
    return _computeRangeGeometry(
      task.start,
      task.end,
      startDate,
      totalDays,
      dayWidth,
    );
  }

  /// 任意の期間(start～end)をピクセル幅に変換するヘルパー
  _TaskGeometry? _computeRangeGeometry(
    DateTime? rangeStart,
    DateTime? rangeEnd,
    DateTime startDate,
    int totalDays,
    double dayWidth,
  ) {
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
    return _TaskGeometry(left: left, width: width);
  }

  Map<String, List<ProductGanttBar>> _groupBarsByProductStep(
    List<ProductGanttBar> bars,
  ) {
    final map = <String, List<ProductGanttBar>>{};
    for (final bar in bars) {
      final key = '${bar.productId}__${bar.stepId}';
      map.putIfAbsent(key, () => <ProductGanttBar>[]).add(bar);
    }
    return map;
  }

  List<_MatrixStep> _buildUiStepsForStatusView(
    List<ProcessGroup> groups,
    List<ProcessStep> steps,
  ) {
    final List<_MatrixStep> uiSteps = [];
    final sortedGroups = [...groups]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    for (final group in sortedGroups) {
      final groupSteps = steps
          .where((s) => s.groupId == group.id)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      for (final step in groupSteps) {
        uiSteps.add(
          _MatrixStep(
            id: step.id,
            label: step.label,
            groupName: group.label,
          ),
        );
      }
    }

    return uiSteps;
  }

  List<_ProcessHeaderGroup> _buildHeaderGroups(List<_MatrixStep> steps) {
    final Map<String, List<_MatrixStep>> grouped = {};
    for (final step in steps) {
      grouped.putIfAbsent(step.groupName, () => <_MatrixStep>[]).add(step);
    }
    final List<_ProcessHeaderGroup> result = [];
    grouped.forEach((groupName, groupSteps) {
      result.add(
        _ProcessHeaderGroup(
          groupName: groupName,
          steps: groupSteps,
        ),
      );
    });
    return result;
  }

  List<_MatrixStep> _uniqueSteps(List<_MatrixStep> steps) {
    final List<_MatrixStep> result = [];
    final Set<String> seen = {};
    for (final s in steps) {
      final parentLabel = (s.groupName).trim();
      final childLabel = s.label.trim();
      final key = '$parentLabel::$childLabel';
      if (seen.add(key)) {
        result.add(s);
      }
    }
    return result;
  }

  List<ProductGanttBar> _barsForProductStep(
    Map<String, List<ProductGanttBar>> map,
    String productId,
    String stepId,
  ) {
    final key = '${productId}__$stepId';
    return map[key] ?? const <ProductGanttBar>[];
  }

  String _formatDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  DateTime? _minTaskStart(List<GanttTask> tasks) {
    if (tasks.isEmpty) return null;
    return tasks
        .map((t) => t.start)
        .reduce((a, b) => a.isBefore(b) ? a : b);
  }

  DateTime? _maxTaskEnd(List<GanttTask> tasks) {
    if (tasks.isEmpty) return null;
    return tasks.map((t) => t.end).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  double _averageProgress(List<GanttTask> tasks) {
    if (tasks.isEmpty) return 0.0;
    final total = tasks.fold<double>(0.0, (sum, t) => sum + t.progress);
    final avg = total / tasks.length;
    return avg.clamp(0.0, 1.0);
  }

  Color _statusViewParentHeaderColor(String groupName) {
    switch (groupName) {
      case '一次加工':
        return const Color(0xFFFFF5E6); // very light orange
      case 'コア部':
        return const Color(0xFFE9F2FF); // very light blue
      case '仕口部':
        return const Color(0xFFE8F7F0); // very light green
      case '大組部':
        return const Color(0xFFF3E9FF); // very light purple
      default:
        return Colors.grey.shade50; // default light background
    }
  }

  Color _statusViewChildHeaderColor(String groupName) {
    final base = _statusViewParentHeaderColor(groupName);
    final isFallback = base.value == Colors.grey.shade50.value;
    final Color vividBase = isFallback ? const Color(0xFFF2F2F2) : base;
    // 親色を少しだけ薄め、視認できる濃さを確保
    return vividBase.withOpacity(0.35);
  }

  @override
  Widget build(BuildContext context) {
    final asyncProducts = ref.watch(ganttProductsProvider(widget.project));
    final asyncProcessSpec = ref.watch(ganttProcessSpecProvider);
    final asyncProductBars =
        ref.watch(productGanttBarsProvider(widget.project));

    return Scaffold(
      appBar: AppBar(
        title: Text('ガントチャート - ${widget.project.name}'),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedProjectName,
              items: const [
                DropdownMenuItem(value: '工事A', child: Text('工事A')),
                DropdownMenuItem(value: '工事B', child: Text('工事B')),
              ],
              onChanged: (v) =>
                  setState(() => _selectedProjectName = v ?? '工事A'),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: '製品別検査入力',
            icon: const Icon(Icons.checklist),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProductInspectionScreen(
                    project: widget.project,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 160,
            child: TextField(
              decoration: const InputDecoration(
                hintText: '製品検索',
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
              onChanged: (v) => setState(() => _keyword = v),
            ),
          ),
          const SizedBox(width: 8),
          ToggleButtons(
            isSelected: [
              _viewRangeIndex == 0,
              _viewRangeIndex == 1,
              _viewRangeIndex == 2,
            ],
            onPressed: (i) => setState(() {
              _viewRangeIndex = i;
              // 日/週/月ボタンでズームを切り替える
              switch (i) {
                case 0:
                  _dateScale = GanttDateScale.day;
                  _dayZoomIndex = 0;
                  debugPrint('[zoom] select=day, reset zoomIndex=$_dayZoomIndex');
                  _changeDayWidth(_dayZoomLevels[_dayZoomIndex]);
                  break;
                case 1:
                  _dateScale = GanttDateScale.week;
                  break;
                case 2:
                default:
                  _dateScale = GanttDateScale.month;
                  break;
              }
            }),
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('日'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('週'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('月'),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                tooltip: 'ズームアウト（セル幅縮小）',
                onPressed: _dateScale == GanttDateScale.day
                    ? () => setState(_zoomOutDayWidth)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'ズームイン（セル幅拡大）',
                onPressed: _dateScale == GanttDateScale.day
                    ? () => setState(_zoomInDayWidth)
                    : null,
              ),
            ],
          ),
          const SizedBox(width: 8),
          ToggleButtons(
            isSelected: [
              _viewMode == GanttViewMode.byProduct,
              _viewMode == GanttViewMode.byProcess,
            ],
            onPressed: (idx) {
              setState(() {
                _viewMode = idx == 0
                    ? GanttViewMode.byProduct
                    : GanttViewMode.byProcess;
              });
            },
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('製品別'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('工種別'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              // 「今日」の位置へ横スクロール
              final now = DateTime.now();
              final todayBase = DateTime(now.year, now.month, now.day);
              final displayStart = _displayStartDate;
              final offsetDays =
                  todayBase.difference(displayStart).inDays;
              double target;
              if (offsetDays <= 0) {
                target = 0;
              } else if (offsetDays >= _totalDays) {
                target = (_totalDays - 1) * _dayWidth;
              } else {
                target = offsetDays * _dayWidth;
              }
              _rightScroll.animateTo(
                target,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // 将来: データ再取得
            },
          ),
        ],
      ),
      body: asyncProducts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
        data: (products) {
          return asyncProcessSpec.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('工程マスタ読込エラー: $e')),
            data: (spec) {
              _updateDateRange(products);
              final filteredProducts = _filteredProductsFromList(products);
              final rowEntries = _filterRowsByKeyword(
                _buildRowEntries(filteredProducts, spec.groups, spec.steps),
              );
              final allTasks =
                  filteredProducts.expand((p) => p.tasks).toList();
              final processRows = _filterTreeRowsByKeyword(
                _buildProcessTreeRows(
                  spec.groups,
                  spec.steps,
                  allTasks,
                ),
              );
              final visibleProcessRows = _buildVisibleProcessRows(processRows);

              Widget content;

              if (_viewMode == GanttViewMode.byProcess) {
                content = _buildTimelineByProcess(visibleProcessRows);
              } else {
                content = _buildTimelineByProduct(
                  rowEntries,
                  asyncProductBars,
                  spec.groups,
                  spec.steps,
                );
              }

              return _wrapHorizontalWheelScroll(content);
            },
          );
        },
      ),
    );
  }

  Widget _wrapHorizontalWheelScroll(Widget child) {
    return Listener(
      onPointerSignal: (event) {
        if (event is! PointerScrollEvent) return;
        final pressed = HardwareKeyboard.instance.logicalKeysPressed;
        final isShiftPressed = pressed.contains(LogicalKeyboardKey.shiftLeft) ||
            pressed.contains(LogicalKeyboardKey.shiftRight);
        if (!isShiftPressed) return;
        if (!_rightScroll.hasClients) return;
        final min = _rightScroll.position.minScrollExtent;
        final max = _rightScroll.position.maxScrollExtent;
        final target = (_rightScroll.offset + event.scrollDelta.dy)
            .clamp(min, max);
        _rightScroll.jumpTo(target);
      },
      child: child,
    );
  }

  Widget _buildLeftPaneByProduct(List<GanttRowEntry> rows) {
    return ListView.builder(
      controller: _leftScroll,
      itemCount: rows.length,
      itemExtent: _rowHeight,
      itemBuilder: (context, index) {
        final entry = rows[index];
        switch (entry.kind) {
          case GanttRowKind.productHeader:
            return _buildProductHeaderTile(entry.product);
          case GanttRowKind.taskRow:
            return _buildTaskTile(entry.task!);
        }
      },
    );
  }

  Widget _buildLeftPaneByProcess(List<ProcessVisibleRow> rows) {
    return ListView.builder(
      controller: _leftScroll,
      itemCount: rows.length,
      itemExtent: _rowHeight,
      itemBuilder: (context, index) {
        final row = rows[index];
        if (row.isGroup && row.groupRow != null) {
          return _buildProcessGroupTile(context, row.groupRow!);
        } else if (!row.isGroup && row.stepRow != null) {
          return _buildProcessStepTile(row.stepRow!);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLeftPaneByProcessHeaderOnly(double headerHeight) {
    return Container(
      width: _leftPaneWidth,
      height: headerHeight,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey.shade300),
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: const Text(
        '工程ツリー',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLeftPaneByProductHeaderOnly(double headerHeight) {
    return Container(
      width: _leftPaneWidth,
      height: headerHeight,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey.shade300),
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: const Text(
        '製品 / 工程',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  /// 工程ツリーの表示状態に応じて、実際に表示する行（親+展開中の子のみ）のリストを構築する。
  List<ProcessVisibleRow> _buildVisibleProcessRows(List<ProcessTreeRow> rows) {
    final result = <ProcessVisibleRow>[];
    var index = 0;

    while (index < rows.length) {
      final row = rows[index];
      if (row is ProcessGroupRow) {
        result.add(ProcessVisibleRow.group(row));
        index++;

        if (_isGroupExpanded(row.groupId)) {
          while (index < rows.length && rows[index] is ProcessStepRow) {
            final stepRow = rows[index] as ProcessStepRow;
            if (stepRow.groupId != row.groupId) break;
            result.add(ProcessVisibleRow.step(stepRow));
            index++;
          }
        } else {
          while (index < rows.length && rows[index] is ProcessStepRow) {
            final stepRow = rows[index] as ProcessStepRow;
            if (stepRow.groupId != row.groupId) break;
            index++;
          }
        }
      } else {
        index++;
      }
    }

    return result;
  }

  Widget _buildProcessGroupTile(BuildContext context, ProcessGroupRow row) {
    const groupBg = Color(0xFFF2F2F2);
    final color = _taskBaseColorByLabel(row.label);
    final expanded = _isGroupExpanded(row.groupId);
    final start = _minTaskStart(row.tasks);
    final end = _maxTaskEnd(row.tasks);
    final subtitleParts = <String>[
      'タスク数: ${row.tasks.length}',
      if (start != null && end != null) '${_formatDate(start)} 〜 ${_formatDate(end)}',
    ];
    final avgProgress = _averageProgress(row.tasks);
    return Container(
      height: _rowHeight,
      color: groupBg,
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        leading: SizedBox(
          width: 28,
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            iconSize: 20,
            icon: Icon(expanded ? Icons.expand_more : Icons.chevron_right),
            onPressed: () => _toggleGroupExpanded(row.groupId),
          ),
        ),
        title: Text(
          row.label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitleParts.join(' / ')),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: avgProgress,
              backgroundColor: Colors.grey.shade200,
              color: color,
              minHeight: 6,
            ),
          ],
        ),
        onTap: () => _toggleGroupExpanded(row.groupId),
        onLongPress: () => _showProcessGroupDetail(context, row, color),
      ),
    );
  }

  Widget _buildProcessStepTile(ProcessStepRow row) {
    const stepBg = Colors.white;
    final color = _taskBaseColorByLabel(row.label);
    final start = _minTaskStart(row.tasks);
    final end = _maxTaskEnd(row.tasks);
    final subtitleParts = <String>[
      'タスク数: ${row.tasks.length}',
      if (start != null && end != null) '${_formatDate(start)} 〜 ${_formatDate(end)}',
    ];
    return Container(
      height: _rowHeight,
      color: stepBg,
      child: Padding(
        padding: const EdgeInsets.only(left: _processStepIndent),
        child: ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          leading: SizedBox(
            width: 28,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
          ),
          title: Text(
            row.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.normal),
          ),
          subtitle: Text(subtitleParts.join(' / ')),
          onTap: () {
            // step 行のタップ時の動きは今後拡張
          },
        ),
      ),
    );
  }

  Widget _buildRightPane({
    required List<GanttRowEntry> rowEntries,
    required List<ProcessTreeRow> processRows,
    required List<ProcessVisibleRow> visibleProcessRows,
    AsyncValue<List<ProductGanttBar>>? productBars,
  }) {
    return _buildTimelineByProcess(visibleProcessRows);
  }

  /// 工程別ビューを「左セル＋右セル」を1行にまとめた単一ListViewで描画する。
  /// 親を閉じたときは子行そのものをリストに入れないため、空白が残らず左右も確実に揃う。
  Widget _buildProcessUnifiedView(List<ProcessVisibleRow> visibleRows) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final displayStart = _displayStartDate;
        final displayEnd = _displayEndDate;
        final visibleDays = displayEnd.difference(displayStart).inDays + 1;
        final timelineWidth =
            (constraints.maxWidth - _leftPaneWidth).clamp(1.0, double.infinity);
        final daysCount = _computeDaysCount(
          visibleDays: visibleDays,
          availableWidth: timelineWidth,
        );
        if (_isDayView) {
          debugPrint(
            '[DayTimeline][ProcessUnified] zoomIndex=$_dayZoomIndex, '
            'displayStart=$displayStart, displayEnd=$displayEnd, '
            'visibleDays=$visibleDays, timelineWidth=$timelineWidth, '
            'daysCount=$daysCount, dayWidth=$_dayWidth',
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_rightScroll.hasClients) {
              debugPrint(
                '[DayTimeline][ProcessUnified] maxScrollExtent=${_rightScroll.position.maxScrollExtent}, '
                'viewport=${_rightScroll.position.viewportDimension}',
              );
            }
          });
        }
        _totalDays = daysCount;

        return Column(
          children: [
            Row(
              children: [
                _buildLeftPaneByProcessHeaderOnly(
                  _timelineMonthRowHeight + _timelineDayRowHeight,
                ),
                Expanded(
                  child: _buildTimelineHeader(daysCount, displayStart),
                ),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: Row(
                children: [
                  SizedBox(
                    width: _leftPaneWidth,
                    child: ListView.builder(
                      controller: _leftScroll,
                      itemCount: visibleRows.length,
                      itemExtent: _rowHeight,
                      itemBuilder: (context, index) {
                        final row = visibleRows[index];
                        if (row.isGroup && row.groupRow != null) {
                          return _buildProcessGroupTile(context, row.groupRow!);
                        }
                        return _buildProcessStepTile(row.stepRow!);
                      },
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _rightScroll,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: daysCount * _dayWidth,
                        child: ListView.builder(
                          controller: _rightListScroll,
                          itemCount: visibleRows.length,
                          itemExtent: _rowHeight,
                          itemBuilder: (context, index) {
                        final row = visibleRows[index];
                        if (row.isGroup && row.groupRow != null) {
                          return _buildGroupTimelineRow(
                            row.groupRow!,
                            daysCount,
                            displayStart,
                          );
                        }
                        return _buildStepTimelineRow(
                          row.stepRow!,
                          daysCount,
                          displayStart,
                        );
                      },
                    ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildMiniMap(
              daysCount: daysCount,
              startDate: displayStart,
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductHeaderTile(GanttProduct product) {
    final isExpanded = _expandedProductIds.contains(product.id);
    return SizedBox(
      height: _rowHeight,
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        title: Text(
          product.code,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 80,
              child: LinearProgressIndicator(
                value: product.progress.clamp(0.0, 1.0),
              ),
            ),
            Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
          ],
        ),
        onTap: () {
          setState(() {
            if (isExpanded) {
              _expandedProductIds.remove(product.id);
            } else {
              _expandedProductIds.add(product.id);
            }
          });
        },
      ),
    );
  }

  Widget _buildTaskTile(GanttTask task) {
    final baseColor = _taskBaseColorByLabel(task.name);
    return SizedBox(
      height: _rowHeight,
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.only(left: 32, right: 16),
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        title: Text(task.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${_formatDate(task.start)} 〜 ${_formatDate(task.end)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildTimelineByProduct(
    List<GanttRowEntry> rows,
    AsyncValue<List<ProductGanttBar>> barsAsync,
    List<ProcessGroup> groups,
    List<ProcessStep> steps,
  ) {
    return barsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('実績の取得に失敗しました: $e')),
      data: (bars) {
        final barsMap = _groupBarsByProductStep(bars);
        final matrixBarsMap = <String, Map<String, List<ProductGanttBar>>>{};
        for (final bar in bars) {
          matrixBarsMap.putIfAbsent(bar.productId, () => <String, List<ProductGanttBar>>{});
          matrixBarsMap[bar.productId]!
              .putIfAbsent(bar.stepId, () => <ProductGanttBar>[])
              .add(bar);
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final displayStart = _displayStartDate;
            final displayEnd = _displayEndDate;
            final visibleDays = displayEnd.difference(displayStart).inDays + 1;
            final daysCount = _computeDaysCount(
              visibleDays: visibleDays,
              availableWidth: constraints.maxWidth,
            );
            if (_isDayView) {
              debugPrint(
                '[DayTimeline][ByProduct] zoomIndex=$_dayZoomIndex, '
                'displayStart=$displayStart, displayEnd=$displayEnd, '
                'visibleDays=$visibleDays, availableWidth=${constraints.maxWidth}, '
                'daysCount=$daysCount, dayWidth=$_dayWidth',
              );
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_rightScroll.hasClients) {
                  debugPrint(
                    '[DayTimeline][ByProduct] maxScrollExtent=${_rightScroll.position.maxScrollExtent}, '
                    'viewport=${_rightScroll.position.viewportDimension}',
                  );
                }
              });
            }
            _totalDays = daysCount;

            final headerHeight =
                _timelineMonthRowHeight + _timelineDayRowHeight;

            final scheduleView = Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: _leftPaneWidth,
                      height: headerHeight,
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Colors.grey.shade300),
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: const Text(
                        '製品 / 工程',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: _buildTimelineHeader(daysCount, displayStart),
                    ),
                  ],
                ),
                const Divider(height: 1),
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(
                        width: _leftPaneWidth,
                        child: _buildLeftPaneByProduct(rows),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _rightScroll,
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: daysCount * _dayWidth,
                            child: ListView.builder(
                              controller: _rightListScroll,
                              itemCount: rows.length,
                              itemExtent: _rowHeight,
                              itemBuilder: (context, index) {
                                final entry = rows[index];
                                switch (entry.kind) {
                                  case GanttRowKind.productHeader:
                                    return _buildProductTimelineRow(
                                      entry.product,
                                      daysCount,
                                      displayStart,
                                    );
                                  case GanttRowKind.taskRow:
                                    final taskBars = _barsForProductStep(
                                      barsMap,
                                      entry.product.id,
                                      entry.task!.id,
                                    );
                                    return _buildTaskTimelineRow(
                                      entry.task!,
                                      daysCount,
                                      displayStart,
                                      taskBars,
                                    );
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildMiniMap(
                  daysCount: daysCount,
                  startDate: displayStart,
                ),
              ],
            );

            final statusSteps = _uniqueSteps(_buildUiStepsForStatusView(groups, steps));

            final matrixView = _buildProductProcessStatusView(
              productRows: rows,
              steps: statusSteps,
              barsMap: matrixBarsMap,
            );

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _buildProductViewModeToggle(),
                  ),
                ),
                Expanded(
                  child: _productViewMode == ProductViewMode.schedule
                      ? scheduleView
                      : matrixView,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildProductViewModeToggle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildProductViewModeButton(
          label: '日程ガント',
          mode: ProductViewMode.schedule,
        ),
        const SizedBox(width: 8),
        _buildProductViewModeButton(
          label: '工程ステータス',
          mode: ProductViewMode.processStatus,
        ),
      ],
    );
  }

  Widget _buildProductViewModeButton({
    required String label,
    required ProductViewMode mode,
  }) {
    final selected = _productViewMode == mode;
    return OutlinedButton(
      onPressed: () {
        if (!selected) {
          setState(() => _productViewMode = mode);
        }
      },
      style: OutlinedButton.styleFrom(
        backgroundColor:
            selected ? Theme.of(context).colorScheme.primary : Colors.white,
        foregroundColor: selected ? Colors.white : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(label),
    );
  }

  ProcessCellStatus _statusFromBars(List<ProductGanttBar> bars) {
    final actualBars = bars.where((b) => b.kind == GanttBarKind.actual);
    final hasDone = actualBars.any((b) => b.status == GanttBarStatus.done);
    if (hasDone) return ProcessCellStatus.done;
    final hasInProgress =
        actualBars.any((b) => b.status == GanttBarStatus.inProgress);
    if (hasInProgress) return ProcessCellStatus.inProgress;
    return ProcessCellStatus.notStarted;
  }

  Color _statusColor(ProcessCellStatus status) {
    switch (status) {
      case ProcessCellStatus.notStarted:
        return const Color(0xFFE0E0E0);
      case ProcessCellStatus.inProgress:
        return kGanttActualInProgressColor.withValues(alpha: 0.85);
      case ProcessCellStatus.done:
        return kGanttActualDoneColor.withValues(alpha: 0.9);
    }
  }

  Widget _buildStatusLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _legendItem(
          color: _statusColor(ProcessCellStatus.notStarted),
          label: '未',
        ),
        const SizedBox(width: 8),
        _legendItem(
          color: _statusColor(ProcessCellStatus.inProgress),
          label: '作業中',
        ),
        const SizedBox(width: 8),
        _legendItem(
          color: _statusColor(ProcessCellStatus.done),
          label: '完了',
        ),
      ],
    );
  }

  Widget _legendItem({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.black12),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildProductProcessStatusView({
    required List<GanttRowEntry> productRows,
    required List<_MatrixStep> steps,
    required Map<String, Map<String, List<ProductGanttBar>>> barsMap,
  }) {
    const double rowHeight = 28;
    const double productColWidth = 140;
    const double cellWidth = 80;
    // 工程ステータスビュー専用のヘッダー高さ
    const double kProcessStatusHeaderParentHeight = 28;
    const double kProcessStatusHeaderChildHeight = 24;

    final products = <_MatrixProduct>[];
    for (final entry in productRows) {
      if (entry.kind == GanttRowKind.productHeader) {
        products.add(
          _MatrixProduct(
            id: entry.product.id,
            label: entry.product.code.isNotEmpty ? entry.product.code : entry.product.name,
          ),
        );
      }
    }

    if (steps.isEmpty) {
      return const Center(
        child: Text(
          '工程が0件です（ステータスビュー用の工程リストを取得できませんでした）',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.redAccent),
        ),
      );
    }

    final uniqueSteps = _uniqueSteps(steps);

    final statusMap = <String, Map<String, ProcessCellStatus>>{};
    for (final product in products) {
      final productBars = barsMap[product.id] ?? <String, List<ProductGanttBar>>{};
      final stepStatuses = <String, ProcessCellStatus>{};
      for (final step in uniqueSteps) {
        final barsForStep = productBars[step.id] ?? const <ProductGanttBar>[];
        stepStatuses[step.id] = _statusFromBars(barsForStep);
      }
      statusMap[product.id] = stepStatuses;
    }

    final headerGroups = _buildHeaderGroups(uniqueSteps);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: _buildStatusLegend(),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const SizedBox(
                          width: productColWidth,
                          height: kProcessStatusHeaderParentHeight,
                        ),
                        for (final group in headerGroups)
                          Container(
                            height: kProcessStatusHeaderParentHeight,
                            alignment: Alignment.center,
                            width: group.steps.length * cellWidth,
                            padding: const EdgeInsets.symmetric(
                              vertical: 2,
                              horizontal: 4,
                            ),
                            color: _statusViewParentHeaderColor(group.groupName),
                            child: Text(
                              group.groupName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                    Row(
                      children: [
                        const SizedBox(
                          width: productColWidth,
                          height: kProcessStatusHeaderChildHeight,
                        ),
                        for (final step in uniqueSteps)
                          Container(
                            width: cellWidth,
                            height: kProcessStatusHeaderChildHeight,
                            padding: const EdgeInsets.symmetric(
                              vertical: 2,
                              horizontal: 2,
                            ),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _statusViewChildHeaderColor(step.groupName),
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                                right: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Text(
                              step.label,
                              style: const TextStyle(fontSize: 11),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                    Container(
                      width: productColWidth + uniqueSteps.length * cellWidth,
                      height: 1,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
                const SizedBox(height: 4),
                for (final product in products)
                  SizedBox(
                    height: rowHeight,
                    child: Row(
                      children: [
                        Container(
                          width: productColWidth,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            product.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        for (final step in uniqueSteps)
                          _buildStatusCellFor(
                            product: product,
                            step: step,
                            width: cellWidth,
                            height: rowHeight,
                            statusMap: statusMap,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCellFor({
    required _MatrixProduct product,
    required _MatrixStep step,
    required double width,
    required double height,
    required Map<String, Map<String, ProcessCellStatus>> statusMap,
  }) {
    final status = statusMap[product.id]?[step.id] ?? ProcessCellStatus.notStarted;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _statusColor(status),
        border: Border.all(
          color: Colors.white,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildTimelineByProcess(List<ProcessVisibleRow> rows) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final displayStart = _displayStartDate;
        final displayEnd = _displayEndDate;
        final visibleDays = displayEnd.difference(displayStart).inDays + 1;
        final daysCount = _computeDaysCount(
          visibleDays: visibleDays,
          availableWidth: constraints.maxWidth,
        );
        if (_isDayView) {
          debugPrint(
            '[DayTimeline][ByProcess] zoomIndex=$_dayZoomIndex, '
            'displayStart=$displayStart, displayEnd=$displayEnd, '
            'visibleDays=$visibleDays, availableWidth=${constraints.maxWidth}, '
            'daysCount=$daysCount, dayWidth=$_dayWidth',
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_rightScroll.hasClients) {
              debugPrint(
                '[DayTimeline][ByProcess] maxScrollExtent=${_rightScroll.position.maxScrollExtent}, '
                'viewport=${_rightScroll.position.viewportDimension}',
              );
            }
          });
        }
        _totalDays = daysCount;

        final headerHeight =
            _timelineMonthRowHeight + _timelineDayRowHeight;

        return Column(
          children: [
            Row(
              children: [
                _buildLeftPaneByProcessHeaderOnly(headerHeight),
                Expanded(
                  child: _buildTimelineHeader(daysCount, displayStart),
                ),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: Row(
                children: [
                  SizedBox(
                    width: _leftPaneWidth,
                    child: _buildLeftPaneByProcess(rows),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _rightScroll,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: daysCount * _dayWidth,
                        child: ListView.builder(
                          controller: _rightListScroll,
                          itemCount: rows.length,
                          itemExtent: _rowHeight,
                          itemBuilder: (context, index) {
                            final row = rows[index];
                            if (row.isGroup && row.groupRow != null) {
                              return _buildGroupTimelineRow(
                                row.groupRow!,
                                daysCount,
                                displayStart,
                              );
                            } else if (!row.isGroup && row.stepRow != null) {
                              return _buildStepTimelineRow(
                                row.stepRow!,
                                daysCount,
                                displayStart,
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildMiniMap(
              daysCount: daysCount,
              startDate: displayStart,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimelineHeader(int daysCount, DateTime startDate) {
    final dates = List<DateTime>.generate(
      daysCount,
      (i) => startDate.add(Duration(days: i)),
    );

    final mainController = _rightScroll;
    final headerController = _rightHeaderScroll;
    final totalWidth = daysCount * _dayWidth;
    final headerHeight = _timelineMonthRowHeight + _timelineDayRowHeight;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      dragStartBehavior: DragStartBehavior.down,
      onHorizontalDragUpdate: (details) {
        if (!mainController.hasClients) return;

        final double scale = _computeHeaderDragScale(mainController);
        final double delta = details.delta.dx * scale;
        final double maxScroll = mainController.position.maxScrollExtent;
        final double oldOffset = mainController.offset;
        final double newOffset =
            (oldOffset - delta).clamp(0.0, maxScroll);
        debugPrint(
          '[HEADER DRAG] delta.dx=${details.delta.dx}, '
          'scale=$scale, '
          'oldOffset=$oldOffset, '
          'newOffset=$newOffset, '
          'maxScroll=$maxScroll',
        );
        mainController.jumpTo(newOffset);
      },
      child: SizedBox(
        height: headerHeight,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          controller: headerController,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMonthHeaderRow(dates),
                _buildDayHeaderRow(dates),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniMap({
    required int daysCount,
    required DateTime startDate,
  }) {
    return GanttMiniMap(
      mainController: _rightScroll,
      dayWidth: _dayWidth,
      miniDayWidth: _miniMapDayWidth,
      daysCount: daysCount,
      startDate: startDate,
      height: _miniMapHeight,
    );
  }

  Widget _buildMonthHeaderRow(List<DateTime> dates) {
    if (dates.isEmpty) {
      return SizedBox(height: _timelineMonthRowHeight);
    }

    final List<_MonthSpan> spans = [];
    int currentMonth = dates.first.month;
    int startIndex = 0;

    for (var i = 1; i < dates.length; i++) {
      final date = dates[i];
      if (date.month != currentMonth) {
        spans.add(
          _MonthSpan(
            month: currentMonth,
            startIndex: startIndex,
            endIndex: i - 1,
          ),
        );
        currentMonth = date.month;
        startIndex = i;
      }
    }
    spans.add(
      _MonthSpan(
        month: currentMonth,
        startIndex: startIndex,
        endIndex: dates.length - 1,
      ),
    );

    return SizedBox(
      height: _timelineMonthRowHeight,
      child: Row(
        children: spans.map((span) {
          final monthDate = dates[span.startIndex];
          return SizedBox(
            width: span.length * _dayWidth,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                border: Border(
                  right: BorderSide(color: Colors.grey.shade300),
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '${monthDate.month}',
                textAlign: TextAlign.center,
                softWrap: false,
                overflow: TextOverflow.clip,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDayHeaderRow(List<DateTime> dates) {
    return Row(
      children: _buildDayCells(
        context,
        dates,
        (context, date, index) {
          return Container(
            height: _timelineDayRowHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.grey.shade300),
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Text(
              '${date.day}',
              textAlign: TextAlign.center,
              softWrap: false,
              overflow: TextOverflow.clip,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.normal,
                color: Colors.black87,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRowGrid(int daysCount, DateTime startDate) {
    final dates = List<DateTime>.generate(
      daysCount,
      (i) => startDate.add(Duration(days: i)),
    );
    return Row(
      children: _buildDayCells(
        context,
        dates,
        (context, date, index) {
          final isWeekend =
              date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
          return Container(
            height: double.infinity,
            decoration: BoxDecoration(
              color: isWeekend
                  ? Colors.grey.withValues(alpha: 0.12)
                  : Colors.transparent,
              border: Border(
                right: BorderSide(color: Colors.grey.shade300),
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupTimelineRow(
    ProcessGroupRow row,
    int daysCount,
    DateTime startDate,
  ) {
    final baseColor = _taskBaseColorByLabel(row.label);
    // 工程別ビューでは、各工程の全タスク期間（最初の start〜最後の end）を細い計画バーとして 1本描画し、その上に各製品のバー（実績）を重ねている
    _TaskGeometry? plannedGeo;
    if (row.tasks.isNotEmpty) {
      final starts = row.tasks.map((t) => t.start).toList()..sort();
      final ends = row.tasks.map((t) => t.end).toList()..sort();
      final offset = _groupPlanOffsets[row.groupKey] ?? const GroupPlanOffset();
      var plannedStart = starts.first.add(
        Duration(days: offset.shiftDays + offset.startExtra),
      );
      var plannedEnd = ends.last.add(
        Duration(days: offset.shiftDays + offset.endExtra),
      );
      // 開始 > 終了にならないように最低1日幅を確保
      if (!plannedEnd.isAfter(plannedStart)) {
        plannedEnd = plannedStart.add(const Duration(days: 1));
      }
      plannedGeo = _computeRangeGeometry(
        plannedStart,
        plannedEnd,
        startDate,
        daysCount,
        _dayWidth,
      );
    }

    return SizedBox(
      height: _rowHeight,
      child: Stack(
        children: [
          Positioned.fill(child: _buildRowGrid(daysCount, startDate)),
          if (plannedGeo != null)
            _buildProcessPlannedBar(
              plannedGeo,
              baseColor,
              row.groupKey,
            ),
          for (final task in row.tasks)
            _buildProcessTaskBar(task, baseColor, daysCount, startDate),
        ],
      ),
    );
  }

  Widget _buildStepTimelineRow(
    ProcessStepRow row,
    int daysCount,
    DateTime startDate,
  ) {
    final baseColor = _taskBaseColorByLabel(row.label);
    return SizedBox(
      height: _rowHeight,
      child: Stack(
        children: [
          Positioned.fill(child: _buildRowGrid(daysCount, startDate)),
          for (final task in row.tasks)
            _buildProcessTaskBar(task, baseColor, daysCount, startDate),
        ],
      ),
    );
  }

  /// 工程グループ全体の計画バー（細いバー）を描画
  /// shiftDays: 全体スライド、startExtra/endExtra: 左右端の伸縮
  Widget _buildProcessPlannedBar(
    _TaskGeometry geo,
    Color baseColor,
    String groupKey,
  ) {
    const double plannedHeight = 8;
    const double handleWidth = 6;
    final barWidth = geo.width;
    final centerWidthNum = (barWidth - handleWidth * 2);
    final double centerWidth =
        centerWidthNum < 0 ? 0 : centerWidthNum.toDouble();

    return Positioned(
      left: geo.left,
      // 実績バーと完全に重ならないよう少し上にずらす
      top: (_rowHeight - plannedHeight) / 2 - 2,
      child: SizedBox(
        height: _rowHeight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 左端ハンドル: 開始日を伸縮
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (_) =>
                  _onPlanDragStart(groupKey, _DragMode.resizeLeft),
              onPanUpdate: (d) => _onPlanDragUpdate(groupKey, d.delta.dx),
              onPanEnd: (_) => _onPlanDragEnd(groupKey),
              child: Container(
                width: handleWidth,
                height: plannedHeight + 8,
                decoration: BoxDecoration(
                  color: baseColor.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // 中央: 全体スライド
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (_) => _onPlanDragStart(groupKey, _DragMode.move),
              onPanUpdate: (d) => _onPlanDragUpdate(groupKey, d.delta.dx),
              onPanEnd: (_) => _onPlanDragEnd(groupKey),
              child: Container(
                width: centerWidth,
                height: plannedHeight,
                decoration: BoxDecoration(
                  color: baseColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: baseColor.withValues(alpha: 0.7),
                    width: 1,
                  ),
                ),
              ),
            ),
            // 右端ハンドル: 終了日を伸縮
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (_) =>
                  _onPlanDragStart(groupKey, _DragMode.resizeRight),
              onPanUpdate: (d) => _onPlanDragUpdate(groupKey, d.delta.dx),
              onPanEnd: (_) => _onPlanDragEnd(groupKey),
              child: Container(
                width: handleWidth,
                height: plannedHeight + 8,
                decoration: BoxDecoration(
                  color: baseColor.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 工種別ビューでも製品別と同じ「予定(細)+実績(太)」2レイヤーバーを使う
  Widget _buildProcessTaskBar(
    GanttTask task,
    Color baseColor,
    int daysCount,
    DateTime startDate,
  ) {
    final geo = _computeTaskGeometry(task, startDate, daysCount, _dayWidth);
    if (geo == null) return const SizedBox.shrink();

    return Positioned(
      left: geo.left,
      top: (_rowHeight - kGanttActualBarHeight) / 2,
      child: Stack(
        children: [
          _buildPlannedBar(
            width: geo.width,
            color: kGanttPlannedBarColor,
          ),
        ],
      ),
    );
  }

  Widget _buildProductTimelineRow(
    GanttProduct product,
    int daysCount,
    DateTime startDate,
  ) {
    return SizedBox(
      height: _rowHeight,
      child: Stack(
        children: [
          Positioned.fill(child: _buildRowGrid(daysCount, startDate)),
          _buildTodayLine(startDate, daysCount),
          // productヘッダ行ではバーは描かない（タスク行側で連続バーを表示）
        ],
      ),
    );
  }

  Widget _buildTaskTimelineRow(
    GanttTask task,
    int daysCount,
    DateTime startDate,
    List<ProductGanttBar> actualBars,
  ) {
    final geo = _computeTaskGeometry(task, startDate, daysCount, _dayWidth);

    return SizedBox(
      height: _rowHeight,
      child: Stack(
        children: [
          Positioned.fill(child: _buildRowGrid(daysCount, startDate)),
          _buildTodayLine(startDate, daysCount),
          _buildPlannedEndLine(task, startDate, daysCount),
          if (geo != null)
            Positioned(
              left: geo.left,
              top: (_rowHeight - kGanttPlannedBarHeight) / 2,
              child: _buildPlannedBar(
                width: geo.width,
                color: kGanttPlannedBarColor,
              ),
            ),
          for (final bar in actualBars)
            _buildActualBar(
              bar: bar,
              startDate: startDate,
              totalDays: daysCount,
            ),
        ],
      ),
    );
  }

  Widget _buildPlannedBar({
    required double width,
    required Color color,
  }) {
    const double plannedHeight = kGanttPlannedBarHeight;
    return Container(
      width: width,
      height: plannedHeight,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(kGanttPlannedBarRadius),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
    );
  }

  Widget _buildActualBar({
    required ProductGanttBar bar,
    required DateTime startDate,
    required int totalDays,
  }) {
    final geo = _computeRangeGeometry(
      bar.startDate,
      bar.endDate,
      startDate,
      totalDays,
      _dayWidth,
    );
    if (geo == null) return const SizedBox.shrink();
    if (bar.status == GanttBarStatus.notStarted) return const SizedBox.shrink();
    final color =
        bar.status == GanttBarStatus.done ? kGanttActualDoneColor : kGanttActualInProgressColor;
    final double dayWidth = _dayWidth;
    final double minWidth = math.max(kGanttActualBarMinWidth, dayWidth * 0.8);
    final double rawWidth = geo.width;
    final double width = rawWidth < minWidth ? minWidth : rawWidth;
    final double left = rawWidth < minWidth ? geo.left - (minWidth - rawWidth) / 2 : geo.left;
    return Positioned(
      left: left,
      top: (_rowHeight - kGanttActualBarHeight) / 2,
      child: Container(
        width: width,
        height: kGanttActualBarHeight,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(kGanttActualBarRadius),
          border: Border.all(
            color: color.withValues(alpha: 1.0),
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildTodayLine(DateTime startDate, int totalDays) {
    final today = DateTime.now();
    final todayBase = DateTime(today.year, today.month, today.day);
    final offset = todayBase.difference(startDate).inDays;
    if (offset < 0 || offset >= totalDays) {
      return const SizedBox.shrink();
    }
    return Positioned(
      left: offset * _dayWidth,
      top: 0,
      bottom: 0,
      child: Container(width: 2, color: Colors.red.withValues(alpha: 0.6)),
    );
  }

  /// 予定完了日の縦ライン（行内のみ）
  Widget _buildPlannedEndLine(
    GanttTask task,
    DateTime startDate,
    int totalDays,
  ) {
    final planned = task.plannedEnd;
    if (planned == null) {
      return const SizedBox.shrink();
    }
    final plannedOnly = DateTime(planned.year, planned.month, planned.day);
    final offsetDays = plannedOnly.difference(startDate).inDays;
    if (offsetDays < 0 || offsetDays >= totalDays) {
      // タイムライン範囲外
      return const SizedBox.shrink();
    }

    final color = _plannedLineColor(task);
    if (color == Colors.transparent) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: offsetDays * _dayWidth,
      top: 0,
      bottom: 0,
      child: Container(width: 2, color: color),
    );
  }

  /// 予定ラインの色（進捗状況によって変化）
  Color _plannedLineColor(GanttTask task) {
    final planned = task.plannedEnd;
    if (planned == null) return Colors.transparent;

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final plannedOnly = DateTime(planned.year, planned.month, planned.day);
    final actualEndOnly = DateTime(task.end.year, task.end.month, task.end.day);

    // 予定内に完了（前倒し含む）
    if (task.progress >= 1.0 && !actualEndOnly.isAfter(plannedOnly)) {
      return Colors.green;
    }
    // 予定日を過ぎても未完了 → 遅れ
    if (task.progress < 1.0 && todayOnly.isAfter(plannedOnly)) {
      return Colors.red;
    }
    // それ以外は薄いグレー
    return Colors.grey.withValues(alpha: 0.6);
  }

  List<GanttRowEntry> _filterRowsByKeyword(List<GanttRowEntry> rows) {
    if (_keyword.isEmpty) return rows;
    final kw = _keyword.toLowerCase();
    return rows.where((e) {
      switch (e.kind) {
        case GanttRowKind.productHeader:
          return e.product.code.toLowerCase().contains(kw) ||
              e.product.name.toLowerCase().contains(kw);
        case GanttRowKind.taskRow:
          return (e.task?.name.toLowerCase().contains(kw) ?? false) ||
              e.product.code.toLowerCase().contains(kw);
      }
    }).toList();
  }

  List<ProcessTreeRow> _buildProcessTreeRows(
    List<ProcessGroup> groups,
    List<ProcessStep> steps,
    List<GanttTask> allTasks,
  ) {
    final Map<String, String> groupLookup = {
      for (final g in groups) g.id: g.id,
      for (final g in groups) g.key: g.id,
      'その他': groups.firstWhere((g) => g.label == 'その他',
              orElse: () => groups.isNotEmpty ? groups.last : ProcessGroup(id: 'その他', key: 'その他', label: 'その他', sortOrder: 999))
          .id,
    };
    String? resolveGroupId(String? raw) {
      if (raw == null) return null;
      return groupLookup[raw] ?? raw;
    }
    ProcessGroup? otherGroup;
    for (final g in groups) {
      final keyLower = g.key.toLowerCase();
      if (keyLower == 'other' || g.label == 'その他') {
        otherGroup = g;
        break;
      }
    }

    final stepsById = {for (final s in steps) s.id: s};

    final tasksByGroup = <String, List<GanttTask>>{};
    // key: "$groupId||$stepLabel"
    final tasksByStepLabel = <String, List<GanttTask>>{};

    for (final task in allTasks) {
      final step = task.stepId != null ? stepsById[task.stepId] : null;
      String? derivedGroupId = resolveGroupId(task.processGroupId);
      if (derivedGroupId == null && step != null) {
        derivedGroupId = resolveGroupId(step.groupId);
      }
      derivedGroupId ??= otherGroup?.id;

      if (derivedGroupId != null) {
        tasksByGroup.putIfAbsent(derivedGroupId, () => <GanttTask>[]).add(task);
      }
      final stepLabel = (task.stepLabel ?? task.name).trim();
      if (derivedGroupId != null && stepLabel.isNotEmpty) {
        final key = '$derivedGroupId||$stepLabel';
        tasksByStepLabel.putIfAbsent(key, () => <GanttTask>[]).add(task);
      }
    }

    final groupsSorted = [...groups]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final rows = <ProcessTreeRow>[];

    for (final group in groupsSorted) {
      final groupTasks = tasksByGroup[group.id] ?? const <GanttTask>[];
      final groupKey = group.key.isNotEmpty ? group.key : group.id;

      rows.add(
        ProcessGroupRow(
          groupId: group.id,
          groupKey: groupKey,
          label: group.label,
          sortOrder: group.sortOrder,
          tasks: groupTasks,
        ),
      );

      final groupedSteps = steps
          .where((s) => resolveGroupId(s.groupId) == group.id)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      final seenLabels = <String>{};
      for (final step in groupedSteps) {
        final labelKey = step.label.trim().isNotEmpty ? step.label.trim() : step.id;
        if (seenLabels.contains(labelKey)) continue;
        seenLabels.add(labelKey);
        final stepTasks = tasksByStepLabel['${group.id}||$labelKey'] ??
            const <GanttTask>[];
        rows.add(
          ProcessStepRow(
            groupId: group.id,
            stepId: step.id,
            stepKey: step.key,
            label: step.label,
            sortOrder: step.sortOrder,
            tasks: stepTasks,
          ),
        );
      }
    }

    return rows;
  }

  List<ProcessTreeRow> _filterTreeRowsByKeyword(List<ProcessTreeRow> rows) {
    if (_keyword.isEmpty) return rows;
    final kw = _keyword.toLowerCase();
    final filtered = <ProcessTreeRow>[];
    var index = 0;

    while (index < rows.length) {
      final row = rows[index];
      if (row is ProcessGroupRow) {
        final group = row;
        final steps = <ProcessStepRow>[];
        var cursor = index + 1;
        while (
          cursor < rows.length &&
          rows[cursor] is ProcessStepRow &&
          (rows[cursor] as ProcessStepRow).groupId == group.groupId
        ) {
          steps.add(rows[cursor] as ProcessStepRow);
          cursor++;
        }

        final groupMatches = group.label.toLowerCase().contains(kw) ||
            group.tasks.any((t) => t.name.toLowerCase().contains(kw));
        final matchingSteps = steps
            .where(
              (s) =>
                  s.label.toLowerCase().contains(kw) ||
                  s.tasks.any((t) => t.name.toLowerCase().contains(kw)),
            )
            .toList();

        if (groupMatches) {
          filtered.add(group);
          filtered.addAll(steps);
        } else if (matchingSteps.isNotEmpty) {
          filtered.add(group);
          filtered.addAll(matchingSteps);
        }

        index = cursor;
      } else {
        index++;
      }
    }

    return filtered;
  }

  void _onPlanDragStart(String groupKey, _DragMode mode) {
    _draggingGroupKey = groupKey;
    _dragMode = mode;
    _dragAccumulatedDx = 0.0;
    _dragStartOffset = _groupPlanOffsets[groupKey] ?? const GroupPlanOffset();
  }

  void _onPlanDragUpdate(String groupKey, double deltaDx) {
    if (_draggingGroupKey != groupKey || _dragMode == null) return;
    _dragAccumulatedDx += deltaDx;
    final deltaDays = (_dragAccumulatedDx / _dayWidth).truncate();
    if (deltaDays == 0) return;

    final current = _dragStartOffset;
    GroupPlanOffset next;
    switch (_dragMode!) {
      case _DragMode.move:
        next = current.copyWith(shiftDays: current.shiftDays + deltaDays);
        break;
      case _DragMode.resizeLeft:
        next = current.copyWith(startExtra: current.startExtra + deltaDays);
        break;
      case _DragMode.resizeRight:
        next = current.copyWith(endExtra: current.endExtra + deltaDays);
        break;
    }

    setState(() {
      _groupPlanOffsets[groupKey] = next;
    });
  }

  void _onPlanDragEnd(String groupKey) {
    _draggingGroupKey = null;
    _dragMode = null;
    _dragAccumulatedDx = 0.0;
  }

  /// 工程別ビューで行をタップしたとき、その工程グループに属する製品別タスクの一覧をモーダルで表示する（閲覧専用）
  Future<void> _showProcessGroupDetail(
    BuildContext context,
    ProcessGroupRow row,
    Color baseColor,
  ) async {
    final tasks = row.tasks;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                // キーボードが出ても余白を確保
                bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: baseColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        row.label,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'タスク数: ${tasks.length}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        final start = _formatDate(task.start);
                        final end = _formatDate(task.end);
                        final progressPercent =
                            (task.progress.clamp(0.0, 1.0) * 100).round();
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: baseColor,
                              child: Text('${index + 1}'),
                            ),
                            title: Text(task.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$start 〜 $end'),
                                Text('工程: ${task.name}'),
                                LinearProgressIndicator(
                                  value: task.progress.clamp(0.0, 1.0),
                                ),
                                Text('進捗: $progressPercent%'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<GanttProduct> _filteredProductsFromList(List<GanttProduct> list) {
    if (_keyword.isEmpty) return list;
    final kw = _keyword.toLowerCase();
    return list
        .where(
          (p) =>
              p.code.toLowerCase().contains(kw) ||
              p.name.toLowerCase().contains(kw) ||
              p.tasks.any((t) => t.name.toLowerCase().contains(kw)),
        )
        .toList();
  }

  void _updateDateRange(List<GanttProduct> products) {
    DateTime? minStart;
    DateTime? maxEnd;
    for (final p in products) {
      for (final t in p.tasks) {
        final s = _dateOnly(t.start);
        final e = _dateOnly(t.end);
        minStart = minStart == null || s.isBefore(minStart) ? s : minStart;
        maxEnd = maxEnd == null || e.isAfter(maxEnd) ? e : maxEnd;
      }
    }
    final now = DateTime.now();
    final today = _dateOnly(now);
    // データが無い場合もカレンダーを一定期間表示する（デフォルト14日間）
    DateTime start;
    DateTime end;
    if (minStart == null || maxEnd == null) {
      start = today.subtract(
        const Duration(days: 3),
      );
      end = start.add(const Duration(days: 13)); // 合計14日
    } else {
      start = _dateOnly(minStart);
      end = _dateOnly(maxEnd);
      // 極端に短い期間の場合は少し余白を足す
      final minDays = 14;
      final totalDays = end.difference(start).inDays + 1;
      if (totalDays < minDays) {
        end = start.add(Duration(days: minDays - 1));
      }
    }

    final total = end.difference(start).inDays + 1;

    final needsUpdate =
        _startDate != start || _endDate != end || _totalDays != total;
    if (needsUpdate) {
      _startDate = _dateOnly(start);
      _endDate = _dateOnly(end);
      _totalDays = total;
    }
    debugPrint(
      '[_updateDateRange] _startDate=$_startDate, _endDate=$_endDate, _totalDays=$_totalDays',
    );
  }
}

class GanttMiniMap extends StatefulWidget {
  final ScrollController mainController;
  final double dayWidth;
  final double miniDayWidth;
  final int daysCount;
  final DateTime startDate;
  final double height;

  const GanttMiniMap({
    super.key,
    required this.mainController,
    required this.dayWidth,
    required this.miniDayWidth,
    required this.daysCount,
    required this.startDate,
    required this.height,
  });

  @override
  State<GanttMiniMap> createState() => _GanttMiniMapState();
}

class _GanttMiniMapState extends State<GanttMiniMap> {
  @override
  void initState() {
    super.initState();
    widget.mainController.addListener(_handleMainScroll);
  }

  @override
  void dispose() {
    widget.mainController.removeListener(_handleMainScroll);
    super.dispose();
  }

  void _handleMainScroll() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final totalWidth = widget.dayWidth * widget.daysCount;
    final miniTotalWidth = widget.miniDayWidth * widget.daysCount;
    final position = widget.mainController.positions.isNotEmpty
        ? widget.mainController.positions.first
        : null;
    final hasViewport = position?.hasViewportDimension == true;
    final hasPixels = position?.hasPixels == true;
    final hasContent = position?.hasContentDimensions == true;
    final viewport = hasViewport ? position!.viewportDimension : miniTotalWidth;
    final offset = hasPixels ? position!.pixels : 0.0;
    final maxScroll = hasContent ? position!.maxScrollExtent : 0.0;

    final viewportRatio =
        totalWidth == 0 ? 1.0 : (viewport / totalWidth).clamp(0.0, 1.0);
    final miniViewportWidth = (miniTotalWidth * viewportRatio).toDouble();

    final miniScrollableWidth =
        (miniTotalWidth - miniViewportWidth).clamp(0.0, double.infinity);
    final scrollRatio =
        maxScroll <= 0 ? 0.0 : (offset / maxScroll).clamp(0.0, 1.0);
    final miniViewportX = (miniScrollableWidth * scrollRatio).toDouble();

    final scaleToMain =
        miniTotalWidth == 0 ? 1.0 : (totalWidth / miniTotalWidth);

    void jumpMainByDelta(double miniDelta) {
      if (!widget.mainController.hasClients) return;
      final deltaMain = miniDelta * scaleToMain;
      final min = widget.mainController.position.minScrollExtent;
      final max = widget.mainController.position.maxScrollExtent;
      final target =
          (widget.mainController.offset + deltaMain).clamp(min, max);
      widget.mainController.jumpTo(target);
    }

    void jumpMainToMiniPosition(double miniCenter) {
      if (!widget.mainController.hasClients) return;
      final desiredMainCenter = miniCenter * scaleToMain;
      final min = widget.mainController.position.minScrollExtent;
      final max = widget.mainController.position.maxScrollExtent;
      final target = (desiredMainCenter - viewport / 2).clamp(min, max);
      widget.mainController.jumpTo(target);
    }

    return SizedBox(
      height: widget.height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) => jumpMainByDelta(details.delta.dx),
        onTapDown: (details) =>
            jumpMainToMiniPosition(details.localPosition.dx),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.08),
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                children: List.generate(widget.daysCount, (i) {
                  final d = widget.startDate.add(Duration(days: i));
                  final isWeekend = d.weekday == DateTime.saturday ||
                      d.weekday == DateTime.sunday;
                  return Container(
                    width: widget.miniDayWidth,
                    height: double.infinity,
                    color: isWeekend
                        ? Colors.grey.withValues(alpha: 0.12)
                        : Colors.transparent,
                  );
                }),
              ),
            ),
            Positioned(
              left: miniViewportX,
              top: 4,
              bottom: 4,
              width: miniViewportWidth,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.12),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.6),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
