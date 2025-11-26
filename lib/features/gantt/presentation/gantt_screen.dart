import 'package:flutter/material.dart';
import '../../../models/project.dart';

/// 工種タイプ
enum ProcessType { coreAssembly, coreWeld, jointAssembly, jointWeld, other }

/// 工種タスク（1工程のバー）
class GanttTask {
  final String id;
  final String name;
  final ProcessType type;
  final DateTime start;
  final DateTime end;
  final double progress; // 0.0〜1.0

  const GanttTask({
    required this.id,
    required this.name,
    required this.type,
    required this.start,
    required this.end,
    required this.progress,
  });
}

/// 製品行
class GanttProduct {
  final String id;
  final String code;
  final String name;
  final double progress; // 製品全体進捗
  final List<GanttTask> tasks;

  const GanttProduct({
    required this.id,
    required this.code,
    required this.name,
    required this.progress,
    required this.tasks,
  });
}

/// タスクの描画位置
class _TaskGeometry {
  final double left;
  final double width;
  const _TaskGeometry({required this.left, required this.width});
}

/// ガントチャート画面（ダミーデータ版）
class GanttScreen extends StatefulWidget {
  final Project project;
  const GanttScreen({super.key, required this.project});

  @override
  State<GanttScreen> createState() => _GanttScreenState();
}

class _GanttScreenState extends State<GanttScreen> {
  // 画面内状態
  final _projects = const ['工事A', '工事B'];
  String _selectedProject = '工事A';
  String _keyword = '';
  int _viewModeIndex = 1; // 0:日 1:週 2:月

  late final List<GanttProduct> _products;
  late DateTime _startDate;
  late DateTime _endDate;
  late int _totalDays;

  // スクロール同期用
  final _headerScroll = ScrollController();
  final _bodyScroll = ScrollController();

  // レイアウト定数
  double get _dayWidth {
    switch (_viewModeIndex) {
      case 0:
        return 40;
      case 1:
        return 32;
      case 2:
      default:
        return 24;
    }
  }

  static const double _rowHeight = 48;

  @override
  void initState() {
    super.initState();
    _products = _buildDummyProducts(widget.project);
    _recalcRange();
    // 横スクロール同期
    _bodyScroll.addListener(() {
      if (_headerScroll.hasClients) {
        _headerScroll.jumpTo(_bodyScroll.offset);
      }
    });
  }

  @override
  void dispose() {
    _headerScroll.dispose();
    _bodyScroll.dispose();
    super.dispose();
  }

  // ダミーデータ生成（後で Firestore で置き換えられる構造）
  List<GanttProduct> _buildDummyProducts(Project project) {
    final today = DateTime.now();
    final base = DateTime(today.year, today.month, today.day);
    DateTime d(int offset) => base.add(Duration(days: offset));

    return [
      GanttProduct(
        id: 'p-1',
        code: '1C-X1Y1',
        name: '1C-X1Y1',
        progress: 0.6,
        tasks: [
          GanttTask(
            id: 't1-core-assy',
            name: 'コア組立',
            type: ProcessType.coreAssembly,
            start: d(-1),
            end: d(2),
            progress: 0.9,
          ),
          GanttTask(
            id: 't1-core-weld',
            name: 'コア溶接',
            type: ProcessType.coreWeld,
            start: d(1),
            end: d(4),
            progress: 0.5,
          ),
          GanttTask(
            id: 't1-joint-assy',
            name: '仕口組立',
            type: ProcessType.jointAssembly,
            start: d(3),
            end: d(6),
            progress: 0.3,
          ),
          GanttTask(
            id: 't1-joint-weld',
            name: '仕口溶接',
            type: ProcessType.jointWeld,
            start: d(5),
            end: d(8),
            progress: 0.1,
          ),
        ],
      ),
      GanttProduct(
        id: 'p-2',
        code: '1C-X1Y2',
        name: '1C-X1Y2',
        progress: 0.3,
        tasks: [
          GanttTask(
            id: 't2-core-assy',
            name: 'コア組立',
            type: ProcessType.coreAssembly,
            start: d(0),
            end: d(1),
            progress: 0.4,
          ),
          GanttTask(
            id: 't2-core-weld',
            name: 'コア溶接',
            type: ProcessType.coreWeld,
            start: d(2),
            end: d(4),
            progress: 0.2,
          ),
          GanttTask(
            id: 't2-joint-assy',
            name: '仕口組立',
            type: ProcessType.jointAssembly,
            start: d(4),
            end: d(7),
            progress: 0.1,
          ),
        ],
      ),
      GanttProduct(
        id: 'p-3',
        code: '2G-X1Y1',
        name: '2G-X1Y1',
        progress: 0.8,
        tasks: [
          GanttTask(
            id: 't3-joint-weld',
            name: '仕口溶接',
            type: ProcessType.jointWeld,
            start: d(-2),
            end: d(1),
            progress: 1.0,
          ),
          GanttTask(
            id: 't3-other',
            name: 'その他',
            type: ProcessType.other,
            start: d(2),
            end: d(3),
            progress: 0.5,
          ),
          GanttTask(
            id: 't3-core-assy',
            name: 'コア組立',
            type: ProcessType.coreAssembly,
            start: d(4),
            end: d(6),
            progress: 0.2,
          ),
        ],
      ),
    ];
  }

