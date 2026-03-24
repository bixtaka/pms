import 'package:flutter/material.dart';
import '../models/photo_template.dart';
import '../services/firestore_service.dart';

/// テンプレート項目のデータモデル（再帰的構造）
class TemplateItem {
  String id;
  String title; // 項目名
  String inputType; // 'text', 'number', 'select' 等
  List<TemplateItem> children; // 子項目のリスト

  TemplateItem({
    required this.id,
    this.title = '',
    this.inputType = 'text',
    List<TemplateItem>? children,
  }) : children = children ?? [];

  /// ディープコピーを作成するメソッド（編集用）
  TemplateItem clone() {
    return TemplateItem(
      id: this.id,
      title: this.title,
      inputType: this.inputType,
      children: this.children.map((c) => c.clone()).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'inputType': inputType,
      'children': children.map((e) => e.toMap()).toList(),
    };
  }

  factory TemplateItem.fromMap(Map<String, dynamic> map) {
    return TemplateItem(
      id: map['id'] as String,
      title: map['title'] as String,
      inputType: map['inputType'] as String,
      children: (map['children'] as List<dynamic>?)
              ?.map((e) => TemplateItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// テンプレート作成画面
class TemplateBuilderScreen extends StatefulWidget {
  final String? initialTemplateId;
  final String? initialTemplateName;
  final String? initialCategory;
  final List<TemplateItem>? initialTreeData;

  const TemplateBuilderScreen({
    Key? key,
    this.initialTemplateId,
    this.initialTemplateName,
    this.initialCategory,
    this.initialTreeData,
  }) : super(key: key);

  @override
  State<TemplateBuilderScreen> createState() => _TemplateBuilderScreenState();
}

class _TemplateBuilderScreenState extends State<TemplateBuilderScreen> {
  final TextEditingController _templateNameController = TextEditingController();
  String _selectedCategory = '工程写真';

  final List<String> _categories = ['工程写真', 'テープ合わせ', '立会検査'];

  // ツリー構造のルート項目のリスト
  final List<TemplateItem> _items = [];

  @override
  void initState() {
    super.initState();
    _templateNameController.text = widget.initialTemplateName ?? '';
    if (widget.initialCategory != null && _categories.contains(widget.initialCategory)) {
      _selectedCategory = widget.initialCategory!;
    }
    if (widget.initialTreeData != null) {
      // 編集元のデータを破壊しないようディープコピー
      _items.addAll(widget.initialTreeData!.map((e) => e.clone()).toList());
    }
  }

  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  void _addRootItem() {
    setState(() {
      _items.add(
        TemplateItem(id: DateTime.now().microsecondsSinceEpoch.toString()),
      );
    });
  }

  Future<void> _saveTemplate() async {
    if (_templateNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('テンプレート名を入力してください')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final template = PhotoTemplate(
        id: widget.initialTemplateId ?? '',
        name: _templateNameController.text,
        category: _selectedCategory,
        items: _items,
      );

      await _firestoreService.savePhotoTemplate(template);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('テンプレートを保存しました')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }



  @override
  void dispose() {
    _templateNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('テンプレート作成')),
      body: Column(
        children: [
          // 1. テンプレート基本情報エリア
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey.withOpacity(0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '基本情報',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _templateNameController,
                  decoration: const InputDecoration(
                    labelText: 'テンプレート名',
                    hintText: '例：1階配筋検査用',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'カテゴリ',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedCategory = val;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 2. 【メイン】入力フォーム階層構築エリア
          Expanded(
            child: _items.isEmpty
                ? const Center(child: Text('項目がありません。「＋新しい項目を追加」から追加してください。'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return _TemplateItemNodeWidget(
                        key: ValueKey(item.id),
                        item: item,
                        depth: 0,
                        onDelete: () {
                          setState(() {
                            _items.removeAt(index);
                          });
                        },
                        onUpdate: () {
                          setState(() {}); // 子項目の追加・削除・変更でツリー全体を再描画
                        },
                      );
                    },
                  ),
          ),
          // 新しい項目を追加（ルート）
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: OutlinedButton.icon(
              onPressed: _addRootItem,
              icon: const Icon(Icons.add),
              label: const Text('新しい項目を追加'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
          // 3. 保存エリア
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveTemplate,
                icon: _isLoading 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
                label: Text(_isLoading ? '保存中...' : 'テンプレートを保存'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ツリー構造の各ノードを描画するWidget
class _TemplateItemNodeWidget extends StatefulWidget {
  final TemplateItem item;
  final int depth;
  final VoidCallback onDelete;
  final VoidCallback onUpdate;

  const _TemplateItemNodeWidget({
    Key? key,
    required this.item,
    required this.depth,
    required this.onDelete,
    required this.onUpdate,
  }) : super(key: key);

  @override
  State<_TemplateItemNodeWidget> createState() =>
      _TemplateItemNodeWidgetState();
}

class _TemplateItemNodeWidgetState extends State<_TemplateItemNodeWidget> {
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
  }

  @override
  void didUpdateWidget(covariant _TemplateItemNodeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) {
      _titleController.text = widget.item.title;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: 24.0 * widget.depth, // 階層が深くなるごとにインデント
            top: 4.0,
            bottom: 4.0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 階層を視覚的にわかりやすくするアイコン
              if (widget.depth > 0)
                const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Icon(
                    Icons.subdirectory_arrow_right,
                    size: 20,
                    color: Colors.grey,
                  ),
                ),
              // 項目名 TextField
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: '項目名',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    widget.item.title = val;
                  },
                ),
              ),
              const SizedBox(width: 8),
              // 入力タイプ Dropdown
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: widget.item.inputType,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'text', child: Text('テキスト')),
                    DropdownMenuItem(value: 'number', child: Text('数値')),
                    DropdownMenuItem(value: 'select', child: Text('選択式')),
                    DropdownMenuItem(value: 'photo', child: Text('写真')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      widget.item.inputType = val;
                      widget.onUpdate(); // ルートまでの更新を発火
                    }
                  },
                ),
              ),
              // 子項目追加ボタン
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                tooltip: '子項目を追加',
                onPressed: () {
                  widget.item.children.add(
                    TemplateItem(
                      id: DateTime.now().microsecondsSinceEpoch.toString(),
                    ),
                  );
                  widget.onUpdate();
                },
              ),
              // 削除ボタン
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: '削除',
                onPressed: widget.onDelete,
              ),
            ],
          ),
        ),
        // 子項目の描画（再帰的）
        if (widget.item.children.isNotEmpty)
          ...widget.item.children.map((child) {
            return _TemplateItemNodeWidget(
              key: ValueKey(child.id),
              item: child,
              depth: widget.depth + 1,
              onDelete: () {
                widget.item.children.removeWhere((c) => c.id == child.id);
                widget.onUpdate();
              },
              onUpdate: widget.onUpdate,
            );
          }).toList(),
      ],
    );
  }
}
