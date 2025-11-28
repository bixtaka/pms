import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/project.dart';
import '../../process_spec/presentation/process_colors.dart';
import '../application/gantt_providers.dart';
import 'group_plan_offset.dart';

/// 工種種別
enum ProcessType { coreAssembly, coreWeld, jointAssembly, jointWeld, other }

/// 表示モード（製品別 / 工種別）
enum GanttViewMode { byProduct, byProcess }

/// ガントの横方向ズーム。日/週/月ボタンで切り替える。
/// day: 1日あたりの幅を広くして細かく見る（表示日数少なめ）
/// month: 幅を狭くして長期間を見る（表示日数多め）
enum GanttDateScale { day, week, month }

/// 計画バーのドラッグモード（スライド／左右リサイズ）
enum _DragMode { move, resizeLeft, resizeRight }

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
  final double progress;
  final List<GanttTask> tasks;

  const GanttProduct({
    required this.id,
    required this.code,
    required this.name,
    required this.progress,
    required this.tasks,
  });
}

/// 行の種類：製品ヘッダ or タスク行
enum GanttRowKind { productHeader, taskRow }

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

/// バーの位置計算結果
class _TaskGeometry {
  final double left;
  final double width;

  const _TaskGeometry({required this.left, required this.width});
}

/// 工程グループ（SPEC の process_groups）単位の集計モデル
class ProcessGroupSummary {
  final String key;
  final String label;
  final int sortOrder;
  final List<GanttTask> tasks;

  const ProcessGroupSummary({
    required this.key,
    required this.label,
    required this.sortOrder,
    required this.tasks,
  });
}

class GanttScreen extends ConsumerStatefulWidget {
  final Project project;

  const GanttScreen({super.key, required this.project});

  @override
  ConsumerState<GanttScreen> createState() => _GanttScreenState();
}

class _GanttScreenState extends ConsumerState<GanttScreen> {
  // タイムライン幅調整
  // 行高さは左リストと右ガントで共通化し、ズレを防ぐ
  static const double _rowHeight = 52;
  // 日付スケール
  GanttDateScale _dateScale = GanttDateScale.month;

  double get _dayWidth {
    switch (_dateScale) {
      case GanttDateScale.day:
        return 64;
      case GanttDateScale.week:
        return 32;
      case GanttDateScale.month:
        return 16;
    }
  }

  DateTime _startDate = DateTime.now().subtract(
    const Duration(days: 3),
  ); // デフォルト
  DateTime _endDate = DateTime.now().add(const Duration(days: 14));
  int _totalDays = 18;

  // スクロール同期用
  final ScrollController _leftScroll = ScrollController();
  final ScrollController _rightScroll = ScrollController();
  final ScrollController _rightHeaderScroll = ScrollController();

  // 展開状態
  final Set<String> _expandedProductIds = <String>{};

  // フィルタUI用（ダミー）
  String _selectedProjectName = '工事A';
  String _keyword = '';
  int _viewRangeIndex = 1; // 日/週/月ダミー
  // 初期表示を工種別に。運用上製品別を初期に戻したい場合は byProduct に戻してください。
  GanttViewMode _viewMode = GanttViewMode.byProcess;
  // 工程別ビューの「計画バー（Plan）」用オフセット。
  // shiftDays: 元の期間から全体を何日スライドしたか。
  // startExtra/endExtra: 左右端を何日延長・短縮したか。
  // UI 専用の状態であり、現場実績（process_progress_daily）には影響しない。
  final Map<String, GroupPlanOffset> _groupPlanOffsets = {};
  // ドラッグ中の状態
  String? _draggingGroupKey;
  double _dragAccumulatedDx = 0.0;
  GroupPlanOffset _dragStartOffset = const GroupPlanOffset();
  _DragMode? _dragMode;

  @override
  void initState() {
    super.initState();
    _rightScroll.addListener(() {
      _rightHeaderScroll.jumpTo(_rightScroll.offset);
    });
  }

  @override
  void dispose() {
    _leftScroll.dispose();
    _rightScroll.dispose();
    _rightHeaderScroll.dispose();
    super.dispose();
  }

