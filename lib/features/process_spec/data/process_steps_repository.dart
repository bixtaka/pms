import '../domain/process_step.dart';
import 'process_groups_repository.dart';

/// SPEC の process_steps を提供するアダプタ
/// 現状 Firestore に steps コレクションが無いため、process_groups から擬似 step を生成する
class ProcessStepsRepository {
  final ProcessGroupsRepository _groupsRepo;

  ProcessStepsRepository({ProcessGroupsRepository? groupsRepo})
    : _groupsRepo = groupsRepo ?? ProcessGroupsRepository();

  /// 現在は group をそのまま step とみなして返す（key/label/sort_order を踏襲）
  Future<List<ProcessStep>> fetchAll() async {
    final groups = await _groupsRepo.fetchAll();
    return groups
        .map(
          (g) => ProcessStep(
            id: g.id,
            groupId: g.id,
            key: g.key,
            label: g.label,
            sortOrder: g.sortOrder,
          ),
        )
        .toList();
  }
}
