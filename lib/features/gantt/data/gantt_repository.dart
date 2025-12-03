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
            : taskList
                .map((t) => t.progress)
                .fold<double>(0.0, (a, b) => a + b) /
                taskList.length;
        return GanttProduct(
          id: product.id,
          code: product.productCode.isNotEmpty
              ? product.productCode
              : product.name,
          name: product.name.isNotEmpty ? product.name : product.productCode,
          memberType: product.memberType,
          progress: avgProgress.isNaN ? 0.0 : avgProgress,
          quantity: product.quantity,
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

    final tasks = <GanttTask>[];
    for (final entry in stepsMap.entries) {
      final stepId = entry.key;
      final step = entry.value;
      final group = groupsMap[step.groupId];
      final dailyList = groupedByStep[stepId] ?? const <ProcessProgressDaily>[];

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
      final progress =
          (doneSum / (totalQty > 0 ? totalQty : 1)).clamp(0.0, 1.0);

      tasks.add(
        GanttTask(
          id: stepId,
          name: step.label,
          type: _mapProcessType(step.label, groups, step),
          start: start,
          end: end,
          progress: progress.isNaN ? 0.0 : progress,
          plannedEnd: plannedEnd,
          stepId: step.id,
          stepKey: step.key,
          stepLabel: step.label,
          stepSort: step.sortOrder,
          processGroupId: group?.id,
          processGroupKey: group?.key,
          processGroupLabel: group?.label,
          processGroupSort: group?.sortOrder,
        ),
      );
    }

    // 進捗のみ存在しているが steps にない stepId も補完
    for (final entry in groupedByStep.entries) {
      final stepId = entry.key;
      if (stepsMap.containsKey(stepId)) continue;
      final dailyList = entry.value;
      DateTime start = dailyList
          .map((d) => d.date)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      DateTime end = dailyList
          .map((d) => d.date)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      if (end.isBefore(start)) end = start;
      final totalQty = product.quantity > 0 ? product.quantity : 1;
      final doneSum = dailyList.fold<int>(0, (prev, e) => prev + e.doneQty);
      final progress =
          (doneSum / (totalQty > 0 ? totalQty : 1)).clamp(0.0, 1.0);

      tasks.add(
        GanttTask(
          id: stepId,
          name: stepId,
          type: _mapProcessType(stepId, groups, null),
          start: start,
          end: end,
          progress: progress.isNaN ? 0.0 : progress,
          plannedEnd: plannedEnd,
          stepId: stepId,
          stepKey: stepId,
          stepLabel: stepId,
          stepSort: 9999,
          processGroupId: null,
          processGroupKey: null,
          processGroupLabel: null,
          processGroupSort: 9999,
        ),
      );
    }

    tasks.sort((a, b) {
      final groupSortA = a.processGroupSort ?? 9999;
      final groupSortB = b.processGroupSort ?? 9999;
      if (groupSortA != groupSortB) {
        return groupSortA.compareTo(groupSortB);
      }
      final stepSortA = a.stepSort ?? 9999;
      final stepSortB = b.stepSort ?? 9999;
      if (stepSortA != stepSortB) {
        return stepSortA.compareTo(stepSortB);
      }
      return a.name.compareTo(b.name);
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
