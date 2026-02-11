// blackboard_settings_screen.dart
// 黒板設定画面
// 黒板のタイプ（段数）を選択する画面

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// 黒板設定画面
/// 
/// 黒板のタイプ（2段、3段、4段、詳細）を選択し、
/// 選択されたタイプを呼び出し元に返します。
class BlackboardSettingsScreen extends StatefulWidget {
  /// 初期選択タイプ（nullの場合はtype2がデフォルト）
  final String? initialType;
  
  const BlackboardSettingsScreen({
    super.key,
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
  
  // PageController
  PageController? _pageController;
  
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
    
    // 初期タイプのインデックスを取得
    final initialIndex = _blackboardTypes.indexWhere((item) => item['type'] == _selectedType);
    
    // PageControllerを初期化
    _pageController = PageController(
      viewportFraction: 0.75,
      initialPage: initialIndex >= 0 ? initialIndex : 0,
    );
    
    _isLoading = false;
  }
  
  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
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
                    '左右にスワイプして黒板タイプを選択',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // === カルーセル ===
                Expanded(
                  child: _pageController == null
                      ? const Center(child: CircularProgressIndicator())
                      : PageView.builder(
                          controller: _pageController!,
                          itemCount: _blackboardTypes.length,
                          onPageChanged: (index) {
                            setState(() {
                              _selectedType = _blackboardTypes[index]['type'];
                            });
                          },
                          itemBuilder: (context, index) {
                            return AnimatedBuilder(
                              animation: _pageController!,
                              builder: (context, child) {
                                double value = 1.0;
                                if (_pageController!.position.haveDimensions) {
                                  value = _pageController!.page! - index;
                                  value = (1 - (value.abs() * 0.2)).clamp(0.8, 1.0);
                                }
                                
                                return Center(
                                  child: SizedBox(
                                    height: Curves.easeInOut.transform(value) * 500,
                                    child: child,
                                  ),
                                );
                              },
                              child: _buildCarouselItem(_blackboardTypes[index]),
                            );
                          },
                        ),
                ),
                
                const SizedBox(height: 20),
                
                // === 選択中のタイプ名 ===
                Text(
                  _blackboardTypes.firstWhere((item) => item['type'] == _selectedType)['title'],
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF007AFF),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  _blackboardTypes.firstWhere((item) => item['type'] == _selectedType)['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                
                const SizedBox(height: 40),
                
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

  /// カルーセルアイテムを構築
  Widget _buildCarouselItem(Map<String, dynamic> typeData) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _buildBlackboardPreview(typeData['type']),
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
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF00552E), // 黒板風の濃い緑色
              border: Border.all(color: Colors.white, width: 2), // 白い外枠
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                // === 上段：工事名 ===
                IntrinsicHeight(
                  child: Row(
                    children: [
                      // 見出し（左）
                      Container(
                        width: 80,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(8.0),
                        child: const Text(
                          '工事名',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const VerticalDivider(
                        color: Colors.white,
                        width: 1,
                        thickness: 1,
                      ),
                      // 内容（右）
                      Expanded(
                        child: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.all(8.0),
                          child: const Text(
                            'サンプル工事',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  color: Colors.white,
                  height: 1,
                  thickness: 1,
                ),
                
                // === 中段：工種 ===
                IntrinsicHeight(
                  child: Row(
                    children: [
                      // 見出し（左）
                      Container(
                        width: 80,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(8.0),
                        child: const Text(
                          '工　種',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const VerticalDivider(
                        color: Colors.white,
                        width: 1,
                        thickness: 1,
                      ),
                      // 内容（右）
                      Expanded(
                        child: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            _getWorkTypeName(type),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  color: Colors.white,
                  height: 1,
                  thickness: 1,
                ),
                
                // === 下段：工程・作業名 & 撮影日 ===
                Expanded(
                  child: Stack(
                    children: [
                      // 工程・作業名（罫線なし）
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 工程
                              Text(
                                _getProcessName(type),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // 作業名
                              Text(
                                _getWorkName(type),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // 撮影日（右下）
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Text(
                          '2026/02/11',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 工種名を取得
  String _getWorkTypeName(String type) {
    switch (type) {
      case 'type2':
        return '土工事 / 掘削';
      case 'type3':
        return '土工事 / 掘削 / 根切り';
      case 'type4':
        return '土工事 / 掘削 / 根切り / 床付け';
      case 'typeDetail':
        return '土工事 / 掘削（略図付き）';
      default:
        return '土工事 / 掘削';
    }
  }

  /// 工程名を取得
  String _getProcessName(String type) {
    switch (type) {
      case 'type2':
        return '工程：一次加工';
      case 'type3':
        return '工程：組立';
      case 'type4':
        return '工程：仕上げ';
      case 'typeDetail':
        return '工程：検査';
      default:
        return '工程：一次加工';
    }
  }

  /// 作業名を取得
  String _getWorkName(String type) {
    switch (type) {
      case 'type2':
        return '作業名：切断';
      case 'type3':
        return '作業名：孔あけ';
      case 'type4':
        return '作業名：塗装';
      case 'typeDetail':
        return '作業名：寸法確認';
      default:
        return '作業名：切断';
    }
  }

}
