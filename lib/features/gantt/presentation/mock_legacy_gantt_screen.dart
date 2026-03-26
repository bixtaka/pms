import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legacy_gantt_chart/legacy_gantt_chart.dart';
import '../utils/gantt_data_adapter.dart';
import '../../../features/products/application/product_providers.dart';
import '../application/gantt_providers.dart';
import '../application/gantt_shared_providers.dart';
import '../../process_spec/data/process_progress_daily_repository.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

import '../../projects/presentation/project_settings_screen.dart';
import '../../../features/projects/application/project_providers.dart';
import '../../../features/projects/domain/project.dart';

// ─── 共通定数 ─────────────────────────────────────────────────────────────────
/// 左ペインと右チャートで使う 1行の高さ（両側で完全一致）
const double kRowHeight = 55.0;

/// タイムラインヘッダーの高さ（左ペインヘッダーと完全一致）
const double kAxisHeight = 60.0;

/// 左ペインの幅
const double kLeftPaneWidth = 280.0;

/// チャートの表示スケール（ズームレベル）
enum GanttViewScale { day, week, month }
// ─────────────────────────────────────────────────────────────────────────────

final masterGanttDataProvider = FutureProvider.autoDispose<GanttChartData>((
  ref,
) async {
  return _buildMasterRichMockData();
});

GanttChartData _buildMasterRichMockData() {
  final now = DateTime.now();
  DateTime s(int daysAgo) => DateTime(now.year, now.month, now.day - daysAgo);

  Color cFor(String name) {
    final hue = name.hashCode.abs() % 360.0;
    return HSLColor.fromAHSL(1.0, hue, 0.65, 0.42).toColor();
  }

  final tasks = <LegacyGanttTask>[];
  final rows = <LegacyGanttRow>[];
  final categoryTrees = <GanttCategoryTree>[];

  final projectsParams = [
    (id: 'prj_a', name: 'テスト工事 A工区', offset: -45),
    (id: 'prj_b', name: '新築工事 B工区', offset: -15),
    (id: 'prj_c', name: '改修工事 C工区', offset: 15),
    (id: 'prj_d', name: 'プラント D工区', offset: 60),
  ];

  int sortOrder = 0;
  for (final p in projectsParams) {
    final pStart = s(-p.offset); // offsetが負ならs(45), 正ならs(-15)=d(15)となる
    final prjTasks = [
      (
        cId: 'cat_1',
        cName: '一次加工',
        start: pStart,
        end: pStart.add(const Duration(days: 30)),
        pct: 100,
      ),
      (
        cId: 'cat_2',
        cName: 'コア部',
        start: pStart.add(const Duration(days: 20)),
        end: pStart.add(const Duration(days: 60)),
        pct: 60,
      ),
      (
        cId: 'cat_3',
        cName: '仕口部',
        start: pStart.add(const Duration(days: 40)),
        end: pStart.add(const Duration(days: 90)),
        pct: 20,
      ),
      (
        cId: 'cat_4',
        cName: '梁・桁',
        start: pStart.add(const Duration(days: 70)),
        end: pStart.add(const Duration(days: 120)),
        pct: 0,
      ),
    ];

    DateTime minStart = prjTasks.first.start;
    DateTime maxEnd = prjTasks.first.end;
    for (final c in prjTasks) {
      if (c.start.isBefore(minStart)) minStart = c.start;
      if (c.end.isAfter(maxEnd)) maxEnd = c.end;
    }

    rows.add(LegacyGanttRow(id: p.id, label: p.name));

    tasks.add(
      LegacyGanttTask(
        id: p.id,
        rowId: p.id,
        name: p.name,
        start: minStart,
        end: maxEnd,
        isSummary: true,
        color: Colors.blueGrey.shade700,
      ),
    );

    final processes = <GanttProcessLeaf>[];
    for (int j = 0; j < prjTasks.length; j++) {
      final c = prjTasks[j];
      final rowId = '${p.id}_${c.cId}';

      final color = cFor(c.cName);

      tasks.add(
        LegacyGanttTask(
          id: '${rowId}_task',
          rowId: rowId,
          name: c.cName,
          start: c.start,
          end: c.end,
          color: color,
        ),
      );

      processes.add(
        GanttProcessLeaf(
          stepId: c.cId,
          displayName: c.cName,
          sortOrder: j,
          taskId: '${rowId}_task',
          rowId: rowId,
          start: c.start,
          end: c.end,
        ),
      );
    }

    categoryTrees.add(
      GanttCategoryTree(
        categoryId: p.id,
        categoryName: p.name,
        sortOrder: sortOrder++,
        processes: processes,
        start: minStart,
        end: maxEnd,
      ),
    );
  }

  return GanttChartData(
    tasks: tasks,
    rows: rows,
    rowMaxStackDepth: const {},
    categoryTrees: categoryTrees,
  );
}

final mockGanttDataProvider = FutureProvider.autoDispose
    .family<GanttChartData, String>((ref, projectId) async {
      final products = await ref.watch(
        productsByProjectProvider(projectId).future,
      );
      // Dummy project since we only need ID for firestoreTasksProvider
      final dummyProject = Project(id: projectId, name: '', createdAt: DateTime.now(), updatedAt: DateTime.now());
      final spec = await ref.watch(ganttProcessSpecProvider(dummyProject).future);

      final dailyRepo = ProcessProgressDailyRepository();
      final Map<String, Map<String, List<GanttDailyEntry>>> progressByStepId =
          {};
      for (final product in products) {
        final dailies = await dailyRepo.fetchDaily(projectId, product.id);
        for (final d in dailies) {
          progressByStepId
              .putIfAbsent(d.stepId, () => {})
              .putIfAbsent(product.id, () => [])
              .add(GanttDailyEntry(date: d.date));
        }
      }

      return GanttDataAdapter.convertFromDaily(
        products: products,
        progressByStepId: progressByStepId,
        groups: spec.groups,
        steps: spec.steps,
      );
    });

// ─── リアルデータ用プロバイダ ──────────────────────────────────────────────────

