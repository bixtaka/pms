/// ガントチャート用のドメインモデルとEnum定義
///
/// gantt_screen.dart から抽出したモデルクラス群。
/// 製品別/工程別ビュー両方で使用される共通モデル。

/// 工種種別
enum ProcessType { coreAssembly, coreWeld, jointAssembly, jointWeld, other }

/// 表示モード（製品別 / 工種別）
enum GanttViewMode { byProduct, byProcess }

/// ガントの横方向ズーム。日/週/月ボタンで切り替える。
/// day: 1日あたりの幅を広くして細かく見る（表示日数少なめ）
/// month: 幅を狭くして長期間を見る（表示日数多め）
enum GanttDateScale { day, week, twoWeeks, month }

/// 計画バーのドラッグモード（スライド／左右リサイズ）
enum DragMode { move, resizeLeft, resizeRight }

/// 製品別タブのビュー切り替え
enum ProductViewMode { schedule, processStatus }

/// 工程ステータスマトリクス用ステータス
enum ProcessCellStatus { notStarted, inProgress, done }

/// 行の種類：製品ヘッダ or タスク行
enum GanttRowKind { productHeader, taskRow }

/// 1タスク（工種）を表すモデル
class GanttTask {
  final String id;
  final String name;
  final ProcessType type;
  final DateTime start;
  final DateTime end;
  final double progress;
  // 製品全体の予定完了日（製品レベルの予定を工程にも共有する）
  final DateTime? plannedEnd;
  // SPEC の process_steps への紐付け（工程別ビューで使用）
  final String? stepId;
  final String? stepKey;
  final String? stepLabel;
  final int? stepSort;
  // SPEC の process_groups への紐付け（工程別ビューで使用）
  final String? processGroupId;
  final String? processGroupKey;
  final String? processGroupLabel;
  final int? processGroupSort;

  const GanttTask({
    required this.id,
    required this.name,
    required this.type,
    required this.start,
    required this.end,
    required this.progress,
    this.plannedEnd,
    this.stepId,
    this.stepKey,
    this.stepLabel,
    this.stepSort,
    this.processGroupId,
    this.processGroupKey,
    this.processGroupLabel,
    this.processGroupSort,
  });
}

/// 製品行モデル（複数タスクを内包）
class GanttProduct {
  final String id;
  final String code;
  final String name;
  final String memberType;
  final double progress;
  final int quantity;
  final List<GanttTask> tasks;

  const GanttProduct({
    required this.id,
    required this.code,
    required this.name,
    this.memberType = '',
    required this.progress,
    required this.quantity,
    required this.tasks,
  });
}

/// 左ペイン／右タイムライン両方で使う行定義
class GanttRowEntry {
  final GanttRowKind kind;
  final GanttProduct product;
  final GanttTask? task;

  const GanttRowEntry.productHeader(this.product)
    : kind = GanttRowKind.productHeader,
      task = null;

  const GanttRowEntry.taskRow(this.product, this.task)
    : kind = GanttRowKind.taskRow;
}

// 工程別ビュー用の親子ツリー行モデル。
// 親: process_groups（一級の工程グループ。一次加工／コア部／…）
// 子: process_steps（各グループ配下の工程ステップ。切断／ショット／UT／…）
// ガント画面では、左ペイン・右ペインともにこの rows を使って
// 折りたたみ可能なツリー構造として表示する。
abstract class ProcessTreeRow {
  const ProcessTreeRow();
}

class ProcessGroupRow extends ProcessTreeRow {
  final String groupId;
  final String groupKey;
  final String label;
  final int sortOrder;
  final List<GanttTask> tasks; // そのグループに属する全タスク

  const ProcessGroupRow({
    required this.groupId,
    required this.groupKey,
    required this.label,
    required this.sortOrder,
    required this.tasks,
  });
}

class ProcessStepRow extends ProcessTreeRow {
  final String groupId;
  final String stepId;
  final String stepKey;
  final String label;
  final int sortOrder;
  final List<GanttTask> tasks; // そのステップに属するタスク

  const ProcessStepRow({
    required this.groupId,
    required this.stepId,
    required this.stepKey,
    required this.label,
    required this.sortOrder,
    required this.tasks,
  });
}

class ProcessVisibleRow {
  final bool isGroup;
  final ProcessGroupRow? groupRow;
  final ProcessStepRow? stepRow;

  const ProcessVisibleRow.group(this.groupRow)
      : isGroup = true,
        stepRow = null;

  const ProcessVisibleRow.step(this.stepRow)
      : isGroup = false,
        groupRow = null;
}
