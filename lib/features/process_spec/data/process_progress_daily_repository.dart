import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/process_progress_daily.dart';

/// 既存 processProgress コレクションを SPEC の process_progress_daily へ読み替えるアダプタ
class ProcessProgressDailyRepository {
  CollectionReference<Map<String, dynamic>> _col(
    String projectId,
    String productId,
  ) => FirebaseFirestore.instance
      .collection('projects')
      .doc(projectId)
      .collection('products')
      .doc(productId)
      .collection('processProgress');

  /// 単発読み込み。日付は updatedAt/endDate/startDate の順で採用し、未来日は今日にクランプする。
  /// 同じ stepId+date の複数レコードは「最新(updatedAt)を優先」して1件に集約する。
  Future<List<ProcessProgressDaily>> fetchDaily(
    String projectId,
    String productId, {
    bool debugLog = false,
    String? filterStepId,
  }) async {
    final snap = await _col(projectId, productId).get();
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final List<ProcessProgressDaily> rows = snap.docs.map((d) {
      final data = d.data();
      // docId が "stepId_yyyyMMdd" 形式の場合もあるので分解して stepId を復元
      final idParts = d.id.split('_');
      final inferredStepId =
          (data['stepId'] ?? (idParts.isNotEmpty ? idParts.first : d.id))
              .toString()
              .trim(); // 余計な空白を除去しキーを正規化

      final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate();
      DateTime? date =
          updatedAt ??
          (data['endDate'] as Timestamp?)?.toDate() ??
          (data['startDate'] as Timestamp?)?.toDate();
      // 年月日だけをキーに使う（時刻はすべて捨てる）
      if (date != null) {
        final only = DateTime(date.year, date.month, date.day);
        if (only.isAfter(todayDate)) {
          date = todayDate; // 未来日を禁止
        } else {
          date = only;
        }
      } else {
        date = todayDate;
      }

      final rawQty = data['completedQuantity'] ?? 0;
      final doneQty = rawQty is int ? rawQty : (rawQty as num).toInt();
      final note = data['remarks'] ?? '';
      return ProcessProgressDaily(
        id: d.id,
        productId: productId,
        stepId: inferredStepId, // processId を stepId として転用
        date: date,
        doneQty: doneQty < 0 ? 0 : doneQty,
        note: note,
      );
    }).toList();

    // stepId + date で集計（最新の1件だけ採用）
    final Map<String, Map<DateTime, _AggRow>> grouped = {};
    for (final r in rows) {
      if (filterStepId != null && r.stepId != filterStepId) continue;
      grouped.putIfAbsent(r.stepId, () => <DateTime, _AggRow>{});
      final byDate = grouped[r.stepId]!;
      final existing = byDate[r.date];
      final updatedAt = r.date; // 日単位のため date を更新時刻の代理にする
      if (existing == null || updatedAt.isAfter(existing.updatedAt)) {
        byDate[r.date] = _AggRow(
          stepId: r.stepId,
          date: r.date,
          doneQty: r.doneQty,
          note: r.note,
          updatedAt: updatedAt,
          sourceId: r.id,
        );
      } else if (updatedAt.isAtSameMomentAs(existing.updatedAt)) {
        // 同一日時の重複がある場合、doneQty は新しいものを優先（上書き）し、note も上書き
        byDate[r.date] = _AggRow(
          stepId: r.stepId,
          date: r.date,
          doneQty: r.doneQty,
          note: r.note.isNotEmpty ? r.note : existing.note,
          updatedAt: updatedAt,
          sourceId: r.id,
        );
      }
    }

    final result =
        grouped.values
            .expand((m) => m.values)
            .map(
              (a) => ProcessProgressDaily(
                id: a.sourceId,
                productId: productId,
                stepId: a.stepId,
                date: a.date,
                doneQty: a.doneQty,
                note: a.note,
              ),
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    if (debugLog) {
      // デバッグ用途: 集約前後の件数と対象 product/step を確認
      // ignore: avoid_print
      print(
        '[fetchDaily debug] product=$productId stepFilter=$filterStepId raw=${rows.length} aggregated=${result.length}',
      );
    }

    return result;
  }

  /// productId + stepId + date をキーに上書き保存する（idempotent）
  /// - 未来日は保存不可（StateError を投げる）
  /// - docId に stepId_yyyyMMdd を用いて上書きしやすくするが、既存コレクション構造はそのまま
  Future<void> upsertDaily({
    required String projectId,
    required String productId,
    required String stepId,
    required DateTime date,
    required int doneQty,
    String note = '',
  }) async {
    final requestedDate = DateTime(date.year, date.month, date.day);
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final clampedDate =
        requestedDate.isAfter(todayOnly) ? todayOnly : requestedDate;
    final safeDoneQty = doneQty < 0 ? 0 : doneQty;

    final docId =
        '${stepId}_${clampedDate.year.toString().padLeft(4, '0')}${clampedDate.month.toString().padLeft(2, '0')}${clampedDate.day.toString().padLeft(2, '0')}';
    final col = _col(projectId, productId);
    await col.doc(docId).set({
      'stepId': stepId,
      'completedQuantity': safeDoneQty,
      'remarks': note,
      'updatedAt': Timestamp.fromDate(clampedDate),
    }, SetOptions(merge: true));
  }

  /// productId + stepId + date をキーに削除する
  Future<void> deleteDaily({
    required String projectId,
    required String productId,
    required String stepId,
    required DateTime date,
  }) async {
    final requestedDate = DateTime(date.year, date.month, date.day);
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final clampedDate =
        requestedDate.isAfter(todayOnly) ? todayOnly : requestedDate;
    final docId =
        '${stepId}_${clampedDate.year.toString().padLeft(4, '0')}${clampedDate.month.toString().padLeft(2, '0')}${clampedDate.day.toString().padLeft(2, '0')}';
    final col = _col(projectId, productId);
    await col.doc(docId).delete();
  }
}

class _AggRow {
  final String stepId;
  final DateTime date;
  final int doneQty;
  final String note;
  final DateTime updatedAt;
  final String sourceId;

  const _AggRow({
    required this.stepId,
    required this.date,
    required this.doneQty,
    required this.note,
    required this.updatedAt,
    required this.sourceId,
  });
}
