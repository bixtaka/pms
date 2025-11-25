import 'package:flutter/material.dart';
import '../../../models/process_progress.dart';
import '../../products/data/product_repository.dart';
import '../../process_progress/data/process_progress_repository.dart';

/// ガントチャート表示用の集約モデル
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

/// ガント用データをまとめて取得するリポジトリ
class GanttRepository {
  final ProductRepository _productRepo = ProductRepository();
  final ProcessProgressRepository _progressRepo = ProcessProgressRepository();

  /// 指定 projectId の全製品と進捗をまとめて取得
  Future<List<GanttItem>> fetchGanttItems(String projectId) async {
    final products = await _productRepo.streamByProject(projectId).first;
    final List<GanttItem> items = [];
    for (final p in products) {
      final progresses =
          await _progressRepo.streamAll(projectId, p.id).first;
      final map = {for (final pg in progresses) pg.processId: pg};
      items.add(
        GanttItem(
          productId: p.id,
          productCode: p.productCode.isNotEmpty ? p.productCode : p.name,
          overallStartDate: p.overallStartDate ?? p.startDate,
          overallEndDate: p.overallEndDate ?? p.endDate,
          processes: map,
        ),
      );
    }
    return items;
  }

  /// ガントアイテムから表示範囲の最小開始日・最大終了日を算出
  DateTimeRange computeDateRange(List<GanttItem> items) {
    if (items.isEmpty) {
      final now = DateTime.now();
      return DateTimeRange(
        start: DateTime(now.year, now.month, now.day),
        end: DateTime(now.year, now.month, now.day + 7),
      );
    }
    DateTime? minStart;
    DateTime? maxEnd;
    for (final item in items) {
      final s = item.overallStartDate;
      final e = item.overallEndDate;
      if (s != null) {
        minStart = (minStart == null || s.isBefore(minStart)) ? s : minStart;
      }
      if (e != null) {
        maxEnd = (maxEnd == null || e.isAfter(maxEnd)) ? e : maxEnd;
      }
    }
    final today = DateTime.now();
    final start = DateTime(
        (minStart ?? today).year, (minStart ?? today).month, (minStart ?? today).day);
    final endBase = maxEnd ?? start.add(const Duration(days: 7));
    final end = DateTime(endBase.year, endBase.month, endBase.day);
    return DateTimeRange(start: start, end: end);
  }
}