  List<GanttRowEntry> _buildRowEntries(List<GanttProduct> products) {
    final entries = <GanttRowEntry>[];
    for (final product in products) {
      entries.add(GanttRowEntry.productHeader(product));
      if (_expandedProductIds.contains(product.id)) {
        for (final task in product.tasks) {
          entries.add(GanttRowEntry.taskRow(product, task));
        }
      }
    }
    return entries;
  }

  Color _taskBaseColorByLabel(String label) =>
      ProcessColors.fromProcessNames(label);

  _TaskGeometry? _computeTaskGeometry(
    GanttTask task,
    DateTime startDate,
    int totalDays,
    double dayWidth,
  ) {
    return _computeRangeGeometry(
      task.start,
      task.end,
      startDate,
      totalDays,
      dayWidth,
    );
  }

  /// 任意の期間(start～end)をピクセル幅に変換するヘルパー
  _TaskGeometry? _computeRangeGeometry(
    DateTime? rangeStart,
    DateTime? rangeEnd,
    DateTime startDate,
    int totalDays,
    double dayWidth,
  ) {
    if (rangeStart == null || rangeEnd == null) return null;
    final chartEnd = DateTime(startDate.year, startDate.month, startDate.day)
        .add(Duration(days: totalDays));

    // 完全に範囲外なら非表示
    if (rangeEnd.isBefore(startDate) || rangeStart.isAfter(chartEnd)) {
      return null;
    }

    // 表示範囲にクランプして「見える部分だけ」描画する
    final effectiveStart =
        rangeStart.isBefore(startDate) ? startDate : rangeStart;
    final effectiveEnd =
        rangeEnd.isAfter(chartEnd) ? chartEnd : rangeEnd;

    int startOffsetDays = effectiveStart.difference(startDate).inDays;
    int durationDays = effectiveEnd.difference(effectiveStart).inDays + 1;

    if (durationDays <= 0) return null;

    final left = startOffsetDays * dayWidth;
    final width = durationDays * dayWidth;
    return _TaskGeometry(left: left, width: width);
  }

  String _formatDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final asyncProducts = ref.watch(ganttProductsProvider(widget.project));

