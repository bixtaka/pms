import '../../process_spec/data/process_progress_daily_repository.dart';

DateTime _toDateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// 1日分の工程実績
class ProductStepDailyProgress {
  final String productId;
  final String stepId;
  final DateTime date;
  final int doneQty;
  final bool inProgress;

  const ProductStepDailyProgress({
    required this.productId,
    required this.stepId,
    required this.date,
    required this.doneQty,
    required this.inProgress,
  });
}

enum GanttBarKind { planned, actual }

enum GanttBarStatus { notStarted, inProgress, done }

GanttBarStatus _statusFromDoneQty({
  required int doneQty,
  required bool isCompleted,
}) {
  if (doneQty <= 0) return GanttBarStatus.inProgress;
  return isCompleted ? GanttBarStatus.done : GanttBarStatus.inProgress;
}

/// ガントに描画する連続実績バー
class ProductGanttBar {
  final String productId;
  final String stepId;
  final DateTime startDate;
  final DateTime endDate;
  final int totalDoneQty;
  final bool isCompleted;
  final GanttBarKind kind;
  final GanttBarStatus status;

  const ProductGanttBar({
    required this.productId,
    required this.stepId,
    required this.startDate,
    required this.endDate,
    required this.totalDoneQty,
    required this.isCompleted,
    required this.kind,
    required this.status,
  });
}

/// 日別進捗をまとめて取得し、ガント用バーへ変換するサービス
class ProductGanttProgressService {
  final ProcessProgressDailyRepository dailyRepo;

  ProductGanttProgressService(this.dailyRepo);

  /// 指定期間＋製品リストの実績（日単位）をまとめて取得
  Future<List<ProductStepDailyProgress>> fetchDailyProgressForRange({
    required String projectId,
    required DateTime start,
    required DateTime end,
    List<String>? productIds,
  }) async {
    final targets = productIds ?? const <String>[];
    if (targets.isEmpty) return const [];
    final startOnly = _toDateOnly(start);
    final endOnly = _toDateOnly(end);
    final result = <ProductStepDailyProgress>[];

    for (final productId in targets) {
      final dailies = await dailyRepo.fetchDaily(projectId, productId);
      for (final d in dailies) {
        final dateOnly = _toDateOnly(d.date);
        if (dateOnly.isBefore(startOnly) || dateOnly.isAfter(endOnly)) continue;
        final safeQty = d.doneQty < 0 ? 0 : d.doneQty;
        final inProgress = safeQty <= 0;
        result.add(
          ProductStepDailyProgress(
            productId: productId,
            stepId: d.stepId,
            date: dateOnly,
            doneQty: safeQty,
            inProgress: inProgress,
          ),
        );
      }
    }
    return result;
  }

  /// 日別実績を連続バーへ変換（同一productId+stepIdで隣接日をまとめる）
  List<ProductGanttBar> buildBarsFromDaily(
    List<ProductStepDailyProgress> list, {
    Map<String, int>? productQuantities,
  }) {
    if (list.isEmpty) return const [];
    final grouped = <String, List<ProductStepDailyProgress>>{};
    for (final d in list) {
      // 実績 or 作業中のみ対象
      if (d.doneQty <= 0 && !d.inProgress) continue;
      final key = '${d.productId}__${d.stepId}';
      grouped.putIfAbsent(key, () => <ProductStepDailyProgress>[]).add(d);
    }

    final bars = <ProductGanttBar>[];
    grouped.forEach((key, values) {
      values.sort((a, b) => a.date.compareTo(b.date));

      final parts = key.split('__');
      final productId = parts.first;
      final stepId = parts.length > 1 ? parts.last : '';

      ProductStepDailyProgress? currentStart;
      DateTime? currentEnd;
      GanttBarStatus? currentStatus;
      int accQty = 0;

      for (final d in values) {
        final status =
            d.doneQty > 0 ? GanttBarStatus.done : GanttBarStatus.inProgress;

        if (currentStart == null) {
          currentStart = d;
          currentEnd = d.date;
          currentStatus = status;
          accQty = d.doneQty;
          continue;
        }

        final isContinuous = d.date.difference(currentEnd!).inDays == 1;
        if (isContinuous && status == currentStatus) {
          currentEnd = d.date;
          accQty += d.doneQty;
          continue;
        }

        // シーケンスを確定
        bars.add(
          _logAndBuildBar(
            productId: productId,
            stepId: stepId,
            start: currentStart.date,
            end: currentEnd!,
            totalQty: accQty,
            isCompleted: currentStatus == GanttBarStatus.done,
          ),
        );

        // 次のシーケンス開始
        currentStart = d;
        currentEnd = d.date;
        currentStatus = status;
        accQty = d.doneQty;
      }

      if (currentStart != null && currentEnd != null && currentStatus != null) {
        bars.add(
          _logAndBuildBar(
            productId: productId,
            stepId: stepId,
            start: currentStart.date,
            end: currentEnd,
            totalQty: accQty,
            isCompleted: currentStatus == GanttBarStatus.done,
          ),
        );
      }
    });
    return bars;
  }

  ProductGanttBar _logAndBuildBar({
    required String productId,
    required String stepId,
    required DateTime start,
    required DateTime end,
    required int totalQty,
    required bool isCompleted,
  }) {
    final status = _statusFromDoneQty(
      doneQty: totalQty,
      isCompleted: isCompleted,
    );
    final bar = ProductGanttBar(
      productId: productId,
      stepId: stepId,
      startDate: _toDateOnly(start),
      endDate: _toDateOnly(end),
      totalDoneQty: totalQty,
      isCompleted: isCompleted,
      kind: GanttBarKind.actual,
      status: status,
    );
    //debugPrint(
    //  'bar: ${bar.startDate.toIso8601String()} - ${bar.endDate.toIso8601String()}',
    //);
    return bar;
  }
}
