import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/process_master.dart';
import '../domain/process_group.dart';

/// 既存の processMasters コレクションを SPEC の process_groups に読み替えるアダプタ
class ProcessGroupsRepository {
  final CollectionReference<Map<String, dynamic>> _col = FirebaseFirestore
      .instance
      .collection('processMasters');

  /// 全件読み込み（SPEC の ProcessGroup に変換）
  Future<List<ProcessGroup>> fetchAll() async {
    final snap = await _col.get();
    return snap.docs.map((d) => ProcessMaster.fromJson(d.data(), d.id)).map((
      m,
    ) {
      // stage を key として再利用（英語化は既存値に依存）
      return ProcessGroup(
        id: m.id,
        key: m.stage.isNotEmpty ? m.stage : m.id,
        label: m.name,
        sortOrder: m.orderInStage,
      );
    }).toList();
  }
}
