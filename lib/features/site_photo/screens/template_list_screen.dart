import 'package:flutter/material.dart';
import 'template_editor_pane.dart';
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
  PhotoTemplate? _selectedTemplate;
  bool _isCreatingNew = false;

  Future<void> _confirmDeleteTemplate(PhotoTemplate template) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('テンプレートの削除'),
        content: Text('「${template.name.isEmpty ? "(名前なし)" : template.name}」を削除しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除する'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _firestoreService.deletePhotoTemplate(template.id);
      if (mounted) {
        if (_selectedTemplate?.id == template.id) {
          setState(() {
            _selectedTemplate = null;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('テンプレートを削除しました')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text('工程写真テンプレート管理', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Row(
        children: [
          // 左ペイン：リスト
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  // 新規作成ボタン
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedTemplate = null;
                          _isCreatingNew = true;
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('新規テンプレート作成'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  // リスト
                  Expanded(
                    child: StreamBuilder<List<PhotoTemplate>>(
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
                            child: Text('テンプレートがありません。', textAlign: TextAlign.center),
                          );
                        }

                        return ListView.separated(
                          itemCount: templates.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final template = templates[index];
                            final isSelected = _selectedTemplate?.id == template.id && !_isCreatingNew;
                            
                            return ListTile(
                              selected: isSelected,
                              selectedTileColor: Colors.blue.shade50,
                              leading: Icon(Icons.description, color: isSelected ? Colors.blue : Colors.grey),
                              title: Text(
                                template.name.isEmpty ? '(名前なし)' : template.name,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.blue : Colors.black87,
                                ),
                              ),
                              subtitle: Text('${template.category} / 項目数: ${template.items.length}'),
                              onTap: () {
                                setState(() {
                                  _selectedTemplate = template;
                                  _isCreatingNew = false;
                                });
                              },
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.grey),
                                onPressed: () => _confirmDeleteTemplate(template),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 中央の区切り線
          Container(width: 1, color: Colors.grey.shade300),

          // 右ペイン：ビルダー
          Expanded(
            flex: 2,
            child: _isCreatingNew || _selectedTemplate != null
                ? TemplateEditorPane(
                    // ValueKeyで状態をリセット
                    key: ValueKey(_isCreatingNew ? 'new_${DateTime.now().microsecondsSinceEpoch}' : _selectedTemplate!.id),
                    initialTemplateId: _isCreatingNew ? null : _selectedTemplate!.id,
                    initialTemplateName: _isCreatingNew ? null : _selectedTemplate!.name,
                    initialCategory: _isCreatingNew ? null : _selectedTemplate!.category,
                    initialTreeData: _isCreatingNew ? null : _selectedTemplate!.items,
                    onSaved: () {
                      // 保存完了時のコールバック
                      setState(() {
                        // 保存後はリストに戻るか、選択状態を解除する
                        _isCreatingNew = false;
                        _selectedTemplate = null; 
                      });
                    },
                  )
                : const Center(
                    child: Text(
                      '左のリストからテンプレートを選択するか、\n「新規テンプレート作成」を押してください',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
