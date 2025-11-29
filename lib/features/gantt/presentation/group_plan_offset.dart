/// 工程別ビューの計画バー用オフセット。
/// shiftDays: 元の期間（summary.tasks の min〜max）から全体を何日スライドしたか。
/// startExtra / endExtra: 左右の端を何日延長・短縮したか。
/// UI 専用の状態であり、現場実績（process_progress_daily）のデータには影響しない。
class GroupPlanOffset {
  final int shiftDays;
  final int startExtra;
  final int endExtra;

  const GroupPlanOffset({
    this.shiftDays = 0,
    this.startExtra = 0,
    this.endExtra = 0,
  });

  GroupPlanOffset copyWith({
    int? shiftDays,
    int? startExtra,
    int? endExtra,
  }) {
    return GroupPlanOffset(
      shiftDays: shiftDays ?? this.shiftDays,
      startExtra: startExtra ?? this.startExtra,
      endExtra: endExtra ?? this.endExtra,
    );
  }
}