    return Scaffold(
      appBar: AppBar(
        title: Text('ガントチャート - ${widget.project.name}'),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedProjectName,
              items: const [
                DropdownMenuItem(value: '工事A', child: Text('工事A')),
                DropdownMenuItem(value: '工事B', child: Text('工事B')),
              ],
              onChanged: (v) =>
                  setState(() => _selectedProjectName = v ?? '工事A'),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 160,
            child: TextField(
              decoration: const InputDecoration(
                hintText: '製品検索',
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
              onChanged: (v) => setState(() => _keyword = v),
            ),
          ),
          const SizedBox(width: 8),
          ToggleButtons(
            isSelected: [
              _viewRangeIndex == 0,
              _viewRangeIndex == 1,
              _viewRangeIndex == 2,
            ],
            onPressed: (i) => setState(() {
              _viewRangeIndex = i;
              // 日/週/月ボタンでズームを切り替える
              switch (i) {
                case 0:
                  _dateScale = GanttDateScale.day;
                  break;
                case 1:
                  _dateScale = GanttDateScale.week;
                  break;
                case 2:
                default:
                  _dateScale = GanttDateScale.month;
                  break;
              }
            }),
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('日'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('週'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('月'),
              ),
            ],
          ),
          const SizedBox(width: 8),
          ToggleButtons(
            isSelected: [
              _viewMode == GanttViewMode.byProduct,
              _viewMode == GanttViewMode.byProcess,
            ],
            onPressed: (idx) {
              setState(() {
                _viewMode = idx == 0
                    ? GanttViewMode.byProduct
                    : GanttViewMode.byProcess;
              });
            },
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('製品別'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('工種別'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              // 「今日」の位置へ横スクロール
              final now = DateTime.now();
              final todayBase = DateTime(now.year, now.month, now.day);
              final offsetDays =
                  todayBase.difference(_startDate).inDays;
              double target;
              if (offsetDays <= 0) {
                target = 0;
              } else if (offsetDays >= _totalDays) {
                target = (_totalDays - 1) * _dayWidth;
              } else {
                target = offsetDays * _dayWidth;
              }
              _rightScroll.animateTo(
                target,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // 将来: データ再取得
            },
          ),
        ],
      ),
      body: asyncProducts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
        data: (products) {
          _updateDateRange(products);
          final filteredProducts = _filteredProductsFromList(products);
          final rowEntries = _filterRowsByKeyword(
            _buildRowEntries(filteredProducts),
          );
          final processSummaries = _filterSummariesByKeyword(
            _buildProcessSummaries(filteredProducts),
          );
          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 900) {
                return Row(
                  children: [
                    SizedBox(
                      width: 280,
                      child: _buildLeftPane(
                        rowEntries: rowEntries,
                        summaries: processSummaries,
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: _buildRightPane(
                        rowEntries: rowEntries,
                        summaries: processSummaries,
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    SizedBox(
                      height: 320,
                      child: _buildLeftPane(
                        rowEntries: rowEntries,
                        summaries: processSummaries,
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _buildRightPane(
                        rowEntries: rowEntries,
                        summaries: processSummaries,
                      ),
                    ),
                  ],
                );
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildLeftPane({
    required List<GanttRowEntry> rowEntries,
    required List<ProcessGroupSummary> summaries,
  }) {
    switch (_viewMode) {
      case GanttViewMode.byProduct:
        return _buildLeftPaneByProduct(rowEntries);
      case GanttViewMode.byProcess:
        return _buildLeftPaneByProcess(summaries);
    }
  }

  Widget _buildLeftPaneByProduct(List<GanttRowEntry> rows) {
    return ListView.builder(
      controller: _leftScroll,
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final entry = rows[index];
        switch (entry.kind) {
          case GanttRowKind.productHeader:
            return _buildProductHeaderTile(entry.product);
          case GanttRowKind.taskRow:
            return _buildTaskTile(entry.task!);
        }
      },
    );
  }

  Widget _buildLeftPaneByProcess(List<ProcessGroupSummary> summaries) {
    return ListView.builder(
      controller: _leftScroll,
      itemCount: summaries.length,
      itemBuilder: (context, index) {
        final summary = summaries[index];
        final color = _taskBaseColorByLabel(summary.label);
        final allStarts = summary.tasks.map((t) => t.start).toList()..sort();
        final allEnds = summary.tasks.map((t) => t.end).toList()..sort();
        final start = allStarts.isNotEmpty ? allStarts.first : null;
        final end = allEnds.isNotEmpty ? allEnds.last : null;
        final avgProgress = summary.tasks.isEmpty
            ? 0.0
            : summary.tasks
                    .map((t) => t.progress)
                    .fold<double>(0, (a, b) => a + b) /
                summary.tasks.length;
        return SizedBox(
          height: _rowHeight,
          child: InkWell(
            onTap: () => _showProcessGroupDetail(context, summary, color),
            child: ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              leading: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              title: Text(summary.label),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [
                      'タスク数: ${summary.tasks.length}',
                      if (start != null && end != null)
                        '${_formatDate(start)} 〜 ${_formatDate(end)}',
                    ].join(' / '),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: avgProgress.clamp(0.0, 1.0),
                    backgroundColor: Colors.grey.shade200,
                    color: color,
                    minHeight: 6,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRightPane({
    required List<GanttRowEntry> rowEntries,
    required List<ProcessGroupSummary> summaries,
  }) {
    switch (_viewMode) {
      case GanttViewMode.byProduct:
        return _buildTimelineByProduct(rowEntries);
      case GanttViewMode.byProcess:
        return _buildTimelineByProcess(summaries);
    }
  }

  Widget _buildProductHeaderTile(GanttProduct product) {
    final isExpanded = _expandedProductIds.contains(product.id);
    return ListTile(
      title: Text(
        product.code,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(product.name),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 80,
            child: LinearProgressIndicator(
              value: product.progress.clamp(0.0, 1.0),
            ),
          ),
          Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
        ],
      ),
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedProductIds.remove(product.id);
          } else {
            _expandedProductIds.add(product.id);
          }
        });
      },
    );
  }

  Widget _buildTaskTile(GanttTask task) {
    final baseColor = _taskBaseColorByLabel(task.name);
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 32, right: 16),
      leading: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      title: Text(task.name),
      subtitle: Text('${_formatDate(task.start)} 〜 ${_formatDate(task.end)}'),
    );
  }

  Widget _buildTimelineByProduct(List<GanttRowEntry> rows) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final visibleDays = _endDate.difference(_startDate).inDays + 1;
        final requiredDays =
            (constraints.maxWidth / _dayWidth).ceil().clamp(1, 365);
        final daysCount = visibleDays < requiredDays ? requiredDays : visibleDays;
        // _totalDays/_endDate を最新に合わせておく（他ヘルパーで参照するため）
        _totalDays = daysCount;
        _endDate = _startDate.add(Duration(days: daysCount - 1));
        return Column(
          children: [
            _buildTimelineHeader(daysCount),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: _rightScroll,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: daysCount * _dayWidth,
                  child: ListView.builder(
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      final entry = rows[index];
                      switch (entry.kind) {
                        case GanttRowKind.productHeader:
                          return _buildProductTimelineRow(entry.product, daysCount);
                        case GanttRowKind.taskRow:
                          return _buildTaskTimelineRow(entry.task!, daysCount);
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimelineByProcess(List<ProcessGroupSummary> summaries) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final visibleDays = _endDate.difference(_startDate).inDays + 1;
        final requiredDays =
            (constraints.maxWidth / _dayWidth).ceil().clamp(1, 365);
        final daysCount = visibleDays < requiredDays ? requiredDays : visibleDays;
        _totalDays = daysCount;
        _endDate = _startDate.add(Duration(days: daysCount - 1));
        return Column(
          children: [
            _buildTimelineHeader(daysCount),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: _rightScroll,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: daysCount * _dayWidth,
                  child: ListView.builder(
                    itemCount: summaries.length,
                    itemBuilder: (context, index) {
                      final summary = summaries[index];
                      return _buildProcessTimelineRow(summary, daysCount);
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimelineHeader(int daysCount) {
    return SizedBox(
      height: 32,
      child: SingleChildScrollView(
        controller: _rightHeaderScroll,
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(daysCount, (i) {
            final d = _startDate.add(Duration(days: i));
            return Container(
              width: _dayWidth,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Text(
                '${d.month}/${d.day}',
                style: const TextStyle(fontSize: 12),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildRowGrid(int daysCount) {
    return Row(
      children: List.generate(daysCount, (i) {
        final d = _startDate.add(Duration(days: i));
        final isWeekend =
            d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;
        return Container(
          width: _dayWidth,
          height: double.infinity,
          decoration: BoxDecoration(
            color: isWeekend
                ? Colors.grey.withValues(alpha: 0.12)
                : Colors.transparent,
            // 横線(ボーダー)を追加し、左リストと右ガントの行境界を揃える
            border: Border(
              right: BorderSide(color: Colors.grey.shade300),
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildProcessTimelineRow(ProcessGroupSummary summary, int daysCount) {
    final baseColor = _taskBaseColorByLabel(summary.label);
    // 工程別ビューでは、各工程の全タスク期間（最初の start〜最後の end）を細い計画バーとして 1本描画し、その上に各製品のバー（実績）を重ねている
    _TaskGeometry? plannedGeo;
    if (summary.tasks.isNotEmpty) {
      final starts = summary.tasks.map((t) => t.start).toList()..sort();
      final ends = summary.tasks.map((t) => t.end).toList()..sort();
      final offset = _groupPlanOffsets[summary.key] ?? const GroupPlanOffset();
      var plannedStart = starts.first.add(
        Duration(days: offset.shiftDays + offset.startExtra),
      );
      var plannedEnd = ends.last.add(
        Duration(days: offset.shiftDays + offset.endExtra),
      );
      // 開始 > 終了にならないように最低1日幅を確保
      if (!plannedEnd.isAfter(plannedStart)) {
        plannedEnd = plannedStart.add(const Duration(days: 1));
      }
      plannedGeo = _computeRangeGeometry(
        plannedStart,
        plannedEnd,
        _startDate,
        daysCount,
        _dayWidth,
      );
      // デバッグ用ログ: 計画バーのジオメトリを可視化
      // ignore: avoid_print
      print(
        '[process-planned] ${summary.label} '
        'tasks=${summary.tasks.length} '
        'groupStart=${starts.first} groupEnd=${ends.last} '
        'offset=${offset.shiftDays} '
        'startDate=$_startDate totalDays=$_totalDays '
        'geo=${plannedGeo?.left},${plannedGeo?.width}',
      );
    }

    return SizedBox(
      height: _rowHeight,
      child: Stack(
        children: [
          Positioned.fill(child: _buildRowGrid(daysCount)),
          if (plannedGeo != null)
            _buildProcessPlannedBar(
              plannedGeo,
              baseColor,
              summary.key,
            ),
          for (final task in summary.tasks)
            _buildProcessTaskBar(task, baseColor, daysCount),
        ],
      ),
    );
  }

  /// 工程グループ全体の計画バー（細いバー）を描画
  /// shiftDays: 全体スライド、startExtra/endExtra: 左右端の伸縮
  Widget _buildProcessPlannedBar(
    _TaskGeometry geo,
    Color baseColor,
    String groupKey,
  ) {
    const double plannedHeight = 8;
    const double handleWidth = 6;
    final barWidth = geo.width;
    final centerWidthNum = (barWidth - handleWidth * 2);
    final double centerWidth =
        centerWidthNum < 0 ? 0 : centerWidthNum.toDouble();

    return Positioned(
      left: geo.left,
      // 実績バーと完全に重ならないよう少し上にずらす
      top: (_rowHeight - plannedHeight) / 2 - 2,
      child: SizedBox(
        height: _rowHeight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 左端ハンドル: 開始日を伸縮
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (_) =>
                  _onPlanDragStart(groupKey, _DragMode.resizeLeft),
              onPanUpdate: (d) => _onPlanDragUpdate(groupKey, d.delta.dx),
              onPanEnd: (_) => _onPlanDragEnd(groupKey),
              child: Container(
                width: handleWidth,
                height: plannedHeight + 8,
                decoration: BoxDecoration(
                  color: baseColor.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // 中央: 全体スライド
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (_) => _onPlanDragStart(groupKey, _DragMode.move),
              onPanUpdate: (d) => _onPlanDragUpdate(groupKey, d.delta.dx),
              onPanEnd: (_) => _onPlanDragEnd(groupKey),
              child: Container(
                width: centerWidth,
                height: plannedHeight,
                decoration: BoxDecoration(
                  color: baseColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: baseColor.withValues(alpha: 0.7),
                    width: 1,
                  ),
                ),
              ),
            ),
            // 右端ハンドル: 終了日を伸縮
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (_) =>
                  _onPlanDragStart(groupKey, _DragMode.resizeRight),
              onPanUpdate: (d) => _onPlanDragUpdate(groupKey, d.delta.dx),
              onPanEnd: (_) => _onPlanDragEnd(groupKey),
              child: Container(
                width: handleWidth,
                height: plannedHeight + 8,
                decoration: BoxDecoration(
                  color: baseColor.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 工種別ビューでも製品別と同じ「予定(細)+実績(太)」2レイヤーバーを使う
  Widget _buildProcessTaskBar(GanttTask task, Color baseColor, int daysCount) {
    final geo = _computeTaskGeometry(task, _startDate, daysCount, _dayWidth);
    if (geo == null) return const SizedBox.shrink();
    final progress = task.progress.clamp(0.0, 1.0);

    return Positioned(
      left: geo.left,
      top: (_rowHeight - 14) / 2,
      child: _buildLayeredBar(
        width: geo.width,
        baseColor: baseColor,
        progress: progress,
      ),
    );
  }

  Widget _buildProductTimelineRow(GanttProduct product, int daysCount) {
    return SizedBox(
      height: _rowHeight,
      child: Stack(
        children: [
          // Note: productヘッダ行は現状グリッドなし（必要ならヘッダ表現を追加）
          Positioned.fill(child: Container()),
          _buildTodayLine(),
          for (final task in product.tasks) _buildTaskBar(task, daysCount),
        ],
      ),
    );
  }

  Widget _buildTaskTimelineRow(GanttTask task, int daysCount) {
    final geo = _computeTaskGeometry(task, _startDate, daysCount, _dayWidth);
    final baseColor = _taskBaseColorByLabel(task.name);
    final progress = task.progress.clamp(0.0, 1.0);

    return SizedBox(
      height: _rowHeight,
      child: Stack(
        children: [
          Positioned.fill(child: _buildRowGrid(daysCount)),
          _buildTodayLine(),
          _buildPlannedEndLine(task),
          if (geo != null)
            Positioned(
              left: geo.left,
              top: (_rowHeight - 14) / 2,
              child: _buildLayeredBar(
                width: geo.width,
                baseColor: baseColor,
                progress: progress,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskBar(GanttTask task, int daysCount) {
    final geo = _computeTaskGeometry(task, _startDate, daysCount, _dayWidth);
    if (geo == null) return const SizedBox.shrink();
    final baseColor = _taskBaseColorByLabel(task.name);
    final progress = task.progress.clamp(0.0, 1.0);

    return Positioned(
      left: geo.left,
      top: (_rowHeight - 14) / 2,
      child: _buildLayeredBar(
        width: geo.width,
        baseColor: baseColor,
        progress: progress,
      ),
    );
  }

  /// 予定(細)＋実績(太)の2レイヤー構造バーを描画する。
  /// - 予定バー: full width・高さ10・淡い色
  /// - 実績バー: progressに応じた幅・高さ14・濃い色
  Widget _buildLayeredBar({
    required double width,
    required Color baseColor,
    required double progress,
  }) {
    const double plannedHeight = 10;
    const double actualHeight = 14;
    final double clampedProgress = progress.clamp(0.0, 1.0);

    return SizedBox(
      width: width,
      height: actualHeight,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // 予定バー（細・淡色）
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: width,
              height: plannedHeight,
              decoration: BoxDecoration(
                color: baseColor.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: baseColor.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
          // 実績バー（太・不透明）
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: width * clampedProgress,
              height: actualHeight,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayLine() {
    final today = DateTime.now();
    final todayBase = DateTime(today.year, today.month, today.day);
    final offset = todayBase.difference(_startDate).inDays;
    if (offset < 0 || offset >= _totalDays) {
      return const SizedBox.shrink();
    }
    return Positioned(
      left: offset * _dayWidth,
      top: 0,
      bottom: 0,
      child: Container(width: 2, color: Colors.red.withValues(alpha: 0.6)),
    );
  }

  /// 予定完了日の縦ライン（行内のみ）
  Widget _buildPlannedEndLine(GanttTask task) {
    final planned = task.plannedEnd;
    if (planned == null) {
      return const SizedBox.shrink();
    }
    final plannedOnly = DateTime(planned.year, planned.month, planned.day);
    final offsetDays = plannedOnly.difference(_startDate).inDays;
    if (offsetDays < 0 || offsetDays >= _totalDays) {
      // タイムライン範囲外
      return const SizedBox.shrink();
    }

    final color = _plannedLineColor(task);
    if (color == Colors.transparent) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: offsetDays * _dayWidth,
      top: 0,
      bottom: 0,
      child: Container(width: 2, color: color),
    );
  }

  /// 予定ラインの色（進捗状況によって変化）
  Color _plannedLineColor(GanttTask task) {
    final planned = task.plannedEnd;
    if (planned == null) return Colors.transparent;

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final plannedOnly = DateTime(planned.year, planned.month, planned.day);
    final actualEndOnly = DateTime(task.end.year, task.end.month, task.end.day);

    // 予定内に完了（前倒し含む）
    if (task.progress >= 1.0 && !actualEndOnly.isAfter(plannedOnly)) {
      return Colors.green;
    }
    // 予定日を過ぎても未完了 → 遅れ
    if (task.progress < 1.0 && todayOnly.isAfter(plannedOnly)) {
      return Colors.red;
    }
    // それ以外は薄いグレー
    return Colors.grey.withValues(alpha: 0.6);
  }

  List<GanttRowEntry> _filterRowsByKeyword(List<GanttRowEntry> rows) {
    if (_keyword.isEmpty) return rows;
    final kw = _keyword.toLowerCase();
    return rows.where((e) {
      switch (e.kind) {
        case GanttRowKind.productHeader:
          return e.product.code.toLowerCase().contains(kw) ||
              e.product.name.toLowerCase().contains(kw);
        case GanttRowKind.taskRow:
          return (e.task?.name.toLowerCase().contains(kw) ?? false) ||
              e.product.code.toLowerCase().contains(kw);
      }
    }).toList();
  }

  /// process_groups ベースで工程別ビュー用の集計を行う
  /// 行 = process_groups（一次加工/コア部/...）を親とし、将来は子工程(process_steps)を展開する拡張を想定。
  List<ProcessGroupSummary> _buildProcessSummaries(
    List<GanttProduct> products,
  ) {
    // SPEC 順固定（一次加工 → コア部 → 仕口部 → 大組部 → 二次部材 → 製品検査 → 製品塗装 → 積込 → 出荷）
    const orderedGroups = [
      {'key': 'primary', 'label': '一次加工'},
      {'key': 'core', 'label': 'コア部'},
      {'key': 'shikuchi', 'label': '仕口部'},
      {'key': 'oogumi', 'label': '大組部'},
      {'key': 'niji', 'label': '二次部材'},
      {'key': 'productInspection', 'label': '製品検査'},
      {'key': 'coating', 'label': '製品塗装'},
      {'key': 'loading', 'label': '積込'},
      {'key': 'shipping', 'label': '出荷'},
    ];

    // まずタスクを processGroupKey / Label でまとめる
    final Map<String, List<GanttTask>> groupedTasks = {};

    for (final product in products) {
      for (final task in product.tasks) {
        final key =
            (task.processGroupKey ?? task.processGroupId ?? '').trim();
        final label = (task.processGroupLabel ?? '').trim();
        final mapKey = key.isNotEmpty ? key : (label.isNotEmpty ? label : 'other');
        groupedTasks.putIfAbsent(mapKey, () => <GanttTask>[]).add(task);
      }
    }

    // SPEC 順で並べ替えつつ、タスクが無いグループも空で出す
    final List<ProcessGroupSummary> list = [];
    for (var i = 0; i < orderedGroups.length; i++) {
      final spec = orderedGroups[i];
      final key = spec['key']!;
      final label = spec['label']!;
      // ラベル一致・キー一致のどちらかで拾う
      final tasks = groupedTasks[key] ??
          groupedTasks[label] ??
          <GanttTask>[];
      list.add(
        ProcessGroupSummary(
          key: key,
          label: label,
          sortOrder: i, // 固定順
          tasks: tasks,
        ),
      );
    }

    // SPEC に無いグループがあれば「その他」として後ろに付ける
    final usedKeys = {...orderedGroups.map((g) => g['key']), ...orderedGroups.map((g) => g['label'])};
    groupedTasks.forEach((key, tasks) {
      if (usedKeys.contains(key)) return;
      list.add(
        ProcessGroupSummary(
          key: key,
          label: 'その他',
          sortOrder: 999,
          tasks: tasks,
        ),
      );
    });

    return list;
  }

  List<ProcessGroupSummary> _filterSummariesByKeyword(
    List<ProcessGroupSummary> summaries,
  ) {
    if (_keyword.isEmpty) return summaries;
    final kw = _keyword.toLowerCase();
    return summaries
        .where(
          (s) =>
              s.label.toLowerCase().contains(kw) ||
              s.tasks.any((t) => t.name.toLowerCase().contains(kw)),
        )
        .toList();
  }

  void _onPlanDragStart(String groupKey, _DragMode mode) {
    _draggingGroupKey = groupKey;
    _dragMode = mode;
    _dragAccumulatedDx = 0.0;
    _dragStartOffset = _groupPlanOffsets[groupKey] ?? const GroupPlanOffset();
  }

  void _onPlanDragUpdate(String groupKey, double deltaDx) {
    if (_draggingGroupKey != groupKey || _dragMode == null) return;
    _dragAccumulatedDx += deltaDx;
    final deltaDays = (_dragAccumulatedDx / _dayWidth).truncate();
    if (deltaDays == 0) return;

    final current = _dragStartOffset;
    GroupPlanOffset next;
    switch (_dragMode!) {
      case _DragMode.move:
        next = current.copyWith(shiftDays: current.shiftDays + deltaDays);
        break;
      case _DragMode.resizeLeft:
        next = current.copyWith(startExtra: current.startExtra + deltaDays);
        break;
      case _DragMode.resizeRight:
        next = current.copyWith(endExtra: current.endExtra + deltaDays);
        break;
    }

    setState(() {
      _groupPlanOffsets[groupKey] = next;
    });
  }

  void _onPlanDragEnd(String groupKey) {
    _draggingGroupKey = null;
    _dragMode = null;
    _dragAccumulatedDx = 0.0;
  }

  /// 工程別ビューで行をタップしたとき、その工程グループに属する製品別タスクの一覧をモーダルで表示する（閲覧専用）
  Future<void> _showProcessGroupDetail(
    BuildContext context,
    ProcessGroupSummary summary,
    Color baseColor,
  ) async {
    final tasks = summary.tasks;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                // キーボードが出ても余白を確保
                bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: baseColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        summary.label,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'タスク数: ${tasks.length}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        final start = _formatDate(task.start);
                        final end = _formatDate(task.end);
                        final progressPercent =
                            (task.progress.clamp(0.0, 1.0) * 100).round();
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: baseColor,
                              child: Text('${index + 1}'),
                            ),
                            title: Text(task.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$start 〜 $end'),
                                Text('工程: ${task.name}'),
                                LinearProgressIndicator(
                                  value: task.progress.clamp(0.0, 1.0),
                                ),
                                Text('進捗: $progressPercent%'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<GanttProduct> _filteredProductsFromList(List<GanttProduct> list) {
    if (_keyword.isEmpty) return list;
    final kw = _keyword.toLowerCase();
    return list
        .where(
          (p) =>
              p.code.toLowerCase().contains(kw) ||
              p.name.toLowerCase().contains(kw) ||
              p.tasks.any((t) => t.name.toLowerCase().contains(kw)),
        )
        .toList();
  }

  void _updateDateRange(List<GanttProduct> products) {
    DateTime? minStart;
    DateTime? maxEnd;
    for (final p in products) {
      for (final t in p.tasks) {
        minStart = minStart == null || t.start.isBefore(minStart)
            ? t.start
            : minStart;
        maxEnd = maxEnd == null || t.end.isAfter(maxEnd) ? t.end : maxEnd;
      }
    }
    final now = DateTime.now();
    // データが無い場合もカレンダーを一定期間表示する（デフォルト14日間）
    DateTime start;
    DateTime end;
    if (minStart == null || maxEnd == null) {
      start = DateTime(now.year, now.month, now.day).subtract(
        const Duration(days: 3),
      );
      end = start.add(const Duration(days: 13)); // 合計14日
    } else {
      start = minStart;
      end = maxEnd;
      // 極端に短い期間の場合は少し余白を足す
      final minDays = 14;
      final totalDays = end.difference(start).inDays + 1;
      if (totalDays < minDays) {
        end = start.add(Duration(days: minDays - 1));
      }
    }

    final total = end.difference(start).inDays + 1;

    final needsUpdate =
        _startDate != start || _endDate != end || _totalDays != total;
    if (needsUpdate) {
      _startDate = start;
      _endDate = end;
      _totalDays = total;
    }
  }
}
