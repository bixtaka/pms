import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:legacy_gantt_chart/legacy_gantt_chart.dart';
import '../../products/domain/product.dart';
import '../../process_progress/domain/process_progress.dart';
import '../../process_spec/domain/process_group.dart';
import '../../process_spec/domain/process_step.dart';

// ─────────────────────────────────────────────
// 公開データクラス
// ─────────────────────────────────────────────

class GanttChartData {
  final List<LegacyGanttTask> tasks;
  final List<LegacyGanttRow> rows;
  final Map<String, int> rowMaxStackDepth;
  final List<GanttCategoryTree> categoryTrees;

  const GanttChartData({
    required this.tasks,
    required this.rows,
    required this.rowMaxStackDepth,
    required this.categoryTrees,
  });
}

class GanttCategoryTree {
  final String categoryId;
  final String categoryName;
  final int sortOrder;
  final List<GanttProcessLeaf> processes;
  final DateTime start;
  final DateTime end;

  const GanttCategoryTree({
    required this.categoryId,
    required this.categoryName,
    required this.sortOrder,
    required this.processes,
    required this.start,
    required this.end,
  });
}

class GanttProcessLeaf {
  final String stepId;
  final String displayName;
  final int sortOrder;
  final String taskId;
  final String rowId;
  final DateTime start;
  final DateTime end;

  const GanttProcessLeaf({
    required this.stepId,
    required this.displayName,
    required this.sortOrder,
    required this.taskId,
    required this.rowId,
    required this.start,
    required this.end,
  });
}

/// 日次進捗の1エントリー（アダプター内部で使用）
class GanttDailyEntry {
  final DateTime date;
  const GanttDailyEntry({required this.date});
}

// ─────────────────────────────────────────────
// アダプター本体
// ─────────────────────────────────────────────

class GanttDataAdapter {
  /// 工程名（文字列）から一意の色（Color）を生成するヘルパー。
  /// 文字列のハッシュ値を元にHSLの色相（Hue）を決定し、一定の彩度・明度で統一感のある色を返す。
  static Color _getColorForProcess(String processName, {bool isChild = false}) {
    if (processName.isEmpty) return Colors.blue;
    // hashCode を 360 の範囲に収める
    final double hue = processName.hashCode.abs() % 360.0;
    
    if (isChild) {
      // 子タスク: 透明度ではなく色そのものを薄く（明るく）設定
      return HSLColor.fromAHSL(1.0, hue, 0.45, 0.85).toColor();
    } else {
      // 親タスク: 濃いめのベースカラー
      return HSLColor.fromAHSL(1.0, hue, 0.65, 0.45).toColor();
    }
  }

  /// ProcessProgressDailyRepository から取得した日次進捗データを元に変換する。
  ///
  /// [progressByStepId] : stepId → { productId → [GanttDailyEntry] }
  ///   ※ ProcessProgressDailyRepository.fetchDaily() で得た ProcessProgressDaily.stepId をキーにする。
  ///   ※ stepId = processMasters / processSteps の Firestore doc ID に相当する。
  static GanttChartData convertFromDaily({
    required List<Product> products,
    required Map<String, Map<String, List<GanttDailyEntry>>> progressByStepId,
    required List<ProcessGroup> groups,
    required List<ProcessStep> steps,
  }) {
    final DateTime fallbackStart = DateTime.now();
    final DateTime fallbackEnd = fallbackStart.add(const Duration(days: 30));

    // stepId ごとに全製品を横断した最小開始・最大終了日を計算
    final Map<String, DateTime> stepMinStart = {};
    final Map<String, DateTime> stepMaxEnd = {};

    progressByStepId.forEach((stepId, byProduct) {
      for (final entries in byProduct.values) {
        for (final e in entries) {
          final d = e.date;
          if (!stepMinStart.containsKey(stepId) || d.isBefore(stepMinStart[stepId]!)) {
            stepMinStart[stepId] = d;
          }
          if (!stepMaxEnd.containsKey(stepId) || d.isAfter(stepMaxEnd[stepId]!)) {
            stepMaxEnd[stepId] = d;
          }
        }
      }
      // エントリーが空の場合はフォールバック
      if (!stepMinStart.containsKey(stepId)) {
        stepMinStart[stepId] = fallbackStart;
        stepMaxEnd[stepId] = fallbackEnd;
      }
    });

    final activeStepIds = progressByStepId.keys.toSet();

    return _build(
      activeStepIds: activeStepIds,
      stepMinStart: stepMinStart,
      stepMaxEnd: stepMaxEnd,
      groups: groups,
      steps: steps,
      fallbackStart: fallbackStart,
      fallbackEnd: fallbackEnd,
    );
  }

