// site_photo_selection_screen.dart
// 撮影項目選択画面
// 物件開始時などの初期設定として、撮影する項目を選択する画面

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/master_data.dart';
import '../services/firestore_service.dart';
import 'blackboard_settings_screen.dart';

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
  
  // 各項目の黒板タイプ管理
  // 第1キー: カテゴリー名, 第2キー: 項目名, 値: 黒板タイプ
  final Map<String, Map<String, String>> _blackboardTypes = {};
  
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
        
        // 黒板タイプも初期化（デフォルトはtype2）
        if (!_blackboardTypes.containsKey(category)) {
          _blackboardTypes[category] = {};
        }
        for (final item in masterWorkItems[category]!) {
          _blackboardTypes[category]![item] = 'type2';
        }
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
        
        // 黒板タイプも初期化（デフォルトはtype2）
        if (!_blackboardTypes.containsKey(category)) {
          _blackboardTypes[category] = {};
        }
        if (!_blackboardTypes[category]!.containsKey(item)) {
          _blackboardTypes[category]![item] = 'type2';
        }
      } else {
        items.remove(item);
        // 選択解除時は黒板タイプも削除
        _blackboardTypes[category]?.remove(item);
      }
      
      // カテゴリー内の項目が空になったらカテゴリー自体を削除
      if (items.isEmpty) {
        _selectedItems.remove(category);
        _blackboardTypes.remove(category);
      }
    });
  }

  /// 指定項目の黒板タイプを取得
  String _getBlackboardType(String category, String item) {
    return _blackboardTypes[category]?[item] ?? 'type2';
  }

  /// 黒板タイプのラベルを取得
  String _getBlackboardTypeLabel(String type) {
    switch (type) {
      case 'type2':
        return '2段';
      case 'type3':
        return '3段';
      case 'type4':
        return '4段';
      case 'typeDetail':
        return '詳細';
      default:
        return '2段';
    }
  }

  /// 黒板設定画面を開く
  Future<void> _openBlackboardSettings(String category, String item) async {
    final currentType = _getBlackboardType(category, item);
    
    final selectedType = await Navigator.of(context).push<String>(
      CupertinoPageRoute(
        builder: (context) => BlackboardSettingsScreen(
          initialType: currentType,
        ),
      ),
    );
    
    // 選択されたタイプで更新
    if (selectedType != null && mounted) {
      setState(() {
        if (!_blackboardTypes.containsKey(category)) {
          _blackboardTypes[category] = {};
        }
        _blackboardTypes[category]![item] = selectedType;
      });
    }
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
        blackboardTypes: _blackboardTypes,
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
                            final blackboardType = _getBlackboardType(category, item);
                            final typeLabel = _getBlackboardTypeLabel(blackboardType);
                            
                            return ListTile(
                              contentPadding: const EdgeInsets.only(left: 16, right: 8),
                              leading: Checkbox(
                                value: isSelected,
                                onChanged: (value) => _toggleItem(category, item, value),
                              ),
                              title: Text(item),
                              // 黒板タイプ設定ボタン
                              trailing: isSelected
                                  ? TextButton.icon(
                                      onPressed: () => _openBlackboardSettings(category, item),
                                      icon: const Icon(
                                        CupertinoIcons.rectangle_grid_2x2,
                                        size: 18,
                                      ),
                                      label: Text(
                                        typeLabel,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        foregroundColor: const Color(0xFF007AFF),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        backgroundColor: const Color(0xFF007AFF).withOpacity(0.1),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    )
                                  : null,
                              onTap: () => _toggleItem(category, item, !isSelected),
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
