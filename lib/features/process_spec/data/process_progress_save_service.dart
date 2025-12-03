import '../domain/process_progress_daily.dart';
import 'process_progress_daily_repository.dart';

/// 進捗保存のラッパー（idempotent upsert）
/// Firestore 構造や SPEC フィールドは変更せず、同じ productId+stepId+date なら上書きする。
class ProcessProgressSaveService {
  final ProcessProgressDailyRepository _dailyRepo;
  ProcessProgressSaveService({ProcessProgressDailyRepository? dailyRepo})
      : _dailyRepo = dailyRepo ?? ProcessProgressDailyRepository();

  Future<void> upsertDaily({
    required String projectId,
    required String productId,
    required String stepId,
    required DateTime date,
    required int doneQty,
    String note = '',
  }) async {
    final requestedDate = DateTime(date.year, date.month, date.day);
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final clampedDate =
        requestedDate.isAfter(todayOnly) ? todayOnly : requestedDate;
    final safeDoneQty = doneQty < 0 ? 0 : doneQty;

    await _dailyRepo.upsertDaily(
      projectId: projectId,
      productId: productId,
      stepId: stepId,
      date: clampedDate,
      doneQty: safeDoneQty,
      note: note,
    );
  }

  Future<void> deleteDaily({
    required String projectId,
    required String productId,
    required String stepId,
    required DateTime date,
  }) async {
    final requestedDate = DateTime(date.year, date.month, date.day);
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final clampedDate =
        requestedDate.isAfter(todayOnly) ? todayOnly : requestedDate;
    await _dailyRepo.deleteDaily(
      projectId: projectId,
      productId: productId,
      stepId: stepId,
      date: clampedDate,
    );
  }

  /// UI などが渡してくる既存 ProcessProgressDaily をそのまま上書き保存するヘルパー
  Future<void> upsertDailyModel({
    required String projectId,
    required ProcessProgressDaily daily,
  }) =>
      upsertDaily(
        projectId: projectId,
        productId: daily.productId,
        stepId: daily.stepId,
        date: daily.date,
        doneQty: daily.doneQty,
        note: daily.note,
      );
}
