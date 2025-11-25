import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/projects/data/project_repository.dart';
import '../features/projects/data/gantt_repository.dart';
import '../models/project.dart';

// リポジトリのプロバイダ
final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository();
});

// プロジェクト一覧の購読
final projectsProvider = StreamProvider<List<Project>>((ref) {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.streamAll();
});

// ガント用データ取得
final ganttRepositoryProvider = Provider<GanttRepository>((ref) {
  return GanttRepository();
});

final ganttItemsProvider =
    FutureProvider.family.autoDispose((ref, String projectId) {
  final repo = ref.watch(ganttRepositoryProvider);
  return repo.fetchGanttItems(projectId);
});
