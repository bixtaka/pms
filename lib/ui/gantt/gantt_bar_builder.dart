import 'gantt_bar_models.dart';

/// 日次進捗リストからステータス別に連結したガントバーを生成する。
///
/// - doneQty > 0      => 完了バー（青）
/// - hasRecord && doneQty == 0 => 作業中バー（オレンジ）
/// - レコード無し              => バーなし
List<GanttBar> buildBarsFromDaily(List<DailyProgressEntry> items) {
  if (items.isEmpty) return const [];

  // 日付昇順で処理
  final sorted = List<DailyProgressEntry>.from(items)
    ..sort((a, b) => a.date.compareTo(b.date));

  final bars = <GanttBar>[];

  String? seqType; // 'done' or 'working'
  DateTime? seqStart;
  DateTime? seqEnd;

  for (final d in sorted) {
    final type = _statusType(d);
    if (type == null) {
      // バーにしないステータスはスキップ
      continue;
    }

    if (seqType == null) {
      seqType = type;
      seqStart = d.date;
      seqEnd = d.date;
      continue;
    }

    // 同じステータスで連続日なら拡張
    final isContinuous = d.date.difference(seqEnd!).inDays == 1;
    if (seqType == type && isContinuous) {
      seqEnd = d.date;
      continue;
    }

    // 連続が途切れたのでバー確定
    bars.add(_makeBar(seqType, seqStart!, seqEnd!));
    seqType = type;
    seqStart = d.date;
    seqEnd = d.date;
  }

  // 最後のシーケンスを追加
  if (seqType != null && seqStart != null && seqEnd != null) {
    bars.add(_makeBar(seqType, seqStart, seqEnd));
  }

  return bars;
}

String? _statusType(DailyProgressEntry entry) {
  if (!entry.hasRecord) return null;
  if (entry.doneQty > 0) return 'done';
  return 'working';
}

GanttBar _makeBar(String type, DateTime s, DateTime e) {
  if (type == 'done') {
    return ActualDoneBar(start: s, end: e);
  }
  return ActualWorkingBar(start: s, end: e);
}
