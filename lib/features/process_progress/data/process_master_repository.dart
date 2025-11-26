import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/process_master.dart';

/// 工程マスタの CRUD / ストリーム
class ProcessMasterRepository {
  final _col = FirebaseFirestore.instance.collection('processMasters');

  Stream<List<ProcessMaster>> streamAll() => _col.snapshots().map(
        (s) => s.docs.map((d) => ProcessMaster.fromJson(d.data(), d.id)).toList(),
      );

  Stream<List<ProcessMaster>> streamByMemberType(String memberType) => _col
      .where('memberType', isEqualTo: memberType)
      .snapshots()
      .map(
        (s) => s.docs.map((d) => ProcessMaster.fromJson(d.data(), d.id)).toList(),
      );

  Future<void> add(ProcessMaster m) => _col.doc(m.id).set(m.toJson());
  Future<void> update(ProcessMaster m) => _col.doc(m.id).update(m.toJson());
  Future<void> delete(String id) => _col.doc(id).delete();
}
