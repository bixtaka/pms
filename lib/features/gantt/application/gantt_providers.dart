import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/project.dart';
import '../data/gantt_repository.dart';
import '../domain/gantt_repository.dart';
import '../presentation/gantt_screen.dart' show GanttProduct;

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
