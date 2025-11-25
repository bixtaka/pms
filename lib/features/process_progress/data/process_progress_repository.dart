import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/process_progress.dart';

/// 製品×工程の進捗を扱うリポジトリ
class ProcessProgressRepository {
  CollectionReference<Map<String, dynamic>> _col(
    String projectId,
    String productId,
  ) =>
      FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('products')
          .doc(productId)
          .collection('processProgress');

  Stream<List<ProcessProgress>> streamAll(
    String projectId,
    String productId,
  ) =>
      _col(projectId, productId)
          .orderBy(FieldPath.documentId)
          .snapshots()
          .map(
            (s) => s.docs
                .map((d) => ProcessProgress.fromJson(d.data(), d.id))
                .toList(),
          );

  Future<void> setProgress({
    required String projectId,
    required String productId,
    required ProcessProgress progress,
  }) =>
      _col(projectId, productId)
          .doc(progress.processId)
          .set(progress.toJson(), SetOptions(merge: true));

  Future<void> delete({
    required String projectId,
    required String productId,
    required String processId,
  }) =>
      _col(projectId, productId).doc(processId).delete();
}
