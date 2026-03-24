import 'package:flutter/material.dart';
import 'template_builder_screen.dart';
import '../models/photo_template.dart';
import '../services/firestore_service.dart';

/// 工程写真テンプレート管理画面（一覧画面）
class TemplateListScreen extends StatefulWidget {
  const TemplateListScreen({Key? key}) : super(key: key);

  @override
  State<TemplateListScreen> createState() => _TemplateListScreenState();
}

class _TemplateListScreenState extends State<TemplateListScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  /// テンプレート作成/編集画面へ遷移
  Future<void> _navigateToBuilder({PhotoTemplate? config}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TemplateBuilderScreen(
          initialTemplateId: config?.id,
          initialTemplateName: config?.name,
          initialCategory: config?.category,
          initialTreeData: config?.items,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('工程写真テンプレート管理'),
      ),
      body: StreamBuilder<List<PhotoTemplate>>(
        stream: _firestoreService.getPhotoTemplates(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             return Center(child: Text('エラー: ${snapshot.error}'));
          }

          final templates = snapshot.data ?? [];

          if (templates.isEmpty) {
            return const Center(
              child: Text('テンプレートがありません。\n「＋」ボタンから追加してください。', textAlign: TextAlign.center),
            );
          }

          return ListView.builder(
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.grid_view, color: Colors.blue),
                  title: Text(
                    template.name.isEmpty ? '(名前なし)' : template.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('カテゴリ: ${template.category} / 項目数: ${template.items.length}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _navigateToBuilder(config: template),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToBuilder(),
        tooltip: 'テンプレートを新規作成',
        child: const Icon(Icons.add),
      ),
    );
  }
}
