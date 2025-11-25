import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/project_providers.dart';
import '../../products/presentation/product_list_screen.dart';
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
        data: (projects) => ListView.builder(
          itemCount: projects.length,
          itemBuilder: (_, i) => _ProjectTile(project: projects[i]),
        ),
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
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductListScreen(projectId: project.id),
          ),
        );
      },
    );
  }
}