final realProjectGanttDataProvider = Provider.autoDispose
    .family<AsyncValue<GanttChartData>, String>((ref, projectId) {
      // Real data parsing logic
      final docsAsync = ref.watch(firestoreTasksProvider(projectId));

      return docsAsync.whenData((docs) {
        final List<GanttCategoryTree> categoryTrees = [];
        final List<LegacyGanttRow> rows = [];
        final List<LegacyGanttTask> tasks = [];

        Color cFor(String name) {
          if (name.contains('加工')) return Colors.indigo;
          if (name.contains('コア')) return Colors.teal;
          if (name.contains('仕口')) return Colors.cyan;
          if (name.contains('大組')) return Colors.green;
          return Colors.blue;
        }

        // 1. 親と子のドキュメントを分離する
        final parents = docs
            .where(
              (doc) =>
                  doc.data()['parentId'] == null ||
                  doc.data()['isSummary'] == true,
            )
            .toList();
        final childrenMap =
            <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};

        for (var doc in docs) {
          final parentId = doc.data()['parentId'] as String?;
          if (parentId != null) {
            childrenMap.putIfAbsent(parentId, () => []).add(doc);
          }
        }

        // 2. 階層の構築
        int sortOrder = 0;
        for (final p in parents) {
          final pData = p.data();
          final pStartStr = pData['startDate'];
          final pEndStr = pData['endDate'];
          final pStartDate = pStartStr is Timestamp
              ? pStartStr.toDate()
              : DateTime.now();
          final pEndDate = pEndStr is Timestamp
              ? pEndStr.toDate()
              : pStartDate.add(const Duration(days: 10));
          final pName = pData['name'] as String? ?? '名称未定';
          final pColor = cFor(pName);

          // 親の行を追加
          rows.add(LegacyGanttRow(id: p.id, label: pName));

          final processes = <GanttProcessLeaf>[];

          // 子タスクの追加
          final childDocs = childrenMap[p.id] ?? [];

          DateTime? overallMinStart;
          DateTime? overallMaxEnd;

          for (int j = 0; j < childDocs.length; j++) {
            final c = childDocs[j];
            final cData = c.data();
            final cStartStr = cData['startDate'];
            final cEndStr = cData['endDate'];
            final cStartDate = cStartStr is Timestamp
                ? cStartStr.toDate()
                : pStartDate;
            final cEndDate = cEndStr is Timestamp ? cEndStr.toDate() : pEndDate;
            final cName = cData['name'] as String? ?? '未定';

            final rowId = '${p.id}_${c.id}';

            if (overallMinStart == null ||
                cStartDate.isBefore(overallMinStart)) {
              overallMinStart = cStartDate;
            }
            if (overallMaxEnd == null || cEndDate.isAfter(overallMaxEnd)) {
              overallMaxEnd = cEndDate;
            }

            tasks.add(
              LegacyGanttTask(
                id: '${rowId}_task',
                rowId: rowId,
                name: cName,
                start: cStartDate,
                end: cEndDate,
                color: pColor,
              ),
            );

            processes.add(
              GanttProcessLeaf(
                stepId: c.id,
                displayName: cName,
                sortOrder: j,
                taskId: '${rowId}_task',
                rowId: rowId,
                start: cStartDate,
                end: cEndDate,
              ),
            );
          }

          // 親の期間を子の最小/最大に合わせて更新
          final finalPStart = overallMinStart ?? pStartDate;
          final finalPEnd = overallMaxEnd ?? pEndDate;

          tasks.insert(
            0,
            LegacyGanttTask(
              id: p.id,
              rowId: p.id,
              name: pName,
              start: finalPStart,
              end: finalPEnd,
              color: Colors.blueGrey.shade700,
              isSummary: true,
            ),
          );

          categoryTrees.add(
            GanttCategoryTree(
              categoryId: p.id,
              categoryName: pName,
              sortOrder: sortOrder++,
              processes: processes,
              start: finalPStart,
              end: finalPEnd,
            ),
          );
        }

        // Firestoreデータが0件の場合のフォールバック
        if (tasks.isEmpty) {
          final now = DateTime.now();
          rows.add(LegacyGanttRow(id: 'r1', label: 'データがありません'));
          tasks.add(
            LegacyGanttTask(
              id: 'no_data',
              rowId: 'r1',
              name: 'データがありません',
              start: now,
              end: now.add(const Duration(days: 1)),
              color: Colors.grey,
            ),
          );
          categoryTrees.add(
            GanttCategoryTree(
              categoryId: 'cat_empty',
              categoryName: '空',
              sortOrder: 0,
              processes: [],
              start: now,
              end: now.add(const Duration(days: 1)),
            ),
          );
        }

        return GanttChartData(
          tasks: tasks,
          rows: rows,
          rowMaxStackDepth: const {},
          categoryTrees: categoryTrees,
        );
      });
    });

// ─── 画面本体 ─────────────────────────────────────────────────────────────────

// ─── 画面本体 ─────────────────────────────────────────────────────────────────

class MockLegacyGanttScreen extends ConsumerStatefulWidget {
  final String projectId;
  const MockLegacyGanttScreen({super.key, required this.projectId});

  @override
  ConsumerState<MockLegacyGanttScreen> createState() =>
      _MockLegacyGanttScreenState();
}

class _MockLegacyGanttScreenState extends ConsumerState<MockLegacyGanttScreen> {
  GanttViewScale _currentScale = GanttViewScale.week;

