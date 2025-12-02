import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/project.dart';
import '../data/gantt_repository.dart';
import '../domain/gantt_repository.dart';
import '../presentation/gantt_screen.dart' show GanttProduct;
import '../../process_spec/data/process_groups_repository.dart';
import '../../process_spec/data/process_progress_daily_repository.dart';
import '../../process_spec/data/process_steps_repository.dart';
import '../../process_spec/domain/process_group.dart';
import '../../process_spec/domain/process_step.dart';
import 'product_gantt_progress_service.dart';

class ProcessSpecData {
  final List<ProcessGroup> groups;
  final List<ProcessStep> steps;

  const ProcessSpecData({
    required this.groups,
    required this.steps,
  });
}

/// リポジトリを DI するプロバイダ
final ganttRepositoryProvider = Provider<GanttRepository>((ref) {
  return FirestoreGanttRepository();
});

/// 指定プロジェクトのガント用製品＋タスク一覧を取得
final ganttProductsProvider =
    FutureProvider.family<List<GanttProduct>, Project>((ref, project) async {
      final repo = ref.watch(ganttRepositoryProvider);
      return repo.fetchGanttProductsByProjectId(project.id);
    });

/// ガント画面で使用する process_groups / process_steps 一覧
final ganttProcessSpecProvider = FutureProvider<ProcessSpecData>((ref) async {
  final groupsRepo = ProcessGroupsRepository();
  final stepsRepo = ProcessStepsRepository();
  final groups = await groupsRepo.fetchAll();
  final steps = await stepsRepo.fetchAll();
  return ProcessSpecData(groups: groups, steps: steps);
});

final productGanttProgressServiceProvider =
    Provider<ProductGanttProgressService>((ref) {
  return ProductGanttProgressService(ProcessProgressDailyRepository());
});

final productGanttBarsProvider =
    FutureProvider.autoDispose.family<List<ProductGanttBar>, Project>(
        (ref, project) async {
  final products = await ref.watch(ganttProductsProvider(project).future);
  if (products.isEmpty) return [];

  DateTime? minStart;
  DateTime? maxEnd;
  for (final p in products) {
    for (final t in p.tasks) {
      minStart = minStart == null || t.start.isBefore(minStart)
          ? t.start
          : minStart;
      maxEnd = maxEnd == null || t.end.isAfter(maxEnd) ? t.end : maxEnd;
    }
  }

  final now = DateTime.now();
  DateTime rangeStart;
  DateTime rangeEnd;
  if (minStart == null || maxEnd == null) {
    rangeStart = DateTime(now.year, now.month, now.day).subtract(
      const Duration(days: 3),
    );
    rangeEnd = rangeStart.add(const Duration(days: 13));
  } else {
    rangeStart = minStart!;
    rangeEnd = maxEnd!;
    final minDays = 14;
    final totalDays = rangeEnd.difference(rangeStart).inDays + 1;
    if (totalDays < minDays) {
      rangeEnd = rangeStart.add(Duration(days: minDays - 1));
    }
  }

  final ids = products.map((p) => p.id).toList();
  final service = ref.watch(productGanttProgressServiceProvider);
  final daily = await service.fetchDailyProgressForRange(
    projectId: project.id,
    start: rangeStart,
    end: rangeEnd,
    productIds: ids,
  );
  final qtyMap = {for (final p in products) p.id: p.quantity};
  return service.buildBarsFromDaily(
    daily,
    productQuantities: qtyMap,
  );
});
