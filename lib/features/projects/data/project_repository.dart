import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/project.dart';

/// プロジェクト関連の CRUD / ストリーム
class ProjectRepository {
  final _col = FirebaseFirestore.instance.collection('projects');

  Stream<List<Project>> streamAll() => _col
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs
          .map((d) => Project.fromJson(d.data(), d.id))
          .toList());

  Stream<Project> streamOne(String projectId) =>
      _col.doc(projectId).snapshots().map(
            (d) => Project.fromJson(d.data() ?? {}, d.id),
          );

  Future<void> add(Project project) async {
    await _col.doc(project.id).set(project.toJson());
  }

  Future<void> update(Project project) async {
    await _col.doc(project.id).update(project.toJson());
  }

  /// プロジェクト削除時に配下の products / processProgress / productionLogs をカスケード削除
  Future<void> delete(String projectId) async {
    final projRef = _col.doc(projectId);
    final products = await projRef.collection('products').get();
    for (final p in products.docs) {
      final progress = await p.reference.collection('processProgress').get();
      for (final pg in progress.docs) {
        await pg.reference.delete();
      }
      await p.reference.delete();
    }
    final logs = await projRef.collection('productionLogs').get();
    for (final l in logs.docs) {
      await l.reference.delete();
    }
    await projRef.delete();
  }
}