  /// ProcessProgress リストから変換する（将来拡張用）
  static GanttChartData convert({
    required List<Product> products,
    required Map<String, List<ProcessProgress>> progressByProductId,
    required List<ProcessGroup> groups,
    required List<ProcessStep> steps,
  }) {
    final DateTime fallbackStart = DateTime.now();
    final DateTime fallbackEnd = fallbackStart.add(const Duration(days: 30));

    final Map<String, DateTime> stepMinStart = {};
    final Map<String, DateTime> stepMaxEnd = {};

    for (final product in products) {
      final progresses = progressByProductId[product.id] ?? [];
      for (final p in progresses) {
        final s = p.startDate ?? fallbackStart;
        final e = p.endDate ?? fallbackEnd;
        if (!stepMinStart.containsKey(p.processId) || s.isBefore(stepMinStart[p.processId]!)) {
          stepMinStart[p.processId] = s;
        }
        if (!stepMaxEnd.containsKey(p.processId) || e.isAfter(stepMaxEnd[p.processId]!)) {
          stepMaxEnd[p.processId] = e;
        }
      }
    }

    final activeStepIds = stepMinStart.keys.toSet();

    return _build(
      activeStepIds: activeStepIds,
      stepMinStart: stepMinStart,
      stepMaxEnd: stepMaxEnd,
      groups: groups,
      steps: steps,
      fallbackStart: fallbackStart,
      fallbackEnd: fallbackEnd,
    );
  }

