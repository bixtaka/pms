// site_photo_selection_screen.dart
// 撮影項目選択画面
// 物件開始時などの初期設定として、撮影する項目を選択する画面

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/master_data.dart';
import '../services/firestore_service.dart';

class SitePhotoSelectionScreen extends StatefulWidget {
  final String projectName;
  final String projectId;
  
  /// 完了後のコールバック（リスト画面へ遷移など）
  final VoidCallback onCompleted;

  const SitePhotoSelectionScreen({
    super.key,
    required this.projectName,
    required this.projectId,
    required this.onCompleted,
  });

  @override
  State<SitePhotoSelectionScreen> createState() => _SitePhotoSelectionScreenState();
}

class _SitePhotoSelectionScreenState extends State<SitePhotoSelectionScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  // 選択状態の管理
  // キー: カテゴリー名, 値: 選択された項目リスト
  final Map<String, List<String>> _selectedItems = {};
  
  // ローディング状態
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // デフォルトですべて選択状態にする
    _selectAllItems();
  }

  /// 全ての項目を選択
  void _selectAllItems() {
    setState(() {
      for (final category in masterWorkItems.keys) {
        _selectedItems[category] = List.from(masterWorkItems[category]!);
      }
    });
  }

  /// 全ての項目を解除
  void _deselectAllItems() {
    setState(() {
      _selectedItems.clear();
    });
  }

  /// 指定カテゴリーの全項目を選択/解除
  void _toggleCategory(String category, bool? value) {
    setState(() {
      if (value == true) {
        _selectedItems[category] = List.from(masterWorkItems[category]!);
      } else {
        _selectedItems.remove(category);
      }
    });
  }

  /// 指定項目の選択状態を切り替え
  void _toggleItem(String category, String item, bool? value) {
    setState(() {
      // カテゴリーのリストを取得（なければ作成）
      if (!_selectedItems.containsKey(category)) {
        _selectedItems[category] = [];
      }
      
      final items = _selectedItems[category]!;
      
      if (value == true) {
        if (!items.contains(item)) {
          items.add(item);
        }
      } else {
        items.remove(item);
      }
      
      // カテゴリー内の項目が空になったらカテゴリー自体を削除
      if (items.isEmpty) {
        _selectedItems.remove(category);
      }
    });
  }

  /// 保存処理
  Future<void> _saveSelection() async {
    if (_selectedItems.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _firestoreService.initializeWithSelectedItems(
        widget.projectId,
        _selectedItems,
      );
      
      // 完了コールバックを実行
      widget.onCompleted();
      
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
  Widget build(BuildContext context) {
    // 選択されている項目の総数
    final totalSelected = _selectedItems.values.fold(0, (sum, list) => sum + list.length);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text('撮影項目の選択'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _selectAllItems,
            child: const Text('すべて選択'),
          ),
          TextButton(
            onPressed: _deselectAllItems,
            child: const Text('すべて解除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // === 説明文 ===
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    children: [
                      Text(
                        'プロジェクト「${widget.projectName}」で使用する撮影項目を選択してください。',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '現在 ${totalSelected} 項目が選択されています',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // === 項目リスト ===
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: masterWorkItems.length,
                    itemBuilder: (context, index) {
                      final category = masterWorkItems.keys.elementAt(index);
                      final allItems = masterWorkItems[category]!;
                      final selectedInCategory = _selectedItems[category] ?? [];
                      
                      // カテゴリー内の全項目が選択されているか
                      final isAllSelected = selectedInCategory.length == allItems.length;
                      // カテゴリー内の一部が選択されているか
                      final isPartiallySelected = selectedInCategory.isNotEmpty && 
                                                 selectedInCategory.length < allItems.length;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        child: ExpansionTile(
                          initiallyExpanded: true,
                          leading: Checkbox(
                            value: isAllSelected ? true : (isPartiallySelected ? null : false),
                            tristate: true,
                            onChanged: (value) => _toggleCategory(category, value),
                          ),
                          title: Text(
                            category,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          subtitle: Text('${selectedInCategory.length} / ${allItems.length} 選択中'),
                          children: allItems.map((item) {
                            final isSelected = selectedInCategory.contains(item);
                            
                            return CheckboxListTile(
                              value: isSelected,
                              onChanged: (value) => _toggleItem(category, item, value),
                              title: Text(item),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: const EdgeInsets.only(left: 16, right: 16),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
                
                // === 開始ボタン ===
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: totalSelected > 0 ? _saveSelection : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue,
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '選択した項目で開始する',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