  void _recalcRange() {
    // 画面用の開始・終了日を計算（ダミーなのでタスク範囲に少し余裕を持たせる）
    final starts = <DateTime>[];
    final ends = <DateTime>[];
    for (final p in _products) {
      for (final t in p.tasks) {
        starts.add(_dateOnly(t.start));
        ends.add(_dateOnly(t.end));
      }
    }
    final today = _dateOnly(DateTime.now());
    if (starts.isEmpty || ends.isEmpty) {
      _startDate = today.subtract(const Duration(days: 3));
      _endDate = today.add(const Duration(days: 14));
    } else {
      _startDate = starts.reduce((a, b) => a.isBefore(b) ? a : b)
          .subtract(const Duration(days: 2));
      _endDate =
          ends.reduce((a, b) => a.isAfter(b) ? a : b).add(const Duration(days: 3));
    }
    _totalDays = _endDate.difference(_startDate).inDays + 1;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredProducts();
    return Scaffold(
      appBar: AppBar(
        title: Text('ガントチャート - ${widget.project.name}'),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedProject,
              items: _projects
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedProject = v ?? _selectedProject),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 160,
            child: TextField(
              decoration: const InputDecoration(
                isDense: true,
                hintText: '製品検索',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _keyword = v),
            ),
          ),
          const SizedBox(width: 8),
          ToggleButtons(
            isSelected: [
              _viewModeIndex == 0,
              _viewModeIndex == 1,
              _viewModeIndex == 2
            ],
            onPressed: (i) => setState(() => _viewModeIndex = i),
            children: const [
              Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('日')),
              Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('週')),
              Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('月')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: '今日へ',
            onPressed: () {
              setState(() {
                final today = _dateOnly(DateTime.now());
                _startDate = today.subtract(const Duration(days: 3));
                _endDate = today.add(const Duration(days: 14));
                _totalDays = _endDate.difference(_startDate).inDays + 1;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '更新',
            onPressed: () => setState(() {}),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 900) {
            return _buildDesktop(filtered);
          } else {
            return _buildMobile(filtered);
          }
        },
      ),
    );
  }

  // PC 向け: 左リスト + 右タイムライン
  Widget _buildDesktop(List<GanttProduct> products) {
    final timelineWidth = _totalDays * _dayWidth;
    return Row(
      children: [
        SizedBox(
          width: 280,
          child: ListView.builder(
            itemCount: products.length,
            itemBuilder: (_, i) {
              final p = products[i];
              return ListTile(
                title: Text(p.code),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(value: p.progress),
                  ],
                ),
              );
            },
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: Column(
            children: [
              _buildTimelineHeader(),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: _bodyScroll,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: timelineWidth,
                    child: ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (_, i) {
                        final p = products[i];
                        return _buildProductTimelineRow(p);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // モバイル向け: 1 カラム
  Widget _buildMobile(List<GanttProduct> products) {
    final timelineWidth = _totalDays * _dayWidth;
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (_, i) {
        final p = products[i];
        return Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.code, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(p.name),
                const SizedBox(height: 4),
                LinearProgressIndicator(value: p.progress),
                const SizedBox(height: 8),
                SizedBox(
                  height: _rowHeight,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: timelineWidth,
                      child: _buildProductTimelineRow(p, showBackground: false),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // タイムラインヘッダ（日付）
  Widget _buildTimelineHeader() {
    return SizedBox(
      height: 44,
      child: SingleChildScrollView(
        controller: _headerScroll,
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_totalDays, (idx) {
            final date = _startDate.add(Duration(days: idx));
            return Container(
              width: _dayWidth,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.grey.shade300, width: 0.5),
                ),
              ),
              alignment: Alignment.center,
              child: Text('${date.month}/${date.day}',
                  style: const TextStyle(fontSize: 12)),
            );
          }),
        ),
      ),
    );
  }

  // 1 製品行のタイムライン（複数タスクを同一行に表示）
  Widget _buildProductTimelineRow(GanttProduct product, {bool showBackground = true}) {
    return SizedBox(
      height: _rowHeight,
      child: Stack(
        children: [
          if (showBackground)
            Positioned.fill(
              child: Row(
                children: List.generate(
                  _totalDays,
                  (i) => Container(
                    width: _dayWidth,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: Colors.grey.shade200,
                          width: 0.5,
                        ),
                        bottom: BorderSide(
                          color: Colors.grey.shade300,
                          width: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // 今日のライン（表示期間内のみ）
          _buildTodayLine(),
          // 各タスクバー
          for (final task in product.tasks) _buildTaskBar(task),
        ],
      ),
    );
  }

  // 今日を示す縦ライン（表示期間内のみ）
  Widget _buildTodayLine() {
    final today = _dateOnly(DateTime.now());
    if (today.isBefore(_startDate) || today.isAfter(_endDate)) {
      return const SizedBox.shrink();
    }
    final offsetDays = today.difference(_startDate).inDays;
    return Positioned(
      left: offsetDays * _dayWidth,
      top: 0,
      bottom: 0,
      child: Container(
        width: 2,
        color: Colors.red.withValues(alpha: (0.6 * 255).round().toDouble()),
      ),
    );
  }

  // タスクバーを1つ描画（予定バー + 進捗バー）
  Widget _buildTaskBar(GanttTask task) {
    final geo = _computeTaskGeometry(task, _startDate, _totalDays, _dayWidth);
    if (geo == null) return const SizedBox.shrink();

    final baseColor = _taskBaseColor(task.type);
    final progress = task.progress.clamp(0.0, 1.0);

    return Positioned(
      left: geo.left,
      top: (_rowHeight - 16) / 2,
      child: Container(
        width: geo.width,
        height: 16,
        decoration: BoxDecoration(
          color:
              baseColor.withValues(alpha: (0.25 * 255).round().toDouble()), // 予定バー（薄い色）
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: baseColor),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: geo.width * progress, // 実績バー（濃い色）
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }

  // タスクの描画位置計算（画面外は切り詰め/非表示）
  _TaskGeometry? _computeTaskGeometry(
      GanttTask task, DateTime startDate, int totalDays, double dayWidth) {
    int startOffsetDays = task.start.difference(startDate).inDays;
    int durationDays = task.end.difference(task.start).inDays + 1;

    // 完全に左に出る
    if (startOffsetDays + durationDays < 0) return null;

    // 左にはみ出した分を削る
    if (startOffsetDays < 0) {
      durationDays += startOffsetDays;
      startOffsetDays = 0;
    }

    // 完全に右に出る
    if (startOffsetDays >= totalDays) return null;

    // 右にはみ出した分を削る
    if (startOffsetDays + durationDays > totalDays) {
      durationDays = totalDays - startOffsetDays;
    }

    if (durationDays <= 0) return null;

    final left = startOffsetDays * dayWidth;
    final width = durationDays * dayWidth;
    return _TaskGeometry(left: left, width: width);
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
        return Colors.grey;
    }
  }

  List<GanttProduct> _filteredProducts() {
    if (_keyword.isEmpty) return _products;
    final kw = _keyword.toLowerCase();
    return _products
        .where((p) =>
            p.code.toLowerCase().contains(kw) ||
            p.name.toLowerCase().contains(kw))
        .toList();
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
