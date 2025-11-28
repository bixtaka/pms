import 'package:collection/collection.dart';
import '../../../models/product.dart';
import '../../process_spec/data/process_groups_repository.dart';
import '../../process_spec/data/process_progress_daily_repository.dart';
import '../../process_spec/data/process_steps_repository.dart';
import '../../process_spec/domain/process_group.dart';
import '../../process_spec/domain/process_progress_daily.dart';
import '../../process_spec/domain/process_step.dart';
import '../../products/data/product_repository.dart';
import '../domain/gantt_repository.dart';
import '../presentation/gantt_screen.dart'
    show GanttProduct, GanttTask, ProcessType;
import '../../../models/process_progress.dart';

/// 旧 UI（widgets/gantt_chart.dart など）が参照する簡易モデル（互換用）
class GanttItem {
  final String productId;
  final String productCode;
  final DateTime? overallStartDate;
  final DateTime? overallEndDate;
  final Map<String, ProcessProgress> processes; // key: processId

  GanttItem({
    required this.productId,
    required this.productCode,
    required this.overallStartDate,
    required this.overallEndDate,
    required this.processes,
  });
}

/// Firestore から製品＋工程進捗を集約してガント用モデルへ変換する実装
class FirestoreGanttRepository implements GanttRepository {
  final ProductRepository _productRepo;
  final ProcessGroupsRepository _groupsRepo;
  final ProcessStepsRepository _stepsRepo;
  final ProcessProgressDailyRepository _dailyRepo;

  FirestoreGanttRepository({
    ProductRepository? productRepo,
    ProcessGroupsRepository? groupsRepo,
    ProcessStepsRepository? stepsRepo,
    ProcessProgressDailyRepository? dailyRepo,
  }) : _productRepo = productRepo ?? ProductRepository(),
       _groupsRepo = groupsRepo ?? ProcessGroupsRepository(),
       _stepsRepo = stepsRepo ?? ProcessStepsRepository(),
       _dailyRepo = dailyRepo ?? ProcessProgressDailyRepository();

  @override
  Future<List<GanttProduct>> fetchGanttProductsByProjectId(
    String projectId,
  ) async {
    final products = await _productRepo.streamByProject(projectId).first;
    final groups = await _groupsRepo.fetchAll();
    final steps = await _stepsRepo.fetchAll();

    return Future.wait(
      products.map((product) async {
        final dailies = await _dailyRepo.fetchDaily(projectId, product.id);
        final taskList = _buildTasks(product, steps, groups, dailies);
        final avgProgress = taskList.isEmpty
            ? 0.0
            : taskList.map((t) => t.progress).average;
        return GanttProduct(
          id: product.id,
          code: product.productCode.isNotEmpty
              ? product.productCode
              : product.name,
          name: product.name.isNotEmpty ? product.name : product.productCode,
          progress: avgProgress.isNaN ? 0.0 : avgProgress,
          tasks: taskList,
        );
      }),
    );
  }

