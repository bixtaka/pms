import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../process_spec/data/process_progress_daily_repository.dart';
import '../../process_spec/data/process_steps_repository.dart';
import '../../process_spec/domain/process_progress_daily.dart';
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

final processProgressDailyRepositoryProvider =
    Provider<ProcessProgressDailyRepository>((ref) {
  return ProcessProgressDailyRepository();
});

final dailyProgressByProductProvider = FutureProvider.autoDispose
    .family<List<ProcessProgressDaily>, DailyProgressKey>((ref, key) async {
  final repo = ref.watch(processProgressDailyRepositoryProvider);
  final list = await repo.fetchDaily(key.projectId, key.productId);
  final target = key.dateOnly;
  return list
      .where(
        (d) =>
            d.date.year == target.year &&
            d.date.month == target.month &&
            d.date.day == target.day,
      )
      .toList();
});
