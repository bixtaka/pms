import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/projects/application/project_providers.dart';
import '../../products/presentation/product_list_screen.dart';
import '../../gantt/presentation/gantt_screen.dart';

import '../../site_photo/presentation/photo_top_screen.dart';
import '../../gantt/presentation/mock_legacy_gantt_screen.dart';
import '../domain/project.dart';
import 'project_create_screen.dart';

/// プロジェクト一覧画面
class ProjectListScreen extends ConsumerStatefulWidget {
  const ProjectListScreen({super.key});

  @override
  ConsumerState<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends ConsumerState<ProjectListScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsProvider);

    // プロジェクトがロードされた後に最初のプロジェクトを取得（新ガント・実績入力用）
    final Project? firstProject = projectsAsync.valueOrNull?.firstOrNull;
    final String? firstProjectId = firstProject?.id;

    // 画面切り替え用のWidgets
    final List<Widget> pages = [
      // インデックス0: 新ガントチャート
      firstProjectId != null
          ? MockLegacyGanttScreen(projectId: firstProjectId)
          : const Center(child: Text('プロジェクトが未取得または0件です')),

      // インデックス1: 工程写真
      const PhotoTopScreen(),

      // インデックス2: 検査入力 (製品実績入力画面)
      firstProject != null
          ? ProductResultInputPage(project: firstProject)
          : const Center(child: Text('プロジェクトが未取得または0件です')),

      // インデックス3: 旧UI (プロジェクト一覧)
      _buildOldUI(projectsAsync),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed, // 4つ以上の場合はfixedにすると見やすい
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '新ガント'),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library_outlined),
            label: '工程写真',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.fact_check), label: '検査入力'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings), // または Icons.history
            label: '工事管理',
          ),
        ],
      ),
    );
  }

  /// 以前のプロジェクト一覧画面のUIをそのまま構築する
  /// 以前のプロジェクト一覧画面のUIをそのまま構築する
  /// 以前のプロジェクト一覧画面のUIをそのまま構築する
  Widget _buildOldUI(AsyncValue<List<Project>> projectsAsync) {
    return Scaffold(
      appBar: AppBar(title: const Text('工事管理'), actions: const []),
      body: Column(
        children: [
          // 新規作成ボタン
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ProjectCreateScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('新規作成'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          // プロジェクト一覧テーブル
          Expanded(
            child: projectsAsync.when(
              data: (projects) {
                if (projects.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('プロジェクトがありません'),
                        SizedBox(height: 8),
                        Text('Firestore の projects コレクションにドキュメントを追加してください'),
                      ],
                    ),
                  );
                }

                // ここから変更箇所：LayoutBuilderとConstrainedBoxを追加し、テーブルを画面幅まで広げます
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: constraints.maxWidth, // 最小幅を画面幅（親の幅）に合わせる
                          ),
                          child: DataTable(
                            showCheckboxColumn:
                                false, // 行全体をタップ可能にするためチェックボックスを非表示
                            headingRowColor: MaterialStateProperty.all(
                              Colors.grey[200],
                            ),
                            columns: const [
                              DataColumn(label: Text('工事ID')),
                              DataColumn(label: Text('工事名称')),
                              DataColumn(label: Text('意匠設計')),
                              DataColumn(label: Text('構造設計')),
                              DataColumn(label: Text('設計監理')),
                              DataColumn(label: Text('施工')),
                              DataColumn(label: Text('商社')),
                              DataColumn(label: Text('作成日')),
                              DataColumn(label: Text('備考')),
                            ],
                            rows: projects.map((project) {
                              return DataRow(
                                // 行タップ時の遷移
                                onSelectChanged: (_) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProductListScreen(
                                        projectId: project.id,
                                        projectName: project.name,
                                      ),
                                    ),
                                  );
                                },
                                cells: [
                                  DataCell(Text(project.id)), // 工事ID
                                  DataCell(Text(project.name)), // 工事名称
                                  const DataCell(Text('-')), // 意匠設計 (DB未設定)
                                  const DataCell(Text('-')), // 構造設計 (DB未設定)
                                  const DataCell(Text('-')), // 設計監理 (DB未設定)
                                  const DataCell(Text('-')), // 施工 (DB未設定)
                                  const DataCell(Text('-')), // 商社 (DB未設定)
                                  const DataCell(Text('-')), // 作成日 (DB未設定)
                                  const DataCell(Text('-')), // 備考 (DB未設定)
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    );
                  },
                );
                // 変更箇所ここまで
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('エラー: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
