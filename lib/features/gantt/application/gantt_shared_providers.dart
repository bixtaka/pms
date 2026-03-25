import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 現在選択されているプロジェクトIDのグローバルプロバイダ
final selectedProjectIdProvider = StateProvider<String?>((ref) => null);

/// Firestore の tasks コレクションから該当プロジェクトのタスク一覧を取得する
final firestoreTasksProvider = StreamProvider.autoDispose
    .family<List<QueryDocumentSnapshot<Map<String, dynamic>>>, String>((
      ref,
      projectId,
    ) {
      return FirebaseFirestore.instance
          .collection('tasks')
          .where('projectId', isEqualTo: projectId)
          .orderBy('sortOrder')
          .snapshots()
          .map((snapshot) => snapshot.docs);
    });