  @override
  void initState() {
    super.initState();
    // 初期値としてウィジェットに渡された projectId をセット
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedProjectIdProvider.notifier).state = widget.projectId;
    });
  }

  void _changeScale(GanttViewScale scale) {
    setState(() => _currentScale = scale);
  }

  @override
  Widget build(BuildContext context) {

    final selectedProjectId =
        ref.watch(selectedProjectIdProvider) ?? widget.projectId;

    return DefaultTabController(
      length: 4,
      initialIndex: 1, // 物件タブを初期選択
      child: Scaffold(
        appBar: AppBar(
          title: const Text('マスター工程表・物件詳細'),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProjectSettingsScreen(projectId: selectedProjectId),
                    ),
                  );
                },
                tooltip: '物件設定',
                icon: const Icon(Icons.settings),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: SegmentedButton<GanttViewScale>(
                segments: const [
                  ButtonSegment(
                    value: GanttViewScale.day,
                    label: Text('日', style: TextStyle(fontSize: 12)),
                  ),
                  ButtonSegment(
                    value: GanttViewScale.week,
                    label: Text('週', style: TextStyle(fontSize: 12)),
                  ),
                  ButtonSegment(
                    value: GanttViewScale.month,
                    label: Text('月', style: TextStyle(fontSize: 12)),
                  ),
                ],
                selected: <GanttViewScale>{_currentScale},
                onSelectionChanged: (Set<GanttViewScale> newSelection) {
                  _changeScale(newSelection.first);
                },
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
              ),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: '全体'),
              Tab(text: '物件'),
              Tab(text: '工程'),
              Tab(text: '製品'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            physics: const NeverScrollableScrollPhysics(), // スワイプで切り替えを防止
            children: [
              // 0: 全体
              MasterGanttTab(currentScale: _currentScale),

              // 1: 物件
              ProjectGanttTab(
                projectId: selectedProjectId,
                currentScale: _currentScale,
              ),

              // 2: 工程
              const Center(child: Text('工程ビュー (未実装)')),

              // 3: 製品
              const Center(child: Text('製品ビュー (未実装)')),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 物件タブのコンテナ ────────────────────────────────────────────────────────
class ProjectGanttTab extends ConsumerWidget {
  final String projectId;
  final GanttViewScale currentScale;
  const ProjectGanttTab({
    super.key,
    required this.projectId,
    required this.currentScale,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(realProjectGanttDataProvider(projectId))
        .when(
          skipLoadingOnReload: true,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('エラー: $e')),
          data: (data) => _ProjectGanttWrapper(
            data: data,
            projectId: projectId,
            currentScale: currentScale,
          ),
        );
  }
}

// ─── ラッパー ─────────────────────────────────────────────────────────────────

class _ProjectGanttWrapper extends ConsumerStatefulWidget {
  final GanttChartData data;
  final String projectId;
  final GanttViewScale currentScale;
  const _ProjectGanttWrapper({
    required this.data,
    required this.projectId,
    required this.currentScale,
  });

  @override
  ConsumerState<_ProjectGanttWrapper> createState() => _ProjectGanttWrapperState();
}

class _ProjectGanttWrapperState extends ConsumerState<_ProjectGanttWrapper> {
  late LegacyGanttController _ganttController;
  List<LegacyGanttTask> _tasks = [];

  /// 左ペインの ListView と右チャートで共有するスクロールコントローラー。
  /// - 左：ListView(controller: _sharedScroll)
  /// - 右：LegacyGanttChartWidget(scrollController: _sharedScroll)
  ///   → ViewModel が addListener で offset を受け取り _translateY に反映
  final ScrollController _sharedScroll = ScrollController();

  final Set<String> _expandedCategoryIds = {};

  /// 右ペインの描画幅（LayoutBuilder で取得）。
  /// _shiftGanttRange でピクセル→日時変換に使用する。
  double _chartWidth = 0;

  // ── GanttController ────────────────────────────────────────────────────────

  void _initController({List<LegacyGanttTask>? tasks}) {
    DateTime? minStart;
    DateTime? maxEnd;
    final currentTasks = tasks ?? _tasks;
    for (final t in currentTasks) {
      if (minStart == null || t.start.isBefore(minStart)) minStart = t.start;
      if (maxEnd == null || t.end.isAfter(maxEnd)) maxEnd = t.end;
    }
    final now = DateTime.now();
    minStart ??= now.subtract(const Duration(days: 3));
    maxEnd ??= now.add(const Duration(days: 30));

    final isMobile =
        ui.PlatformDispatcher.instance.views.first.physicalSize.width /
            ui.PlatformDispatcher.instance.views.first.devicePixelRatio <
        600;

    final initialDuration = widget.currentScale == GanttViewScale.day
        ? (isMobile ? const Duration(days: 7) : const Duration(days: 30))
        : widget.currentScale == GanttViewScale.week
        ? const Duration(days: 90)
        : const Duration(days: 365);

    _ganttController = LegacyGanttController(
      initialVisibleStartDate: minStart.subtract(const Duration(days: 3)),
      initialVisibleEndDate: minStart
          .subtract(const Duration(days: 3))
          .add(initialDuration),
      initialTasks: currentTasks,
    );
  }

  // ── 可視データ構築 ─────────────────────────────────────────────────────────

  ({List<LegacyGanttRow> rows, List<LegacyGanttTask> tasks})
  _buildVisibleData() {
    final rows = <LegacyGanttRow>[];
    final visibleTasks = <LegacyGanttTask>[];

    for (final cat in widget.data.categoryTrees) {
      final isEventRoot = cat.categoryId == 'prj_events_root';
      final catId = isEventRoot ? 'prj_events_root' : cat.categoryId;

      rows.add(LegacyGanttRow(id: catId, label: cat.categoryName));

      // 同じ行(rowId)に複数のタスクが存在する可能性があるため、Mapで上書きせずwhereで全て抽出
      final parentTasks = _tasks.where((t) => t.rowId == catId).toList();
      visibleTasks.addAll(parentTasks);

      if (_expandedCategoryIds.contains(catId) && !isEventRoot) {
        for (final leaf in cat.processes) {
          rows.add(LegacyGanttRow(id: leaf.rowId, label: leaf.displayName));
          final leafTasks = _tasks.where((t) => t.rowId == leaf.rowId).toList();
          if (leafTasks.isNotEmpty) visibleTasks.addAll(leafTasks);
        }
      }
    }
    return (rows: rows, tasks: visibleTasks);
  }

  // ── 展開切り替え ───────────────────────────────────────────────────────────

  void _toggleCategory(String catId) {
    setState(() {
      _expandedCategoryIds.contains(catId)
          ? _expandedCategoryIds.remove(catId)
          : _expandedCategoryIds.add(catId);
      final v = _buildVisibleData();
      _ganttController.dispose();
      _initController(tasks: v.tasks);
    });
  }

  // ── ライフサイクル ─────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tasks = List.of(widget.data.tasks);
    _initController(tasks: _buildVisibleData().tasks);
  }

  @override
  void didUpdateWidget(covariant _ProjectGanttWrapper old) {
    super.didUpdateWidget(old);
    if (old.data != widget.data || old.currentScale != widget.currentScale) {
      _tasks = List.of(widget.data.tasks);
      _ganttController.dispose();
      _initController(tasks: _buildVisibleData().tasks);
    }
  }

  @override
  void dispose() {
    _sharedScroll.dispose();
    _ganttController.dispose();
    super.dispose();
  }

  // ── 水平パン・スクロール ────────────────────────────────────────────────────

  /// チャートの表示範囲を [dx] ピクセル分だけ水平シフトする。
  /// 正値→未来方向（右スクロール）、負値→過去方向（左スクロール）。
  void _shiftGanttRange(double dx) {
    if (_chartWidth <= 0) return;
    final totalMs =
        _ganttController.visibleEndDate.millisecondsSinceEpoch -
        _ganttController.visibleStartDate.millisecondsSinceEpoch;
    final shiftMs = (dx / _chartWidth * totalMs).round();
    _ganttController.setVisibleRange(
      _ganttController.visibleStartDate.add(Duration(milliseconds: shiftMs)),
      _ganttController.visibleEndDate.add(Duration(milliseconds: shiftMs)),
    );
  }

  // ── 左ペインアイテム構築 ───────────────────────────────────────────────────
  //
  // 要件: ListTile / ExpansionTile は使用禁止。
  //       すべての行を SizedBox(height: kRowHeight) でラップして高さを厳格に固定。

  List<Widget> _buildLeftItems(bool isMobile) {
    final items = <Widget>[];
    final df = DateFormat('M/d');

    // tasks から検索できるようにマップ化
    final Map<String, LegacyGanttTask> taskMap = {
      for (final t in _tasks) t.id: t,
    };

    for (final cat in widget.data.categoryTrees) {
      final isEventRoot = cat.categoryId == 'prj_events_root';
      final catId = isEventRoot ? 'prj_events_root' : cat.categoryId;
      final expanded = _expandedCategoryIds.contains(catId);
      final parentTask = taskMap[catId];

      final String parentDateStr = parentTask != null
          ? '最終: ${df.format(parentTask.end)}'
          : '最終: -';

      // ── カテゴリ行（大分類） ─── 高さ: kRowHeight ──────────────────────
      items.add(
        SizedBox(
          height: kRowHeight,
          child: InkWell(
            onTap: () => _toggleCategory(catId),
            child: Container(
              color: isEventRoot ? Colors.red.shade50 : Colors.grey.shade200,
              padding: isMobile
                  ? EdgeInsets.zero
                  : const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: isMobile
                  ? Center(
                      child: Icon(
                        isEventRoot ? Icons.flag : Icons.folder,
                        color: isEventRoot
                            ? Colors.red.shade700
                            : Colors.grey.shade700,
                        size: 20,
                      ),
                    )
                  : Row(
                      children: [
                        Icon(
                          isEventRoot
                              ? (expanded ? Icons.flag : Icons.outlined_flag)
                              : (expanded
                                    ? Icons.keyboard_arrow_down
                                    : Icons.keyboard_arrow_right),
                          size: 18,
                          color: isEventRoot ? Colors.red.shade700 : null,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            cat.categoryName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isEventRoot
                                  ? Colors.red.shade900
                                  : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // 右側のリッチな情報（ダミー値 + 日付）
                        if (!isEventRoot)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                '3 / 624 (0%)', // TODO: 実際の進捗データに置き換え
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.black54,
                                ),
                              ),
                              Text(
                                parentDateStr,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
            ),
          ),
        ),
      );

      // ── プロセス行（小分類） ─── 高さ: kRowHeight ─────────────────────
      if (expanded && !isEventRoot) {
        for (final leaf in cat.processes) {
          final childTask = taskMap[leaf.rowId];
          final Color dotColor = childTask?.color ?? Colors.blue;
          final String dateRangeStr = childTask != null
              ? '${df.format(childTask.start)} 〜 ${df.format(childTask.end)}'
              : '-';

          items.add(
            SizedBox(
              height: kRowHeight,
              child: Container(
                color: Colors.white,
                padding: isMobile
                    ? EdgeInsets.zero
                    : const EdgeInsets.only(
                        left: 32,
                        right: 8,
                        top: 4,
                        bottom: 4,
                      ),
                child: isMobile
                    ? Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // ベースカラーの丸印
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  leaf.displayName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'タスク数: 104 / $dateRangeStr', // TODO: 実際のタスク数に置き換え
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.black54,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          );
        }
      }
    }
    return items;
  }

  // ── 予実バー（計画・実績）カスタム描画 ────────────────────────

  Widget _buildCustomTaskBar(LegacyGanttTask task) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // constraints.maxWidth は「実績（start〜end）」の描画幅に相当する。
        // パッケージ側で Positioned(width: ...) されているため、この幅を基準にスケールを逆算。
        final double actualWidth = constraints.maxWidth;
        final int actualDurationMs =
            task.end.millisecondsSinceEpoch - task.start.millisecondsSinceEpoch;

        // （安全対策）期間がゼロ以下の場合は単純な Container を返す
        if (actualDurationMs <= 0 || actualWidth <= 0) {
          return Container(color: task.color);
        }

        final double msPerPixel = actualDurationMs / actualWidth;

        // ── 【プロジェクトイベントの特例描画】 ──
        if (task.rowId == 'prj_events_root') {
          final dateFormat = DateFormat('M/d');
          final evtName = task.name ?? '';
          final evtDateStr = '${dateFormat.format(task.start)}';

          // ピンの色を要件に応じて変更
          Color pinColor = Colors.red;
          if (evtName.contains('材料入荷')) pinColor = Colors.green;
          if (evtName.contains('立会検査')) pinColor = Colors.red;
          if (evtName.contains('第三者')) pinColor = Colors.blue;

          return OverflowBox(
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            alignment: Alignment.centerLeft, // 左端基準（開始日）
            child: FractionalTranslation(
              // 左端を中心にしつつ、縦方向はマスの中央あたりに配置（-0.2だと上が見切れるので 0.0付近に）
              translation: const Offset(-0.5, 0.0),
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('📌 $evtName (対象日: $evtDateStr)'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Tooltip(
                    message: '$evtName ($evtDateStr)',
                    child: Icon(Icons.push_pin, color: pinColor, size: 20),
                  ),
                ),
              ),
            ),
          );
        }
        // ────────────────────────────────────────

        // 【UI要件1・2】進行度のダミー値設定とテキスト生成
        // （※将来 ProcessProgress から取得した実データに差し替える）
        final double progressRatio = task.isSummary ? 0.45 : 0.60;
        final String progressText = '${(progressRatio * 100).toInt()}%';
        final String labelText = '${task.name} $progressText';

        // 共通テキストウィジェット（はみ出し回避対応）
        Widget buildLabel() {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                labelText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          );
        }

        // 【親タスク】 計画と実績の2段表示
        if (task.isSummary) {
          // モック用：ダミーの計画期間を実績期間の少し前にずらして設定
          final planStart = task.start.subtract(const Duration(days: 2));
          final planEnd = task.end.subtract(const Duration(days: 1));

          final int planStartDiffMs =
              planStart.millisecondsSinceEpoch -
              task.start.millisecondsSinceEpoch;
          final int planDurationMs =
              planEnd.millisecondsSinceEpoch - planStart.millisecondsSinceEpoch;

          final double planLeftOffset = planStartDiffMs / msPerPixel;
          final double planWidth = planDurationMs / msPerPixel;

          // 高さの計算（行の高さの 40% ずつを割り当て）
          final double barHeight = kRowHeight * 0.4;

          return Stack(
            clipBehavior: Clip.none, // 枠外に計画バーがはみ出ることを許可
            children: [
              // ── 上段：計画バー ──
              Positioned(
                top: kRowHeight * 0.05, // 少し上寄り
                left: planLeftOffset,
                width: planWidth,
                height: barHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400, // 計画は薄いグレー
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              // ── 下段：実績バー ──
              Positioned(
                top: kRowHeight * 0.55, // 少し下寄り
                left: 0,
                width: actualWidth,
                height: barHeight,
                child: Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color:
                        task.color?.withValues(alpha: 0.3) ??
                        Colors.blue.withValues(alpha: 0.3), // 背景（薄い色）
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Stack(
                    children: [
                      // 進捗塗りつぶし（濃い色）
                      Container(
                        width: actualWidth * progressRatio,
                        color: task.color,
                      ),
                      // テキストラベル
                      buildLabel(),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        // 【子タスク】 実績バーのみを行の中央に描画
        final double childBarHeight = kRowHeight * 0.5; // 少し太め
        return GestureDetector(
          onTap: () => _showDatePickerAndUpdate(context, task),
          child: Center(
            child: Container(
              height: childBarHeight,
              width: actualWidth,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color:
                    task.color?.withValues(alpha: 0.3) ??
                    Colors.blue.withValues(alpha: 0.3), // 背景（薄い同系色）
                borderRadius: BorderRadius.circular(4),
              ),
              child: Stack(
                children: [
                  // 進捗塗りつぶし（濃い色）
                  Container(
                    width: actualWidth * progressRatio,
                    color: task.color, // もともと task.color が親の色の明るい版になっている
                  ),
                  // テキストラベル
                  buildLabel(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── カレンダーでの日付更新処理 ───────────────────────────────

  Future<void> _showDatePickerAndUpdate(
    BuildContext context,
    LegacyGanttTask task,
  ) async {
    // 親タスクは再計算される側なので個別編集不可
    if (task.isSummary) return;

    final initialDateRange = DateTimeRange(start: task.start, end: task.end);

    final newDateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: initialDateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (newDateRange != null && newDateRange != initialDateRange) {
      await _onTaskUpdate(task, newDateRange.start, newDateRange.end);
    }
  }

  // ── タスクのドラッグ＆ドロップ更新処理 ───────────────────────────────

  Future<void> _onTaskUpdate(
    LegacyGanttTask task,
    DateTime newStart,
    DateTime newEnd,
  ) async {
    // 親タスクは再計算される側なので操作を無効にする
    if (task.isSummary) return;

    // ロールバック用に元のタスク状態を保持
    final originalTasks = List<LegacyGanttTask>.from(_tasks);
    final targetIndex = _tasks.indexWhere((t) => t.id == task.id);
    if (targetIndex == -1) return;

    final originalTask = _tasks[targetIndex];

    setState(() {
      // 1. UIを先行更新 (Optimistic UI Update)
      _tasks[targetIndex] = task.copyWith(start: newStart, end: newEnd);

      // 2. 親タスク（工程カテゴリ）の期間再計算
      if (task.parentId != null) {
        final parentId = task.parentId!;
        final children = _tasks.where((t) => t.parentId == parentId).toList();

        if (children.isNotEmpty) {
          DateTime? minStart;
          DateTime? maxEnd;
          for (final child in children) {
            if (minStart == null || child.start.isBefore(minStart)) {
              minStart = child.start;
            }
            if (maxEnd == null || child.end.isAfter(maxEnd)) {
              maxEnd = child.end;
            }
          }

          final parentIndex = _tasks.indexWhere((t) => t.id == parentId);
          if (parentIndex != -1) {
            _tasks[parentIndex] = _tasks[parentIndex].copyWith(
              start: minStart,
              end: maxEnd,
            );
          }
        }
      }

      // コントローラーを再初期化してビューに反映
      _ganttController.dispose();
      _initController(tasks: _buildVisibleData().tasks);
    });

    // 3. Firestore への保存処理
    try {
      // task.id から実際の tasks コレクションのドキュメントIDを取得する
      // (現在のマッピングでは id: 'parentId_childId_task' となっている)
      String rawId = task.id;
      if (rawId.endsWith('_task')) {
        rawId = rawId.substring(0, rawId.length - 5); // '_task' を除去
      }
      final parts = rawId.split('_');
      final taskId = parts.length > 1 ? parts.sublist(1).join('_') : rawId;

      // 終了日の時刻を 23:59:59 に設定する (UI上での1日の終わりを表現)
      final endOfDay = DateTime(
        newEnd.year,
        newEnd.month,
        newEnd.day,
        23,
        59,
        59,
      );

      final db = FirebaseFirestore.instance;
      await db.collection('tasks').doc(taskId).update({
        'startDate': Timestamp.fromDate(newStart),
        'endDate': Timestamp.fromDate(endOfDay),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('【Firestore保存成功】 更新タスク: ${task.name} (ドキュメントID: $taskId)');
      print('  旧: ${originalTask.start} 〜 ${originalTask.end}');
      print('  新: $newStart 〜 $endOfDay');

      if (mounted) {
        // StreamBuilder (または Provider) が Firestore の変更を検知して自動的にリビルドされるため、
        // ここでの UI の強制更新はOptimistic Updateとしてのみ機能し、整合性は保たれます。
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${task.name} の日程を保存しました。'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, st) {
      print('【Firestore保存失敗】 エラー: $e');
      print(st);

      // 失敗時はロールバック
      if (mounted) {
        setState(() {
          _tasks = originalTasks;
          _ganttController.dispose();
          _initController(tasks: _buildVisibleData().tasks);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存に失敗しました。元の期間に戻します。\n$e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final visible = _buildVisibleData();
    final visibleRows = visible.rows;
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    // isMobile を渡して左ペインのアイテム群を生成
    final leftItems = _buildLeftItems(isMobile);

    final leftPaneContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ヘッダー: チャートの axisHeight と同じ kAxisHeight で厳格に固定
        Container(
          height: kAxisHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: isMobile ? Alignment.center : Alignment.centerLeft,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              right: BorderSide(color: Colors.grey.shade300),
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: isMobile
              ? const Icon(Icons.list, color: Colors.grey)
              : ref.watch(projectsProvider).when(
                    data: (projects) {
                      if (projects.isEmpty) {
                        return const Text(
                          '工程 / 大分類',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        );
                      }

                      final selectedProjectId =
                          ref.watch(selectedProjectIdProvider) ?? widget.projectId;

                      if (!projects.any((p) => p.id == selectedProjectId)) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            ref.read(selectedProjectIdProvider.notifier).state =
                                projects.first.id;
                          }
                        });
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: projects.any((p) => p.id == selectedProjectId)
                                ? selectedProjectId
                                : projects.first.id,
                            isExpanded: true,
                            dropdownColor: Theme.of(context).colorScheme.surface,
                            icon: const Icon(Icons.arrow_drop_down),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            items: projects.map((p) {
                              return DropdownMenuItem(
                                value: p.id,
                                child: Text(
                                  '🏢 ${p.name}',
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                ref.read(selectedProjectIdProvider.notifier).state =
                                    val;
                              }
                            },
                          ),
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (_, __) => const Text(
                      'エラー',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
        ),
        // 行リスト: 常に _sharedScroll で縦スクロール同期
        Expanded(
          child: ListView.builder(
            controller: _sharedScroll,
            padding: EdgeInsets.zero,
            itemCount: leftItems.length,
            itemBuilder: (_, i) => leftItems[i],
          ),
        ),
      ],
    );

    return Column(
      children: [
        // ── メインビュー（左リスト ＋ 右チャート） ──────────────────────────────
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 左ペイン ────────────────────────────────────────────────────────
              SizedBox(
                width: isMobile ? 48.0 : kLeftPaneWidth,
                child: leftPaneContent,
              ),

              // ── 右ペイン ─────────────────────────────────────────────────────────
              // パッケージのバグ回避:
              //   (1) ヘッダー领域（kAxisHeight）に透明 GestureDetector を被せ、
              //       ドラッグを _shiftGanttRange で水平パンに変換。
              //   (2) 外側 Listener で PointerScrollEvent を横取りし、
              //       縦ホイール（dy）を水平シフトに変換。
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // 描画幅をキャッシュ（_shiftGanttRange で使用）
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _chartWidth = constraints.maxWidth;
                    });

                    return Listener(
                      // ── マウスホイール水平スクロール ────────────────────────
                      // パッケージ内部は scrollDelta.dx != 0 のときのみ水平スクロールを行う。
                      // Web では縦ホイールが scrollDelta.dy として報告されるため、
                      // 外側で横取りして _shiftGanttRange に渡す。
                      onPointerSignal: (event) {
                        if (event is PointerScrollEvent) {
                          final dy = event.scrollDelta.dy;
                          final dx = event.scrollDelta.dx;
                          if (dx != 0) {
                            // 水平ホイール（トラックパッドの横スクロールなど）: パッケージに任せる
                            return;
                          }
                          if (dy != 0) {
                            // 縦ホイールを水平パンに変換（感度係数 2.5 で調整可）
                            _shiftGanttRange(dy * 2.5);
                          }
                        }
                      },
                      child: Stack(
                        children: [
                          // ── カスタム背景グリッド（本体の背面に描画） ──
                          Positioned(
                            top: kAxisHeight,
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: AnimatedBuilder(
                              animation: _ganttController,
                              builder: (context, child) {
                                if (_chartWidth <= 0)
                                  return const SizedBox.shrink();
                                return RepaintBoundary(
                                  child: CustomPaint(
                                    painter: _CustomAxisPainter(
                                      visibleStart:
                                          _ganttController.visibleStartDate,
                                      visibleEnd:
                                          _ganttController.visibleEndDate,
                                      viewScale: widget.currentScale,
                                      chartWidth: _chartWidth,
                                      isHeader: false,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          // ── ガント本体 ──
                          LegacyGanttChartWidget(
                            controller: _ganttController,
                            visibleRows: visibleRows,
                            rowMaxStackDepth: widget.data.rowMaxStackDepth,

                            // ── 左ペインと同じ定数で厳格に固定 ───────────────
                            rowHeight: kRowHeight,
                            axisHeight: kAxisHeight,
                            showEmptyRows: true,

                            // ── 縦スクロール同期 ──────────────────────────────
                            scrollController: _sharedScroll,

                            // ── タスクの操作（ドラッグ＆ドロップ、リサイズ） ───────
                            enableDragAndDrop: false,
                            enableResize: false,
                            onTaskUpdate: _onTaskUpdate,

                            // ── 現在日（Today）ライン表示 ───────────────────
                            showNowLine: true,
                            nowLineDate: DateTime.now(),

                            // ── カスタム背景やヘッダーを描画するためデフォルトは透過 ──
                            theme: LegacyGanttTheme.fromTheme(Theme.of(context))
                                .copyWith(
                                  nowLineColor: Colors.red,
                                  gridColor: Colors.transparent, // デフォルトの罫線を消す
                                  backgroundColor:
                                      Colors.transparent, // チャート本体背景を透けさせる
                                ),

                            // ── 独自定義したヘッダー（境界線の中央に文字を配置） ──
                            timelineAxisHeaderBuilder:
                                (
                                  context,
                                  scale,
                                  visibleDomain,
                                  totalDomain,
                                  theme,
                                  width,
                                ) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white, // 重なるタスクを隠すために背景白
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                    ),
                                    child: CustomPaint(
                                      size: Size(_chartWidth, kAxisHeight),
                                      painter: _CustomAxisPainter(
                                        visibleStart:
                                            _ganttController.visibleStartDate,
                                        visibleEnd:
                                            _ganttController.visibleEndDate,
                                        viewScale: widget.currentScale,
                                        chartWidth: _chartWidth,
                                        isHeader: true,
                                      ),
                                    ),
                                  );
                                },

                            // ── タスクバーカスタマイズ（予実） ────────────────
                            taskBarBuilder: _buildCustomTaskBar,
                          ),

                          // ── 現在日（Today）テキストラベル ─────────────────
                          // チャートのスクロール位置（_ganttController の startDate/endDate）から
                          // 今日の X 座標を計算して '今日' テキストを配置する。
                          AnimatedBuilder(
                            animation: _ganttController,
                            builder: (context, child) {
                              if (_chartWidth <= 0)
                                return const SizedBox.shrink();

                              final now = DateTime.now();
                              final visibleStart =
                                  _ganttController.visibleStartDate;
                              final visibleEnd =
                                  _ganttController.visibleEndDate;
                              final duration =
                                  visibleEnd.millisecondsSinceEpoch -
                                  visibleStart.millisecondsSinceEpoch;

                              // 現在表示中の範囲に「今日」が含まれている場合のみラベルを表示
                              if (now.isAfter(visibleStart) &&
                                  now.isBefore(visibleEnd)) {
                                final diffMs =
                                    now.millisecondsSinceEpoch -
                                    visibleStart.millisecondsSinceEpoch;
                                final double msPerPixel =
                                    duration / _chartWidth;
                                final double xPosition = diffMs / msPerPixel;

                                return Positioned(
                                  top: 4, // ヘッダー内の上部
                                  left: xPosition - 12, // 中央寄せのためのオフセット
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      '今日',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),

                          // ── ヘッダー領域の透明 GestureDetector ──────────────
                          // パッケージの onPanUpdate は `dy < timeAxisHeight` の位置から
                          // 開始したドラッグをタスクヒットなしと判定し、水平パンを開始しない。
                          // 外側に透明 GestureDetector を被せることでヘッダードラッグを捕捉し、
                          // _shiftGanttRange で表示範囲を更新する。
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: kAxisHeight,
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onPanStart: (_) {}, // ドラッグ開始を受け取るだけ
                              onPanUpdate: (details) {
                                // delta.dx < 0 → 右（未来）へパン、> 0 → 左（過去）へパン
                                _shiftGanttRange(-details.delta.dx);
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── 指定されたスケール（日/週/月）に合わせた独自背景グリッド・ヘッダー描画 ────────

class _CustomAxisPainter extends CustomPainter {
  final DateTime visibleStart;
  final DateTime visibleEnd;
  final GanttViewScale viewScale;
  final double chartWidth;
  final bool isHeader;

  _CustomAxisPainter({
    required this.visibleStart,
    required this.visibleEnd,
    required this.viewScale,
    required this.chartWidth,
    required this.isHeader,
  });

  double _getX(DateTime date) {
    final startMs = visibleStart.millisecondsSinceEpoch;
    final endMs = visibleEnd.millisecondsSinceEpoch;
    final durationMs = endMs - startMs;
    if (durationMs == 0) return 0;
    return (date.millisecondsSinceEpoch - startMs) / durationMs * chartWidth;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (chartWidth <= 0 || visibleStart.isAfter(visibleEnd)) return;

    final linePaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1.0;

    final weekendPaint = Paint()..color = Colors.grey.shade300; // 休日の背景を少し濃く

    // 描画する境界線のリストを生成
    List<DateTime> boundaries = [];

    if (viewScale == GanttViewScale.day) {
      DateTime current = DateTime(
        visibleStart.year,
        visibleStart.month,
        visibleStart.day,
      );
      while (current.isBefore(visibleEnd) ||
          current.isAtSameMomentAs(visibleEnd)) {
        boundaries.add(current);
        current = current.add(const Duration(days: 1));
      }
      boundaries.add(current); // テキスト中央揃え用にはみ出た日も追加
    } else if (viewScale == GanttViewScale.week) {
      int daysToSubtract = visibleStart.weekday - 1; // 月曜始まり
      DateTime current = DateTime(
        visibleStart.year,
        visibleStart.month,
        visibleStart.day - daysToSubtract,
      );
      while (current.isBefore(visibleEnd) ||
          current.isAtSameMomentAs(visibleEnd)) {
        boundaries.add(current);
        current = current.add(const Duration(days: 7));
      }
      boundaries.add(current);
    } else if (viewScale == GanttViewScale.month) {
      DateTime current = DateTime(visibleStart.year, visibleStart.month, 1);
      while (current.isBefore(visibleEnd) ||
          current.isAtSameMomentAs(visibleEnd)) {
        boundaries.add(current);
        current = DateTime(current.year, current.month + 1, 1);
      }
      boundaries.add(current);
    }

    // ヘッダー領域に横罫線を描画 (3段に見えるように)
    if (isHeader && viewScale == GanttViewScale.day) {
      final double rowH = size.height / 3;
      canvas.drawLine(Offset(0, rowH), Offset(size.width, rowH), linePaint);
      canvas.drawLine(
        Offset(0, rowH * 2),
        Offset(size.width, rowH * 2),
        linePaint,
      );
    }

    for (int i = 0; i < boundaries.length - 1; i++) {
      final current = boundaries[i];
      final next = boundaries[i + 1];

      final x = _getX(current);
      final nextX = _getX(next);

      // 縦罫線の描画（ヘッダーと背景共通、画面内の場合のみ）
      if (x >= -1 && x <= chartWidth + 1) {
        double lineTopY = 0;
        // 「日」ビューのヘッダーの場合、1段目（月）のセルを疑似結合するため、
        // 縦線は原則2段目（rowH）から下のみ引く。ただし1日や左端の場合は全段引く。
        if (isHeader && viewScale == GanttViewScale.day) {
          if (i != 0 && current.day != 1) {
            lineTopY = size.height / 3;
          }
        }
        canvas.drawLine(Offset(x, lineTopY), Offset(x, size.height), linePaint);
      }

      if (isHeader) {
        // ヘッダーテキストの描画（マス目の中央）
        final textCenterX = (x + nextX) / 2;

        // テキスト位置が完全に画面外ならスキップ
        if (textCenterX < -50 || textCenterX > chartWidth + 50) continue;

        if (viewScale == GanttViewScale.day) {
          final weekdays = ['月', '火', '水', '木', '金', '土', '日'];
          final wd = weekdays[current.weekday - 1];

          // 土日のテキスト色判定（2・3段目用）
          Color textColor = Colors.black87;
          if (current.weekday == 6) textColor = Colors.blue;
          if (current.weekday == 7) textColor = Colors.red;

          // 月表記の重複排除: 左端の列、または1日の場合のみ表示
          final String monthText = (i == 0 || current.day == 1)
              ? '${current.month}月'
              : '';
          final String dayText = '${current.day}';
          final String wdText = wd;

          final double rowH = size.height / 3;

          // 月の描画 (上段) - 疑似セル結合として独立スタイル・左寄せ
          if (monthText.isNotEmpty) {
            _drawLeftAlignedText(
              canvas,
              monthText,
              x + 4,
              0,
              rowH,
              Colors.black87,
              FontWeight.bold,
            );
          }
          // 日の描画 (中段)
          _drawCenteredText(
            canvas,
            dayText,
            textCenterX,
            rowH,
            rowH,
            textColor,
            FontWeight.normal,
          );
          // 曜日の描画 (下段)
          _drawCenteredText(
            canvas,
            wdText,
            textCenterX,
            rowH * 2,
            rowH,
            textColor,
            FontWeight.normal,
          );
        } else {
          String text = '';
          if (viewScale == GanttViewScale.week) {
            text = '${current.month}/${current.day}〜';
          } else if (viewScale == GanttViewScale.month) {
            text = '${current.year}年 ${current.month}月';
          }
          _drawCenteredText(
            canvas,
            text,
            textCenterX,
            0,
            size.height,
            Colors.black87,
            FontWeight.normal,
          );
        }
      } else {
        // 背景の描画（土日の背景色）
        if (viewScale == GanttViewScale.day) {
          if (current.weekday == 6 || current.weekday == 7) {
            final rect = Rect.fromLTRB(x, 0, nextX, size.height);
            canvas.drawRect(rect, weekendPaint);
          }
        }
      }
    }
  }

  // 補助関数: 指定した領域の中央にテキストを描画
  void _drawCenteredText(
    Canvas canvas,
    String text,
    double textCenterX,
    double topY,
    double height,
    Color color,
    FontWeight weight,
  ) {
    if (text.isEmpty) return;
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        fontSize: 11,
        color: color,
        height: 1.2,
        fontWeight: weight,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();

    final textY = topY + (height - textPainter.height) / 2;
    textPainter.paint(
      canvas,
      Offset(textCenterX - textPainter.width / 2, textY),
    );
  }

  // 補助関数: 指定した領域の左寄せにテキストを描画（はみ出し許容）
  void _drawLeftAlignedText(
    Canvas canvas,
    String text,
    double leftX,
    double topY,
    double height,
    Color color,
    FontWeight weight,
  ) {
    if (text.isEmpty) return;
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        fontSize: 11,
        color: color,
        height: 1.2,
        fontWeight: weight,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.left,
      textDirection: ui.TextDirection.ltr,
    );
    // はみ出しを許容するため幅制限なしで layout
    textPainter.layout();

    final textY = topY + (height - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(leftX, textY));
  }

  @override
  bool shouldRepaint(covariant _CustomAxisPainter oldDelegate) {
    return oldDelegate.visibleStart != visibleStart ||
        oldDelegate.visibleEnd != visibleEnd ||
        oldDelegate.viewScale != viewScale ||
        oldDelegate.chartWidth != chartWidth ||
        oldDelegate.isHeader != isHeader;
  }
}

// ─── マスター工程表（全体タブ専用） ───────────────────────────────────────────────

class MasterGanttTab extends ConsumerWidget {
  final GanttViewScale currentScale;
  const MasterGanttTab({super.key, required this.currentScale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(masterGanttDataProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('エラー: $e')),
          data: (data) =>
              _MasterGanttWrapper(data: data, currentScale: currentScale),
        );
  }
}

class _MasterGanttWrapper extends StatefulWidget {
  final GanttChartData data;
  final GanttViewScale currentScale;
  const _MasterGanttWrapper({required this.data, required this.currentScale});

  @override
  State<_MasterGanttWrapper> createState() => _MasterGanttWrapperState();
}

class _MasterGanttWrapperState extends State<_MasterGanttWrapper> {
  late LegacyGanttController _ganttController;
  final ScrollController _sharedScroll = ScrollController();
  final Set<String> _expandedCategoryIds = {};
  double _chartWidth = 0;

  void _initController({List<LegacyGanttTask>? tasks}) {
    DateTime? minStart;
    DateTime? maxEnd;
    final currentTasks = tasks ?? widget.data.tasks;
    for (final t in currentTasks) {
      if (minStart == null || t.start.isBefore(minStart)) minStart = t.start;
      if (maxEnd == null || t.end.isAfter(maxEnd)) maxEnd = t.end;
    }
    final now = DateTime.now();
    minStart ??= now.subtract(const Duration(days: 3));
    maxEnd ??= now.add(const Duration(days: 30));

    final isMobile =
        ui.PlatformDispatcher.instance.views.first.physicalSize.width /
            ui.PlatformDispatcher.instance.views.first.devicePixelRatio <
        600;

    final initialDuration = widget.currentScale == GanttViewScale.day
        ? (isMobile ? const Duration(days: 7) : const Duration(days: 30))
        : widget.currentScale == GanttViewScale.week
        ? const Duration(days: 90)
        : const Duration(days: 365);

    _ganttController = LegacyGanttController(
      initialVisibleStartDate: minStart.subtract(const Duration(days: 3)),
      initialVisibleEndDate: minStart
          .subtract(const Duration(days: 3))
          .add(initialDuration),
      initialTasks: currentTasks,
    );
  }

  void _applyNewScale(GanttViewScale newScale) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final currentStart = _ganttController.visibleStartDate;
    final currentEnd = _ganttController.visibleEndDate;
    final centerMs =
        (currentStart.millisecondsSinceEpoch +
            currentEnd.millisecondsSinceEpoch) ~/
        2;
    final center = DateTime.fromMillisecondsSinceEpoch(centerMs);

    Duration duration;
    switch (newScale) {
      case GanttViewScale.day:
        duration = isMobile
            ? const Duration(days: 7)
            : const Duration(days: 30);
        break;
      case GanttViewScale.week:
        duration = const Duration(days: 90);
        break;
      case GanttViewScale.month:
        duration = const Duration(days: 365);
        break;
    }

    final newStart = center.subtract(Duration(days: duration.inDays ~/ 2));
    final newEnd = center.add(Duration(days: duration.inDays ~/ 2));
    _ganttController.setVisibleRange(newStart, newEnd);
  }

  ({List<LegacyGanttRow> rows, List<LegacyGanttTask> tasks})
  _buildVisibleData() {
    final rows = <LegacyGanttRow>[];
    final visibleTasks = <LegacyGanttTask>[];

    for (final cat in widget.data.categoryTrees) {
      rows.add(LegacyGanttRow(id: cat.categoryId, label: cat.categoryName));
      final parentTasks = widget.data.tasks
          .where((t) => t.rowId == cat.categoryId)
          .toList();
      visibleTasks.addAll(parentTasks);

      if (_expandedCategoryIds.contains(cat.categoryId)) {
        for (final leaf in cat.processes) {
          rows.add(LegacyGanttRow(id: leaf.rowId, label: leaf.displayName));
          final leafTasks = widget.data.tasks
              .where((t) => t.rowId == leaf.rowId)
              .toList();
          if (leafTasks.isNotEmpty) visibleTasks.addAll(leafTasks);
        }
      }
    }
    return (rows: rows, tasks: visibleTasks);
  }

  void _toggleCategory(String catId) {
    setState(() {
      _expandedCategoryIds.contains(catId)
          ? _expandedCategoryIds.remove(catId)
          : _expandedCategoryIds.add(catId);
      final v = _buildVisibleData();
      _ganttController.dispose();
      _initController(tasks: v.tasks);
    });
  }

  @override
  void initState() {
    super.initState();
    _initController(tasks: _buildVisibleData().tasks);
  }

  @override
  void didUpdateWidget(covariant _MasterGanttWrapper old) {
    super.didUpdateWidget(old);
    if (old.currentScale != widget.currentScale) {
      _applyNewScale(widget.currentScale);
    }
    if (old.data != widget.data) {
      _ganttController.dispose();
      _initController(tasks: _buildVisibleData().tasks);
    }
  }

  @override
  void dispose() {
    _sharedScroll.dispose();
    _ganttController.dispose();
    super.dispose();
  }

  void _shiftGanttRange(double dx) {
    if (_chartWidth <= 0) return;
    final totalMs =
        _ganttController.visibleEndDate.millisecondsSinceEpoch -
        _ganttController.visibleStartDate.millisecondsSinceEpoch;
    final shiftMs = (dx / _chartWidth * totalMs).round();
    _ganttController.setVisibleRange(
      _ganttController.visibleStartDate.add(Duration(milliseconds: shiftMs)),
      _ganttController.visibleEndDate.add(Duration(milliseconds: shiftMs)),
    );
  }

  List<Widget> _buildLeftItems(bool isMobile) {
    final items = <Widget>[];
    final df = DateFormat('M/d');
    final Map<String, LegacyGanttTask> taskMap = {
      for (final t in widget.data.tasks) t.id: t,
    };

    for (final cat in widget.data.categoryTrees) {
      final expanded = _expandedCategoryIds.contains(cat.categoryId);
      final parentTask = taskMap[cat.categoryId];
      final parentDateStr = parentTask != null
          ? '${df.format(parentTask.start)} ~ ${df.format(parentTask.end)}'
          : '-';

      // ── 親行（プロジェクト） ──
      items.add(
        SizedBox(
          height: kRowHeight,
          child: InkWell(
            onTap: () => _toggleCategory(cat.categoryId),
            child: Container(
              color: Colors.grey.shade200,
              padding: isMobile
                  ? EdgeInsets.zero
                  : const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    size: 18,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '🏢',
                    style: TextStyle(fontSize: 14),
                  ), // プロジェクトアイコン
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      cat.categoryName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!isMobile)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '物件期間',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          parentDateStr,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      );

      // ── 子行（工程） ──
      if (expanded) {
        for (final leaf in cat.processes) {
          final childTask = taskMap[leaf.rowId];
          final dotColor = childTask?.color ?? Colors.blue;
          items.add(
            SizedBox(
              height: kRowHeight,
              child: Container(
                color: Colors.white,
                padding: isMobile
                    ? EdgeInsets.zero
                    : const EdgeInsets.only(
                        left: 32,
                        right: 8,
                        top: 4,
                        bottom: 4,
                      ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        leaf.displayName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      }
    }
    return items;
  }

  Widget _buildCustomTaskBarMaster(LegacyGanttTask task) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final actualWidth = constraints.maxWidth;
        final actualDurationMs =
            task.end.millisecondsSinceEpoch - task.start.millisecondsSinceEpoch;
        if (actualDurationMs <= 0 || actualWidth <= 0)
          return Container(color: task.color);

        final ratio = task.rowId.contains('cat_') ? 0.45 : 0.60;
        final progressText = task.isSummary ? '' : ' ${(ratio * 100).toInt()}%';
        final labelText = '${task.name}$progressText';

        Widget buildLabel() {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                labelText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          );
        }

        if (task.isSummary) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: task.color,
              borderRadius: BorderRadius.circular(4),
            ),
            clipBehavior: Clip.hardEdge,
            child: Stack(
              children: [
                Container(
                  width: actualWidth * ratio,
                  color: Colors.black.withValues(alpha: 0.2),
                ),
                buildLabel(),
              ],
            ),
          );
        }

        return Center(
          child: Container(
            height: kRowHeight * 0.5,
            width: actualWidth,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color:
                  task.color?.withValues(alpha: 0.3) ??
                  Colors.blue.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              children: [
                Container(width: actualWidth * ratio, color: task.color),
                buildLabel(),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _buildVisibleData();
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final leftItems = _buildLeftItems(isMobile);

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: isMobile ? 48.0 : kLeftPaneWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: kAxisHeight,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: isMobile
                          ? Alignment.center
                          : Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          right: BorderSide(color: Colors.grey.shade300),
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: isMobile
                          ? const Icon(Icons.list, color: Colors.grey)
                          : const Text(
                              '物件 / 工程',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: _sharedScroll,
                        itemCount: leftItems.length,
                        itemBuilder: (_, i) => leftItems[i],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _chartWidth = constraints.maxWidth;
                    });
                    return Listener(
                      onPointerSignal: (event) {
                        if (event is PointerScrollEvent &&
                            event.scrollDelta.dy != 0 &&
                            event.scrollDelta.dx == 0) {
                          _shiftGanttRange(event.scrollDelta.dy * 2.5);
                        }
                      },
                      child: Stack(
                        children: [
                          Positioned(
                            top: kAxisHeight,
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: AnimatedBuilder(
                              animation: _ganttController,
                              builder: (context, child) {
                                if (_chartWidth <= 0)
                                  return const SizedBox.shrink();
                                return RepaintBoundary(
                                  child: CustomPaint(
                                    painter: _CustomAxisPainter(
                                      visibleStart:
                                          _ganttController.visibleStartDate,
                                      visibleEnd:
                                          _ganttController.visibleEndDate,
                                      viewScale: widget.currentScale,
                                      chartWidth: _chartWidth,
                                      isHeader: false,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          LegacyGanttChartWidget(
                            controller: _ganttController,
                            visibleRows: visible.rows,
                            rowMaxStackDepth: widget.data.rowMaxStackDepth,
                            rowHeight: kRowHeight,
                            axisHeight: kAxisHeight,
                            showEmptyRows: true,
                            scrollController: _sharedScroll,
                            enableDragAndDrop: false,
                            enableResize: false,
                            showNowLine: true,
                            nowLineDate: DateTime.now(),
                            theme: LegacyGanttTheme.fromTheme(Theme.of(context))
                                .copyWith(
                                  nowLineColor: Colors.red,
                                  gridColor: Colors.transparent,
                                  backgroundColor: Colors.transparent,
                                ),
                            timelineAxisHeaderBuilder:
                                (
                                  context,
                                  scale,
                                  visibleDomain,
                                  totalDomain,
                                  theme,
                                  width,
                                ) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                    ),
                                    child: CustomPaint(
                                      size: Size(_chartWidth, kAxisHeight),
                                      painter: _CustomAxisPainter(
                                        visibleStart:
                                            _ganttController.visibleStartDate,
                                        visibleEnd:
                                            _ganttController.visibleEndDate,
                                        viewScale: widget.currentScale,
                                        chartWidth: _chartWidth,
                                        isHeader: true,
                                      ),
                                    ),
                                  );
                                },
                            taskBarBuilder: _buildCustomTaskBarMaster,
                          ),
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: kAxisHeight,
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onPanStart: (_) {},
                              onPanUpdate: (details) {
                                _shiftGanttRange(-details.delta.dx);
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
