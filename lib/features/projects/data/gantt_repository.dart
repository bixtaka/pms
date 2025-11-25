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
          productCode: p.productCode,
          overallStartDate: p.overallStartDate,
          overallEndDate: p.overallEndDate,
          processes: map,
        ),
      );
    }
    return items;
  }
}
