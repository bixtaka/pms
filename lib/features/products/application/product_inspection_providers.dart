import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../process_spec/data/process_progress_daily_repository.dart';
import '../../process_spec/data/process_groups_repository.dart';
import '../../process_spec/data/process_steps_repository.dart';
import '../../process_spec/domain/process_progress_daily.dart';
import '../../process_spec/domain/process_group.dart';
import '../../process_spec/domain/process_step.dart';

/// 日別進捗のキー（product + 日付 + step を組み合わせる前段階）
@immutable
class DailyProgressKey {
  final String projectId;
  final String productId;
  final DateTime date;

  const DailyProgressKey({
    required this.projectId,
    required this.productId,
    required this.date,
  });

  DateTime get dateOnly => DateTime(date.year, date.month, date.day);

  @override
  bool operator ==(Object other) =>
      other is DailyProgressKey &&
      other.projectId == projectId &&
      other.productId == productId &&
      other.dateOnly.year == dateOnly.year &&
      other.dateOnly.month == dateOnly.month &&
      other.dateOnly.day == dateOnly.day;

  @override
  int get hashCode =>
      Object.hash(projectId, productId, dateOnly.year, dateOnly.month, dateOnly.day);
}

final inspectionProcessStepsProvider =
    FutureProvider.autoDispose<List<ProcessStep>>((ref) async {
  final repo = ProcessStepsRepository();
  return repo.fetchAll();
});

final inspectionProcessGroupsProvider =
    FutureProvider.autoDispose<List<ProcessGroup>>((ref) async {
  final repo = ProcessGroupsRepository();
  return repo.fetchAll();
});

final processProgressDailyRepositoryProvider =
    Provider<ProcessProgressDailyRepository>((ref) {
  return ProcessProgressDailyRepository();
});

final dailyProgressByProductProvider = FutureProvider.autoDispose
    .family<List<ProcessProgressDaily>, DailyProgressKey>((ref, key) async {
  final repo = ref.watch(processProgressDailyRepositoryProvider);
  final list = await repo.fetchDaily(key.projectId, key.productId);
  // 各 (productId, stepId) ごとに日付降順で最新1件を採用（画面は日付指定なしで最新状態を表示する）
  final latestByKey = <String, ProcessProgressDaily>{};
  DateTime _toDateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  for (final d in list) {
    final key = '${d.productId}|${d.stepId}';
    final existing = latestByKey[key];
    if (existing == null) {
      latestByKey[key] = d;
      continue;
    }
    final existingDate = _toDateOnly(existing.date);
    final currentDate = _toDateOnly(d.date);
    if (currentDate.isAfter(existingDate)) {
      latestByKey[key] = d;
    }
  }
  final result = latestByKey.values.toList()
    ..sort((a, b) => a.stepId.compareTo(b.stepId));
  if (kDebugMode) {
    debugPrint(
        '[status] rows=${list.length} latestKeys=${latestByKey.length} sample=${latestByKey.keys.take(5).toList()}');
  }
  return result;
});
