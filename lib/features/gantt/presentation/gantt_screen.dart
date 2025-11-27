import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/project.dart';
import '../application/gantt_providers.dart';

/// 工種種別
enum ProcessType { coreAssembly, coreWeld, jointAssembly, jointWeld, other }

/// 表示モード（製品別 / 工種別）
enum GanttViewMode { byProduct, byProcess }

/// 1タスク（工種）を表すモデル
class GanttTask {
  final String id;
  final String name;
  final ProcessType type;
  final DateTime start;
  final DateTime end;
  final double progress;

  const GanttTask({
    required this.id,
    required this.name,
    required this.type,
    required this.start,
    required this.end,
    required this.progress,
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

/// 工種別集計行
class ProcessSummary {
  final ProcessType type;
  final String label;
  final List<GanttTask> tasks;

  const ProcessSummary({
    required this.type,
    required this.label,
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
  static const double _dayWidth = 40;
  static const double _rowHeight = 32;

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
  GanttViewMode _viewMode = GanttViewMode.byProduct;

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

  Color _taskBaseColor(ProcessType type) {
    switch (type) {
      case ProcessType.coreAssembly:
        return Colors.lightBlue;
      case ProcessType.coreWeld:
        return Colors.blue;
      case ProcessType.jointAssembly:
        return Colors.orangeAccent;
      case ProcessType.jointWeld:
        return Colors.deepOrange;
      case ProcessType.other:
      default:
        return Colors.grey;
    }
  }

  _TaskGeometry? _computeTaskGeometry(
    GanttTask task,
    DateTime startDate,
    int totalDays,
    double dayWidth,
  ) {
    int startOffsetDays = task.start.difference(startDate).inDays;
    int durationDays = task.end.difference(task.start).inDays + 1;

    if (startOffsetDays + durationDays < 0) return null;
    if (startOffsetDays < 0) {
      durationDays += startOffsetDays;
      startOffsetDays = 0;
    }
    if (startOffsetDays >= totalDays) return null;
    if (startOffsetDays + durationDays > totalDays) {
      durationDays = totalDays - startOffsetDays;
    }
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
            onPressed: (i) => setState(() => _viewRangeIndex = i),
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
              // 将来: 今日位置へスクロール
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
    required List<ProcessSummary> summaries,
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

  Widget _buildLeftPaneByProcess(List<ProcessSummary> summaries) {
    return ListView.builder(
      controller: _leftScroll,
      itemCount: summaries.length,
      itemBuilder: (context, index) {
        final summary = summaries[index];
        final color = _taskBaseColor(summary.type);
        final allStarts = summary.tasks.map((t) => t.start).toList()..sort();
        final allEnds = summary.tasks.map((t) => t.end).toList()..sort();
        final start = allStarts.isNotEmpty ? allStarts.first : null;
        final end = allEnds.isNotEmpty ? allEnds.last : null;
        return ListTile(
          leading: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          title: Text(summary.label),
          subtitle: Text(
            [
              'タスク数: ${summary.tasks.length}',
              if (start != null && end != null)
                '${_formatDate(start)} 〜 ${_formatDate(end)}',
            ].join(' / '),
          ),
        );
      },
    );
  }

  Widget _buildRightPane({
    required List<GanttRowEntry> rowEntries,
    required List<ProcessSummary> summaries,
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
    final baseColor = _taskBaseColor(task.type);
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
    return Column(
      children: [
        _buildTimelineHeader(),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            controller: _rightScroll,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: _totalDays * _dayWidth,
              child: ListView.builder(
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final entry = rows[index];
                  switch (entry.kind) {
                    case GanttRowKind.productHeader:
                      return _buildProductTimelineRow(entry.product);
                    case GanttRowKind.taskRow:
                      return _buildTaskTimelineRow(entry.task!);
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineByProcess(List<ProcessSummary> summaries) {
    return Column(
      children: [
        _buildTimelineHeader(),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            controller: _rightScroll,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: _totalDays * _dayWidth,
              child: ListView.builder(
                itemCount: summaries.length,
                itemBuilder: (context, index) {
                  final summary = summaries[index];
                  return _buildProcessTimelineRow(summary);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineHeader() {
    return SizedBox(
      height: 32,
      child: SingleChildScrollView(
        controller: _rightHeaderScroll,
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_totalDays, (i) {
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

  Widget _buildRowGrid() {
    return Row(
      children: List.generate(_totalDays, (i) {
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
            border: Border(right: BorderSide(color: Colors.grey.shade300)),
          ),
        );
      }),
    );
  }

  Widget _buildProcessTimelineRow(ProcessSummary summary) {
    return SizedBox(
      height: _rowHeight,
      child: Stack(
        children: [
          Positioned.fill(child: _buildRowGrid()),
          for (final task in summary.tasks)
            _buildProcessTaskBar(task, _taskBaseColor(summary.type)),
        ],
      ),
    );
  }

  Widget _buildProcessTaskBar(GanttTask task, Color baseColor) {
    final geo = _computeTaskGeometry(task, _startDate, _totalDays, _dayWidth);
    if (geo == null) return const SizedBox.shrink();
    final progress = task.progress.clamp(0.0, 1.0);

    return Positioned(
      left: geo.left,
      top: 8,
      child: Container(
        width: geo.width,
        height: 16,
        decoration: BoxDecoration(
          color: baseColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: baseColor.withValues(alpha: 0.7)),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: geo.width * progress,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductTimelineRow(GanttProduct product) {
    return SizedBox(
      height: _rowHeight,
      child: Stack(
        children: [
          Positioned.fill(child: _buildRowGrid()),
          _buildTodayLine(),
          for (final task in product.tasks) _buildTaskBar(task),
        ],
      ),
    );
  }

  Widget _buildTaskTimelineRow(GanttTask task) {
    final geo = _computeTaskGeometry(task, _startDate, _totalDays, _dayWidth);
    final baseColor = _taskBaseColor(task.type);
    final progress = task.progress.clamp(0.0, 1.0);

    return SizedBox(
      height: _rowHeight,
      child: Stack(
        children: [
          Positioned.fill(child: _buildRowGrid()),
          _buildTodayLine(),
          if (geo != null)
            Positioned(
              left: geo.left,
              top: 8,
              child: Container(
                width: geo.width,
                height: 16,
                decoration: BoxDecoration(
                  color: baseColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: baseColor),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: geo.width * progress,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskBar(GanttTask task) {
    final geo = _computeTaskGeometry(task, _startDate, _totalDays, _dayWidth);
    if (geo == null) return const SizedBox.shrink();
    final baseColor = _taskBaseColor(task.type);
    final progress = task.progress.clamp(0.0, 1.0);

    return Positioned(
      left: geo.left,
      top: 8,
      child: Container(
        width: geo.width,
        height: 16,
        decoration: BoxDecoration(
          color: baseColor.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: baseColor),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: geo.width * progress,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
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

  List<ProcessSummary> _buildProcessSummaries(List<GanttProduct> products) {
    final Map<ProcessType, List<GanttTask>> map = {};
    for (final product in products) {
      for (final task in product.tasks) {
        map.putIfAbsent(task.type, () => <GanttTask>[]).add(task);
      }
    }
    final summaries = <ProcessSummary>[];
    for (final entry in map.entries) {
      summaries.add(
        ProcessSummary(
          type: entry.key,
          label: _processTypeLabel(entry.key),
          tasks: entry.value,
        ),
      );
    }
    summaries.sort(
      (a, b) => _processTypeOrder(a.type) - _processTypeOrder(b.type),
    );
    return summaries;
  }

  List<ProcessSummary> _filterSummariesByKeyword(
    List<ProcessSummary> summaries,
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

  String _processTypeLabel(ProcessType type) {
    switch (type) {
      case ProcessType.coreAssembly:
        return 'コア組立';
      case ProcessType.coreWeld:
        return 'コア溶接';
      case ProcessType.jointAssembly:
        return '仕口組立';
      case ProcessType.jointWeld:
        return '仕口溶接';
      case ProcessType.other:
      default:
        return 'その他';
    }
  }

  int _processTypeOrder(ProcessType type) {
    switch (type) {
      case ProcessType.coreAssembly:
        return 0;
      case ProcessType.coreWeld:
        return 1;
      case ProcessType.jointAssembly:
        return 2;
      case ProcessType.jointWeld:
        return 3;
      case ProcessType.other:
      default:
        return 99;
    }
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
        minStart = minStart == null || t.start.isBefore(minStart!)
            ? t.start
            : minStart;
        maxEnd = maxEnd == null || t.end.isAfter(maxEnd!) ? t.end : maxEnd;
      }
    }
    final now = DateTime.now();
    final start = minStart ?? now.subtract(const Duration(days: 3));
    final end = maxEnd ?? now.add(const Duration(days: 14));
    final needsUpdate =
        _startDate != start ||
        _endDate != end ||
        _totalDays != end.difference(start).inDays + 1;
    if (needsUpdate) {
      _startDate = start;
      _endDate = end;
      _totalDays = _endDate.difference(_startDate).inDays + 1;
    }
  }
}
