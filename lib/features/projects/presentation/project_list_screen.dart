import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/project_providers.dart';
import '../../products/presentation/product_list_screen.dart';
import '../../gantt/presentation/gantt_screen.dart';
import '../../../models/project.dart';

/// プロジェクト一覧画面
class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('プロジェクト一覧')),
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
      trailing: IconButton(
        icon: const Icon(Icons.bar_chart),
        tooltip: 'ガントチャート',
        onPressed: () {
          // ガントチャート画面へ
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GanttScreen(
                projectId: project.id,
                projectName: project.name,
              ),
            ),
          );
        },
      ),
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