  // ── 内部共通ビルダー ──
  static GanttChartData _build({
    required Set<String> activeStepIds,
    required Map<String, DateTime> stepMinStart,
    required Map<String, DateTime> stepMaxEnd,
    required List<ProcessGroup> groups,
    required List<ProcessStep> steps,
    required DateTime fallbackStart,
    required DateTime fallbackEnd,
  }) {
    final sortedGroups = [...groups]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final List<LegacyGanttTask> tasks = [];
    final List<LegacyGanttRow> rows = [];
    final Map<String, int> rowMaxStackDepth = {};
    final List<GanttCategoryTree> categoryTrees = [];

    for (final group in sortedGroups) {
      final categoryRowId = 'cat_${group.id}';

      // このグループに属するステップを sortOrder 順に取得
      final groupSteps = steps
          .where((s) => s.groupId == group.id)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      // 実際に進捗データが存在するステップのみ
      final activeSteps = groupSteps.where((s) => activeStepIds.contains(s.id)).toList();
      if (activeSteps.isEmpty) continue;

      // グループ（親）の期間
      final catStart = activeSteps
          .map((s) => stepMinStart[s.id] ?? fallbackStart)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      final catEnd = activeSteps
          .map((s) => stepMaxEnd[s.id] ?? fallbackEnd)
          .reduce((a, b) => a.isAfter(b) ? a : b);

      final List<GanttProcessLeaf> leaves = [];

      // ── 同じ label を持つステップは1行に統合（期間はunion） ──
      // processMasters に部材タイプごとに同一工程名が複数存在する場合の重複排除
      final Map<String, _MergedStep> mergedByLabel = {};
      for (final step in activeSteps) {
        final pStart = stepMinStart[step.id] ?? fallbackStart;
        final pEnd = stepMaxEnd[step.id] ?? fallbackEnd;
        if (!mergedByLabel.containsKey(step.label)) {
          mergedByLabel[step.label] = _MergedStep(
            label: step.label,
            sortOrder: step.sortOrder,
            start: pStart,
            end: pEnd,
          );
        } else {
          final m = mergedByLabel[step.label]!;
          if (pStart.isBefore(m.start)) m.start = pStart;
          if (pEnd.isAfter(m.end)) m.end = pEnd;
        }
      }

      // sortOrder 順に並べ替えて行を作成
      final mergedSteps = mergedByLabel.values.toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      // このカテゴリ（グループ）のベースカラーを生成
      final Color baseColor = _getColorForProcess(group.label, isChild: false);
      // 子タスクはそのベースカラーを薄く（明るく）したものを使用
      final Color childColor = _getColorForProcess(group.label, isChild: true);

      for (final merged in mergedSteps) {
        final processRowId = '${categoryRowId}_${merged.label}';

        tasks.add(LegacyGanttTask(
          id: processRowId,
          rowId: processRowId,
          name: merged.label,
          parentId: categoryRowId,
          start: merged.start,
          end: merged.end,
          color: childColor, // 所属するグループの薄い色を使用
        ));
        rows.add(LegacyGanttRow(id: processRowId, label: merged.label));
        rowMaxStackDepth[processRowId] = 1;

        leaves.add(GanttProcessLeaf(
          stepId: processRowId,
          displayName: merged.label,
          sortOrder: merged.sortOrder,
          taskId: processRowId,
          rowId: processRowId,
          start: merged.start,
          end: merged.end,
        ));
      }

      // カテゴリ（親）タスクを子の前に挿入
      final insertIdx = tasks.length - leaves.length;

      // TODO: 本番では実際の計画日（予定日）を使用する
      // 実績期間より少し前倒しのダミー計画期間を生成（予実比較テスト用）
      final dummyPlanStart = catStart.subtract(const Duration(days: 2));
      final dummyPlanEnd = catEnd.subtract(const Duration(days: 1));

      tasks.insert(insertIdx, LegacyGanttTask(
        id: categoryRowId,
        rowId: categoryRowId,
        name: group.label,
        start: catStart,
        end: catEnd,
        isSummary: true,
        color: baseColor, // グループ名ベースの濃い色を使用
        baselineStart: dummyPlanStart, // 計画開始日
        baselineEnd: dummyPlanEnd,     // 計画終了日
      ));
      rows.insert(insertIdx, LegacyGanttRow(id: categoryRowId, label: group.label));
      rowMaxStackDepth[categoryRowId] = 1;

      categoryTrees.add(GanttCategoryTree(
        categoryId: group.id,
        categoryName: group.label,
        sortOrder: group.sortOrder,
        processes: leaves,
        start: catStart,
        end: catEnd,
      ));
    }

    // ── 【新規】最上部に「プロジェクトイベント」を追加 ──
    final String eventRootId = 'prj_events_root';
    final DateTime eventDate1 = fallbackStart.add(const Duration(days: 5));
    final DateTime eventDate2 = fallbackStart.add(const Duration(days: 10)); // 追加: 第三者検査
    final DateTime eventDate3 = fallbackStart.add(const Duration(days: 15));
    
    // イベントデータを個別のタスクとして同じ行（eventRootId）に追加
    final List<Map<String, dynamic>> projectEvents = [
      {'id': '${eventRootId}_1', 'name': '材料入荷', 'date': eventDate1},
      {'id': '${eventRootId}_2', 'name': '第三者検査', 'date': eventDate2},
      {'id': '${eventRootId}_3', 'name': '立会検査', 'date': eventDate3},
    ];

    for (final evt in projectEvents) {
      final evtDate = evt['date'] as DateTime;
      tasks.insert(0, LegacyGanttTask(
        id: evt['id'] as String,
        rowId: eventRootId, // 同じ行に描画
        name: evt['name'] as String,
        start: evtDate,
        end: evtDate.add(const Duration(days: 1)),
        isSummary: false,
        color: Colors.transparent, // 背景透明
      ));
    }
    
    // 行データの追加
    rows.insert(0, LegacyGanttRow(id: eventRootId, label: 'プロジェクトイベント'));
    rowMaxStackDepth[eventRootId] = 1;

    categoryTrees.insert(0, GanttCategoryTree(
      categoryId: eventRootId,
      categoryName: 'プロジェクトイベント',
      sortOrder: -1,
      processes: [], // 左ペインでは展開しないため空
      start: fallbackStart,
      end: fallbackEnd,
    ));
    // ───────────────────────────────────────────

    return GanttChartData(
      tasks: tasks,
      rows: rows,
      rowMaxStackDepth: rowMaxStackDepth,
      categoryTrees: categoryTrees,
    );
  }
}

/// 内部ヘルパー: 同一ラベルのステップをマージするための可変データクラス
class _MergedStep {
  final String label;
  final int sortOrder;
  DateTime start;
  DateTime end;

  _MergedStep({
    required this.label,
    required this.sortOrder,
    required this.start,
    required this.end,
  });
}
