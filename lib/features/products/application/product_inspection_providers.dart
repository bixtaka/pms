import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../process_spec/data/process_progress_daily_repository.dart';
import '../../process_spec/data/process_groups_repository.dart';
import '../../process_spec/data/process_steps_repository.dart';
import '../../process_spec/domain/process_progress_daily.dart';
import '../../process_spec/domain/process_group.dart';
import '../../process_spec/domain/process_step.dart';
import '../../../providers/product_providers.dart';
import '../../../models/product.dart';

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

List<ProcessProgressDaily> computeLatestByStep(List<ProcessProgressDaily> list) {
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
  return result;
}

@immutable
class LatestProgressKey {
  final String projectId;
  final String productId;

  const LatestProgressKey({required this.projectId, required this.productId});

  @override
  bool operator ==(Object other) =>
      other is LatestProgressKey &&
      other.projectId == projectId &&
      other.productId == productId;

  @override
  int get hashCode => Object.hash(projectId, productId);
}

final dailyProgressByProductProvider = FutureProvider.autoDispose
    .family<List<ProcessProgressDaily>, DailyProgressKey>((ref, key) async {
  final repo = ref.watch(processProgressDailyRepositoryProvider);
  final list = await repo.fetchDaily(key.projectId, key.productId);
  // 各 (productId, stepId) ごとに日付降順で最新1件を採用（画面は日付指定なしで最新状態を表示する）
  final result = computeLatestByStep(list);
  if (kDebugMode) {
    debugPrint(
        '[status] rows=${list.length} latestKeys=${result.length} sample=${result.take(5).map((e) => e.stepId).toList()}');
  }
  return result;
});

final latestProgressByProductProvider = FutureProvider.autoDispose
    .family<List<ProcessProgressDaily>, LatestProgressKey>((ref, key) async {
  final repo = ref.watch(processProgressDailyRepositoryProvider);
  final list = await repo.fetchDaily(key.projectId, key.productId);
  return computeLatestByStep(list);
});

/// プロジェクト内の全製品について、(productId, stepId) ごと最新日1件を集計したマップ
final latestProgressMapByProjectProvider = FutureProvider.autoDispose
    .family<Map<String, Map<String, ProcessProgressDaily>>, String>((ref, projectId) async {
  final repo = ref.watch(processProgressDailyRepositoryProvider);
  final List<Product> products = await ref.watch(productsByProjectProvider(projectId).future);
  final result = <String, Map<String, ProcessProgressDaily>>{};
  for (final product in products) {
    final list = await repo.fetchDaily(projectId, product.id);
    final latest = computeLatestByStep(list);
    result[product.id] = {for (final d in latest) d.stepId: d};
  }
  return result;
});
