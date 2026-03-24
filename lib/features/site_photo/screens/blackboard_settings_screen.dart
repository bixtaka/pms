// blackboard_settings_screen.dart
// 黒板設定画面
// 黒板のタイプ（段数）を選択する画面

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../widgets/blackboard_preview.dart';

/// 黒板設定画面
/// 
/// 黒板のタイプ（2段、3段、4段、詳細）を選択し、
/// 選択されたタイプを呼び出し元に返します。
class BlackboardSettingsScreen extends StatefulWidget {
  /// 工事名（プレビュー表示用）
  final String projectName;

  /// 初期選択タイプ（nullの場合はtype2がデフォルト）
  final String? initialType;
  
  const BlackboardSettingsScreen({
    super.key,
    required this.projectName,
    this.initialType,
  });

  @override
  State<BlackboardSettingsScreen> createState() => _BlackboardSettingsScreenState();
}

class _BlackboardSettingsScreenState extends State<BlackboardSettingsScreen> {
  // 選択中の黒板タイプ
  String _selectedType = 'type2';
  
  // ローディング状態
  bool _isLoading = true;
  
  // 黒板タイプのリスト
  final List<Map<String, dynamic>> _blackboardTypes = [
    {
      'type': 'type2',
      'title': '2段',
      'description': '工種/種別の2段表示',
    },
    {
      'type': 'type3',
      'title': '3段',
      'description': '工種/種別/追加項目の3段表示',
    },
    {
      'type': 'type4',
      'title': '4段',
      'description': '工種/種別/追加項目/追加項目2の4段表示',
    },
    {
      'type': 'typeDetail',
      'title': '詳細（略図付き）',
      'description': '工種/種別/略図の表示',
    },
  ];

  @override
  void initState() {
    super.initState();
    
    // 初期タイプを設定（nullの場合はtype2）
    _selectedType = widget.initialType ?? 'type2';
    
    _isLoading = false;
  }

  /// 選択を確定して前の画面に戻る
  void _confirmSelection() {
    // 選択されたタイプを返して画面を閉じる
    Navigator.of(context).pop(_selectedType);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F7),
        title: const Text(
          '黒板設定',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 20),
                
                // === 説明テキスト ===
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    '黒板タイプを選択してください',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // === グリッド表示 ===
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.5,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _blackboardTypes.length,
                      itemBuilder: (context, index) {
                        final typeData = _blackboardTypes[index];
                        final isSelected = _selectedType == typeData['type'];
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedType = typeData['type'];
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF007AFF) : Colors.grey[300]!,
                                width: isSelected ? 3 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF007AFF).withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              children: [
                                // タイトル
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF007AFF) : Colors.grey[100],
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(11),
                                      topRight: Radius.circular(11),
                                    ),
                                  ),
                                  child: Text(
                                    typeData['title'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ),
                                // プレビュー
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: _buildBlackboardPreview(typeData['type']),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                // === 選択ボタン ===
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: CupertinoButton(
                    color: const Color(0xFF007AFF),
                    borderRadius: BorderRadius.circular(14),
                    onPressed: _confirmSelection,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.checkmark_circle_fill),
                        SizedBox(width: 8),
                        Text(
                          '選択',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  /// 黒板プレビューを構築
  Widget _buildBlackboardPreview(String type) {
    
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 400, // iPad対策：最大幅を制限
        ),
        child: AspectRatio(
          aspectRatio: 4 / 3, // 一般的な工事黒板の縦横比
          child: BlackboardPreview(
            projectName: widget.projectName,
            category: '鉄骨工事', // ユーザー要望により固定
            // Process + Type
            freeSpaceText: '${_getProcessName(type)}\n${_getWorkName(type)}\n撮影者：ユーザー名',
            constructionType: _getWorkName(type),
            photographer: 'ユーザー名',
            blackboardType: type,
            showDate: true,
            date: DateTime(2026, 2, 11), // サンプル画像の通り
          ),
        ),
      ),
    );
  }



  /// 工程名を取得
  String _getProcessName(String type) {
    switch (type) {
      case 'type2':
        return '一次加工';
      case 'type3':
        return '組立';
      case 'type4':
        return '仕上げ';
      case 'typeDetail':
        return '検査';
      default:
        return '一次加工';
    }
  }

  /// 作業名を取得
  String _getWorkName(String type) {
    switch (type) {
      case 'type2':
        return '切断';
      case 'type3':
        return '孔あけ';
      case 'type4':
        return '塗装';
      case 'typeDetail':
        return '寸法確認';
      default:
        return '切断';
    }
  }

}

/// 黒板プレビュー用のヘルパーウィジェット