  List<GanttTask> _buildTasks(
    Product product,
    List<ProcessStep> steps,
    List<ProcessGroup> groups,
    List<ProcessProgressDaily> dailies,
  ) {
    // 製品レベルの予定完了日（プレゼンテーション用のみ）
    final DateTime? plannedEnd = product.overallEndDate ?? product.endDate;
    final stepsMap = {for (final s in steps) s.id: s};
    final groupsMap = {for (final g in groups) g.id: g};

    // stepId ごとに日別進捗をまとめる
    final groupedByStep = <String, List<ProcessProgressDaily>>{};
    for (final d in dailies) {
      groupedByStep
          .putIfAbsent(d.stepId, () => <ProcessProgressDaily>[])
          .add(d);
    }

    // ラベル（工程名）単位で集約することで、同じ工程名が複数 stepId にまたがっていても 1 行にまとめる
    final Map<String, _AggregatedTask> byLabel = {};

    final stepIds = <String>{...stepsMap.keys, ...groupedByStep.keys};

    for (final stepId in stepIds) {
      final step = stepsMap[stepId];
      final dailyList = groupedByStep[stepId] ?? [];
      final label = (step?.label ?? stepId).trim();
      final group =
          step != null ? groupsMap[step.groupId] : null; // step -> group へ紐付け

      if (label.isEmpty) {
        continue;
      }

      DateTime start;
      DateTime end;
      if (dailyList.isEmpty) {
        start = product.overallStartDate ?? product.startDate ?? DateTime.now();
        end = product.overallEndDate ?? product.endDate ?? start;
      } else {
        start = dailyList
            .map((d) => d.date)
            .reduce((a, b) => a.isBefore(b) ? a : b);
        end = dailyList
            .map((d) => d.date)
            .reduce((a, b) => a.isAfter(b) ? a : b);
      }
      if (end.isBefore(start)) end = start;

      final totalQty = product.quantity > 0 ? product.quantity : 1;
      final doneSum = dailyList.fold<int>(0, (prev, e) => prev + e.doneQty);

      final existing = byLabel[label];
      if (existing == null) {
        byLabel[label] = _AggregatedTask(
          label: label,
          stepId: stepId,
          start: start,
          end: end,
          doneQty: doneSum,
          totalQty: totalQty,
          sortOrder: step?.sortOrder ?? 999,
          processGroupId: group?.id,
          processGroupKey: group?.key,
          processGroupLabel: group?.label,
          processGroupSort: group?.sortOrder,
        );
      } else {
        byLabel[label] = existing.merge(
          otherStart: start,
          otherEnd: end,
          otherDoneQty: doneSum,
          otherSortOrder: step?.sortOrder,
        );
      }
    }

    final tasks =
        byLabel.values.map((agg) {
          final progress = (agg.doneQty / (agg.totalQty > 0 ? agg.totalQty : 1))
              .clamp(0.0, 1.0);
          return GanttTask(
            id: agg.stepId,
            name: agg.label,
            type: _mapProcessType(agg.label, groups, stepsMap[agg.stepId]),
            start: agg.start,
            end: agg.end,
            progress: progress.isNaN ? 0.0 : progress,
            plannedEnd: plannedEnd,
            processGroupId: agg.processGroupId,
            processGroupKey: agg.processGroupKey,
            processGroupLabel: agg.processGroupLabel,
            processGroupSort: agg.processGroupSort,
          );
        }).toList()..sort((a, b) {
          final orderA = byLabel[a.name]?.sortOrder ?? 999;
          final orderB = byLabel[b.name]?.sortOrder ?? 999;
          return orderA.compareTo(orderB);
        });

    return tasks;
  }

  ProcessType _mapProcessType(
    String label,
    List<ProcessGroup> groups,
    ProcessStep? step,
  ) {
    final key = (label.isNotEmpty ? label : step?.key ?? '').toLowerCase();
    if (key.contains('コア') && key.contains('組')) {
      return ProcessType.coreAssembly;
    }
    if (key.contains('コア') && key.contains('溶')) {
      return ProcessType.coreWeld;
    }
    if (key.contains('仕口') && key.contains('組')) {
      return ProcessType.jointAssembly;
    }
    if (key.contains('仕口') && key.contains('溶')) {
      return ProcessType.jointWeld;
    }
    return ProcessType.other;
  }
}

/// 1 製品内の同名工程（ラベル）を集約するための中間モデル
class _AggregatedTask {
  final String label;
  final String stepId;
  final DateTime start;
  final DateTime end;
  final int doneQty;
  final int totalQty;
  final int sortOrder;
  final String? processGroupId;
  final String? processGroupKey;
  final String? processGroupLabel;
  final int? processGroupSort;

  const _AggregatedTask({
    required this.label,
    required this.stepId,
    required this.start,
    required this.end,
    required this.doneQty,
    required this.totalQty,
    required this.sortOrder,
    this.processGroupId,
    this.processGroupKey,
    this.processGroupLabel,
    this.processGroupSort,
  });

  _AggregatedTask merge({
    required DateTime otherStart,
    required DateTime otherEnd,
    required int otherDoneQty,
    int? otherSortOrder,
  }) {
    final mergedStart = otherStart.isBefore(start) ? otherStart : start;
    final mergedEnd = otherEnd.isAfter(end) ? otherEnd : end;
    final mergedDone = doneQty + otherDoneQty;
    final mergedSort = otherSortOrder != null
        ? (otherSortOrder < sortOrder ? otherSortOrder : sortOrder)
        : sortOrder;
    return _AggregatedTask(
      label: label,
      stepId: stepId,
      start: mergedStart,
      end: mergedEnd,
      doneQty: mergedDone,
      totalQty: totalQty,
      sortOrder: mergedSort,
      processGroupId: processGroupId,
      processGroupKey: processGroupKey,
      processGroupLabel: processGroupLabel,
      processGroupSort: processGroupSort,
    );
  }
}
