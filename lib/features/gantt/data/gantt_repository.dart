import 'package:collection/collection.dart';
import '../../../models/process_master.dart';
import '../../../models/process_progress.dart';
import '../../../models/product.dart';
import '../../process_progress/data/process_master_repository.dart';
import '../../process_progress/data/process_progress_repository.dart';
import '../../products/data/product_repository.dart';
import '../domain/gantt_repository.dart';
import '../presentation/gantt_screen.dart'
    show GanttProduct, GanttTask, ProcessType;

/// 旧 UI（widgets/gantt_chart.dart など）が参照する簡易モデル
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

/// Firestore から製品＋工程進捗を集約してガント用モデルへ変換する実装
class FirestoreGanttRepository implements GanttRepository {
  final ProductRepository _productRepo;
  final ProcessProgressRepository _progressRepo;
  final ProcessMasterRepository _masterRepo;

  FirestoreGanttRepository({
    ProductRepository? productRepo,
    ProcessProgressRepository? progressRepo,
    ProcessMasterRepository? masterRepo,
  }) : _productRepo = productRepo ?? ProductRepository(),
       _progressRepo = progressRepo ?? ProcessProgressRepository(),
       _masterRepo = masterRepo ?? ProcessMasterRepository();

  @override
  Future<List<GanttProduct>> fetchGanttProductsByProjectId(
    String projectId,
  ) async {
    // まとめて取得（単発読み込み）
    final products = await _productRepo.streamByProject(projectId).first;
    final masters = await _masterRepo.streamAll().first;

    final List<GanttProduct> result = [];
    for (final product in products) {
      final progresses = await _progressRepo
          .streamAll(projectId, product.id)
          .first;
      final masterForProduct = _pickMastersForProduct(masters, product);
      final taskList = _buildTasks(product, masterForProduct, progresses);

      final avgProgress = taskList.isEmpty
          ? 0.0
          : taskList.map((t) => t.progress).average;

      result.add(
        GanttProduct(
          id: product.id,
          code: product.productCode.isNotEmpty
              ? product.productCode
              : product.name,
          name: product.name.isNotEmpty ? product.name : product.productCode,
          progress: avgProgress.isNaN ? 0.0 : avgProgress,
          tasks: taskList,
        ),
      );
    }
    return result;
  }

  List<ProcessMaster> _pickMastersForProduct(
    List<ProcessMaster> masters,
    Product product,
  ) {
    final filtered = masters
        .where(
          (m) =>
              m.memberType.toUpperCase() == product.memberType.toUpperCase() ||
              m.memberType.toUpperCase() == 'COMMON',
        )
        .toList();
    return filtered.isEmpty ? masters : filtered;
  }

  List<GanttTask> _buildTasks(
    Product product,
    List<ProcessMaster> masters,
    List<ProcessProgress> progresses,
  ) {
    final progressMap = {for (final pg in progresses) pg.processId: pg};
    // master と progress のユニオンでタスクを生成
    final ids = <String>{...masters.map((m) => m.id), ...progressMap.keys};

    final tasks = <GanttTask>[];
    for (final id in ids) {
      final pm = masters.firstWhereOrNull((m) => m.id == id);
      final pg = progressMap[id];
      final name = pm?.name ?? id;
      final type = _mapProcessType(pm, pg);

      final start =
          pg?.startDate ?? product.overallStartDate ?? product.startDate;
      final end =
          pg?.endDate ?? product.overallEndDate ?? product.endDate ?? start;
      final safeStart = start ?? DateTime.now();
      final safeEnd = end == null
          ? safeStart
          : (end.isBefore(safeStart) ? safeStart : end);

      final progressRatio = _calcProgress(pg);

      tasks.add(
        GanttTask(
          id: id,
          name: name,
          type: type,
          start: safeStart,
          end: safeEnd,
          progress: progressRatio,
        ),
      );
    }

    // 表示順を master の orderInStage に寄せる
    tasks.sort((a, b) {
      final orderA =
          masters.firstWhereOrNull((m) => m.id == a.id)?.orderInStage ?? 999;
      final orderB =
          masters.firstWhereOrNull((m) => m.id == b.id)?.orderInStage ?? 999;
      return orderA.compareTo(orderB);
    });

    return tasks;
  }

  ProcessType _mapProcessType(ProcessMaster? pm, ProcessProgress? pg) {
    final key = (pm?.name ?? pg?.processId ?? '').toLowerCase();
    if (key.contains('コア') && key.contains('組'))
      return ProcessType.coreAssembly;
    if (key.contains('コア') && key.contains('溶')) return ProcessType.coreWeld;
    if (key.contains('仕口') && key.contains('組')) {
      return ProcessType.jointAssembly;
    }
    if (key.contains('仕口') && key.contains('溶')) return ProcessType.jointWeld;
    return ProcessType.other;
  }

  double _calcProgress(ProcessProgress? pg) {
    if (pg == null) return 0.0;
    if (pg.totalQuantity > 0) {
      return (pg.completedQuantity / pg.totalQuantity).clamp(0.0, 1.0);
    }
    switch (pg.status) {
      case 'completed':
        return 1.0;
      case 'in_progress':
        return 0.5;
      default:
        return 0.0;
    }
  }
}
