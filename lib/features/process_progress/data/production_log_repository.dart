import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/production_log.dart';

/// 日別実績ログのリポジトリ（任意機能）
class ProductionLogRepository {
  CollectionReference<Map<String, dynamic>> _col(String projectId) =>
      FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('productionLogs');

  Stream<List<ProductionLog>> streamByDate(
    String projectId,
    DateTime from,
    DateTime to,
  ) =>
      _col(projectId)
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(from),
              isLessThanOrEqualTo: Timestamp.fromDate(to))
          .orderBy('date')
          .snapshots()
          .map(
            (s) => s.docs
                .map((d) => ProductionLog.fromJson(d.data(), d.id))
                .toList(),
          );

  Future<void> add(String projectId, ProductionLog log) =>
      _col(projectId).doc(log.id).set(log.toJson());

  Future<void> update(String projectId, ProductionLog log) =>
      _col(projectId).doc(log.id).update(log.toJson());

  Future<void> delete(String projectId, String logId) =>
      _col(projectId).doc(logId).delete();
}
