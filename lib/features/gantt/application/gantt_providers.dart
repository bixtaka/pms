import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/project.dart';
import '../data/gantt_repository.dart';
import '../domain/gantt_repository.dart';
import '../presentation/gantt_screen.dart' show GanttProduct;
import '../../process_spec/data/process_groups_repository.dart';
import '../../process_spec/data/process_steps_repository.dart';
import '../../process_spec/domain/process_group.dart';
import '../../process_spec/domain/process_step.dart';

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
