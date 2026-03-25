import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/project_providers.dart';
import '../../products/presentation/product_list_screen.dart';
import '../../gantt/presentation/gantt_screen.dart';

import '../../site_photo/screens/photo_top_screen.dart';
import '../../gantt/presentation/mock_legacy_gantt_screen.dart';
import '../../../models/project.dart';
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
            label: '旧UI',
          ),
        ],
      ),
    );
  }

  /// 以前のプロジェクト一覧画面のUIをそのまま構築する
  Widget _buildOldUI(AsyncValue<List<Project>> projectsAsync) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プロジェクト一覧 (旧UI)'),
        actions: [],
      ),
      body: projectsAsync.when(
        data: (projects) {
          if (projects.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('プロジェクトがありません'),
                  SizedBox(height: 8),
                  Text('Firestore の projects コレクションにドキュメントを追加してください'),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: projects.length,
            itemBuilder: (_, i) => _ProjectTile(project: projects[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ProjectCreateScreen(),
            ),
          );
        },
        tooltip: '新規物件登録',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  final Project project;
  const _ProjectTile({required this.project});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(project.name),
      subtitle: Text(project.areaCode),

      onTap: () {
        // 製品一覧へ
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
    );
  }
}
