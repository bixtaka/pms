import '../presentation/gantt_screen.dart' show GanttProduct; // 再利用するガント用モデル

/// ガントチャートで必要な製品＋工程タスクを取得するリポジトリの契約
abstract class GanttRepository {
  /// 指定された工事IDの製品と工程進捗を統合し、UI で使える形に変換して返す
  Future<List<GanttProduct>> fetchGanttProductsByProjectId(String projectId);
}
