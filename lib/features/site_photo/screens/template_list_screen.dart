import 'package:flutter/material.dart';
import 'template_builder_screen.dart';

/// テンプレートの設定データを保持するモッククラス
class TemplateConfig {
  final String id;
  String name;
  String category;
  List<TemplateItem> treeData;

  TemplateConfig({
    required this.id,
    required this.name,
    required this.category,
    required this.treeData,
  });
}

/// 工程写真テンプレート管理画面（一覧画面）
class TemplateListScreen extends StatefulWidget {
  const TemplateListScreen({Key? key}) : super(key: key);

  @override
  State<TemplateListScreen> createState() => _TemplateListScreenState();
}

class _TemplateListScreenState extends State<TemplateListScreen> {
  // メモリ上で管理するテスト用ダミーデータ
  final List<TemplateConfig> _templates = [
    TemplateConfig(
      id: 'mock_1',
      name: 'コラム',
      category: '工程写真',
      treeData: [
        TemplateItem(
          id: 'item_1',
          title: '溶接部',
          inputType: 'text',
          children: [
            TemplateItem(
              id: 'item_1_1',
              title: '外観写真',
              inputType: 'photo',
            ),
          ],
        ),
      ],
    ),
  ];

  /// テンプレート作成/編集画面へ遷移
  Future<void> _navigateToBuilder({TemplateConfig? config}) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TemplateBuilderScreen(
          initialTemplateName: config?.name,
          initialCategory: config?.category,
          initialTreeData: config?.treeData,
        ),
      ),
    );

    // 戻り値がある場合はデータを更新・追加する
    if (result != null && result is Map<String, dynamic>) {
      final name = result['templateName'] as String;
      final category = result['category'] as String;
      final treeData = result['treeData'] as List<TemplateItem>;

      setState(() {
        if (config != null) {
          // 既存のテンプレートを上書き
          config.name = name;
          config.category = category;
          config.treeData = treeData;
        } else {
          // 新規追加
          _templates.add(
            TemplateConfig(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              name: name,
              category: category,
              treeData: treeData,
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('工程写真テンプレート管理'),
      ),
      body: _templates.isEmpty
          ? const Center(
              child: Text('テンプレートがありません。\n「＋」ボタンから追加してください。', textAlign: TextAlign.center),
            )
          : ListView.builder(
              itemCount: _templates.length,
              itemBuilder: (context, index) {
                final template = _templates[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.grid_view, color: Colors.blue),
                    title: Text(
                      template.name.isEmpty ? '(名前なし)' : template.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('カテゴリ: ${template.category} / 項目数: ${template.treeData.length}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _navigateToBuilder(config: template),
                  ),
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
