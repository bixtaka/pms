// site_photo_list_screen.dart
// 撮影リスト画面（2分割レイアウト + Firestore連携）
// 左側にリスト、右側に詳細を表示

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'site_photo_camera_screen.dart';
import 'site_photo_detail_screen.dart';
import 'site_photo_selection_screen.dart';
import '../models/photo_item.dart';
import '../services/firestore_service.dart';

/// 撮影リスト画面
/// 
/// 工事名と撮影項目のリストを表示し、
/// 各項目をタップするとカメラ画面へ遷移します。
/// 撮影完了後、リストに戻ると該当項目が「済」に更新されます。
class SitePhotoListScreen extends StatefulWidget {
  // === 前の画面から受け取るデータ ===
  final String projectName; // 工事名
  final String projectId;   // 工事ID (Firestore用)

  const SitePhotoListScreen({
    super.key,
    required this.projectName,
    required this.projectId,
  });

  @override
  State<SitePhotoListScreen> createState() => _SitePhotoListScreenState();
}

class _SitePhotoListScreenState extends State<SitePhotoListScreen> {
  // === Firestore サービス ===
  final FirestoreService _firestoreService = FirestoreService();
  
  // === 選択中の項目 ===
  PhotoItem? _selectedItem;
  
  // === 備考欄のコントローラー ===
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 背景色（Apple風のライトグレー）
      backgroundColor: const Color(0xFFF2F2F7),
      
      // アプリバー
      appBar: AppBar(
        title: Text(
          widget.projectName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // === 設定メニュー ===
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'reset') {
                await _confirmAndResetData();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red),
                    SizedBox(width: 8),
                    Text('データをリセット', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      
      // === 本体部分（2分割レイアウト + StreamBuilder） ===
      body: StreamBuilder<List<PhotoItem>>(
        stream: _firestoreService.getPhotoItems(widget.projectId),
        builder: (context, snapshot) {
          // === ローディング中 ===
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // === エラー発生 ===
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'エラーが発生しました\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            );
          }

          // === データ取得成功 ===
          final photoItems = snapshot.data ?? [];
          debugPrint('📸 取得した項目数: ${photoItems.length}');

          // === データがない場合（初期設定画面へ誘導） ===
          if (photoItems.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.list_bullet,
                      size: 80,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '撮影項目が設定されていません',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'プロジェクト開始前に必要な項目を選択してください',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SitePhotoSelectionScreen(
                              projectName: widget.projectName,
                              projectId: widget.projectId,
                              onCompleted: () => Navigator.pop(context),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(CupertinoIcons.settings),
                      label: const Text(
                        '撮影項目を設定する',
                        style: TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 20,
                        ),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Row(
            children: [
              // === 左ペイン: リスト ===
              Expanded(
                flex: 2,
                child: _buildListPane(photoItems),
              ),
              // ...省略...

              // === 中央の区切り線 ===
              Container(
                width: 1,
                color: Colors.grey[300],
              ),

              // === 右ペイン: 詳細 ===
              Expanded(
                flex: 3,
                child: _buildDetailPane(photoItems),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 左ペイン: リスト表示（カテゴリー別グループ化）
  Widget _buildListPane(List<PhotoItem> photoItems) {
    // カテゴリー別にグループ化
    final Map<String, List<PhotoItem>> groupedItems = {};
    for (final item in photoItems) {
      if (!groupedItems.containsKey(item.category)) {
        groupedItems[item.category] = [];
      }
      groupedItems[item.category]!.add(item);
    }

    return Container(
      color: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: groupedItems.length,
        itemBuilder: (context, categoryIndex) {
          final category = groupedItems.keys.elementAt(categoryIndex);
          final items = groupedItems[category]!;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === カテゴリーヘッダー ===
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: Colors.grey[200],
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.folder_fill,
                      size: 20,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const Spacer(),
                    // 完了数を表示
                    Text(
                      '${items.where((i) => i.isCompleted).length}/${items.length}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // === 子項目リスト ===
              ...items.map((item) {
                final isSelected = _selectedItem?.id == item.id;
                
                return ListTile(
                  key: ValueKey(item.id),
                  selected: isSelected,
                  selectedTileColor: Colors.blue[100], // 濃い目の色に変更
                  selectedColor: Colors.blue[900], // テキスト色も変更
                  contentPadding: const EdgeInsets.only(left: 32, right: 16),
                  leading: Icon(
                    item.isCompleted
                        ? CupertinoIcons.checkmark_circle_fill
                        : CupertinoIcons.circle,
                    color: item.isCompleted ? Colors.green : Colors.grey,
                  ),
                  title: Text(
                    item.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  trailing: Text(
                    item.isCompleted ? '済' : '未',
                    style: TextStyle(
                      color: item.isCompleted ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    debugPrint('👆 タップ: ${item.name} / ID: ${item.id}');
                    setState(() {
                      _selectedItem = item;
                      _notesController.text = item.memo ?? '';
                    });
                  },
                );
              }).toList(),
              
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }

  /// 右ペイン: 詳細表示
  Widget _buildDetailPane(List<PhotoItem> photoItems) {
    // === 未選択の場合 ===
    if (_selectedItem == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.hand_point_left,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '左側のリストから項目を選択してください',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    // === 選択中の項目が未撮影の場合 ===
    if (!_selectedItem!.isCompleted) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.camera_fill,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              // カテゴリー表示
              Text(
                _selectedItem!.category,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              // 項目名表示
              Text(
                _selectedItem!.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              
              // === 黒板タイプ選択 ===
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.square_list,
                          size: 20,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '黒板タイプ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'type2',
                          label: Text('2段'),
                          icon: Icon(CupertinoIcons.square_stack, size: 16),
                        ),
                        ButtonSegment(
                          value: 'type3',
                          label: Text('3段'),
                          icon: Icon(CupertinoIcons.square_stack_3d_up, size: 16),
                        ),
                        ButtonSegment(
                          value: 'type4',
                          label: Text('4段'),
                          icon: Icon(CupertinoIcons.square_stack_3d_down_right, size: 16),
                        ),
                        ButtonSegment(
                          value: 'typeDetail',
                          label: Text('詳細'),
                          icon: Icon(CupertinoIcons.pencil_circle, size: 16),
                        ),
                      ],
                      selected: {_selectedItem!.blackboardType},
                      onSelectionChanged: (Set<String> newSelection) {
                        _updateBlackboardType(newSelection.first);
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.selected)) {
                              return Colors.blue;
                            }
                            return Colors.white;
                          },
                        ),
                        foregroundColor: MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.selected)) {
                              return Colors.white;
                            }
                            return Colors.black87;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getBlackboardTypeDescription(_selectedItem!.blackboardType),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              ElevatedButton.icon(
                onPressed: () => _navigateToCamera(_selectedItem!),
                icon: const Icon(CupertinoIcons.camera),
                label: const Text(
                  'カメラを起動する',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 20,
                  ),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // === 選択中の項目が撮影済みの場合 ===
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // カテゴリー表示
          Text(
            _selectedItem!.category,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          // 項目名表示
          Text(
            _selectedItem!.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // 写真サムネイル
          GestureDetector(
            onTap: _showPhotoFullScreen,
            child: Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _selectedItem!.imagePath != null && _selectedItem!.imagePath!.isNotEmpty
                    ? Image.network(
                        _selectedItem!.imagePath!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.red,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  '画像の読み込みに失敗しました',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.photo,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              '画像がありません',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 備考欄
          const Text(
            '備考',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: '備考を入力してください',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              // 備考が変更されたら Firestore を更新
              _updateMemo(value);
            },
          ),
          const SizedBox(height: 24),

          // 撮り直しボタン
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _navigateToCamera(_selectedItem!),
              icon: const Icon(CupertinoIcons.camera_rotate),
              label: const Text(
                '撮り直す',
                style: TextStyle(fontSize: 16),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.blue),
                foregroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// カメラ画面または詳細画面へ遷移する
  /// 
  /// 撮影完了後、戻り値として画像パスが返ってきたら、
  /// 画像をStorageにアップロードし、URLをFirestoreに保存します。
  Future<void> _navigateToCamera(PhotoItem item) async {
    // === カメラ画面へ遷移し、戻り値を待つ ===
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => SitePhotoCameraScreen(
          projectName: widget.projectName,
          category: item.category,
          constructionType: item.name,
          photographer: 'ユーザー名',
          blackboardType: item.blackboardType,
        ),
      ),
    );
    
    // === 撮影が完了した場合（result に画像パスが入っている）、アップロード ===
    if (result != null && result.isNotEmpty) {
      try {
        debugPrint('📤 画像アップロード開始: $result');
        
        // === 画像を Firebase Storage にアップロード ===
        final imageUrl = await _firestoreService.uploadImage(widget.projectId, result);
        
        debugPrint('✅ 画像アップロード完了: $imageUrl');
        
        // === Firestore を更新 ===
        final updatedItem = item.copyWith(
          status: 'completed',
          imagePath: imageUrl,
        );
        await _firestoreService.updatePhotoItem(widget.projectId, updatedItem);
        
        // 選択中の項目を更新
        setState(() {
          _selectedItem = updatedItem;
        });
        
        debugPrint('✅ 撮影完了: ${item.name}');
      } catch (e) {
        debugPrint('❌ 画像アップロードエラー: $e');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('画像のアップロードに失敗しました: $e'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  /// 備考を更新
  Future<void> _updateMemo(String memo) async {
    if (_selectedItem == null) return;

    // Firestore を更新
    final updatedItem = _selectedItem!.copyWith(memo: memo);
    await _firestoreService.updatePhotoItem(widget.projectId, updatedItem);

    debugPrint('📝 備考更新: ${_selectedItem!.name} - $memo');
  }

  /// 黒板タイプを更新
  Future<void> _updateBlackboardType(String blackboardType) async {
    if (_selectedItem == null) return;

    // Firestore を更新
    final updatedItem = _selectedItem!.copyWith(blackboardType: blackboardType);
    await _firestoreService.updatePhotoItem(widget.projectId, updatedItem);

    // 選択中の項目を更新
    setState(() {
      _selectedItem = updatedItem;
    });

    debugPrint('🎨 黒板タイプ更新: ${_selectedItem!.name} - $blackboardType');
  }

  /// 写真を全画面表示
  void _showPhotoFullScreen() {
    if (_selectedItem == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: _selectedItem!.imagePath != null && _selectedItem!.imagePath!.isNotEmpty
                  ? Image.network(
                      _selectedItem!.imagePath!,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.white,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 128,
                                color: Colors.red,
                              ),
                              SizedBox(height: 24),
                              Text(
                                '画像の読み込みに失敗しました',
                                style: TextStyle(
                                  fontSize: 24,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.photo,
                            size: 128,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 24),
                          Text(
                            '画像がありません',
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// データリセット確認ダイアログ
  Future<void> _confirmAndResetData() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('データをリセットしますか？'),
        content: const Text(
          'すべての撮影項目と写真データが削除されます。\nこの操作は取り消せません。',
          style: TextStyle(color: Colors.red),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('リセットする'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        // 全データを削除
        await _firestoreService.resetAllData(widget.projectId);
        
        // Firestoreの反映を確実に待つ
        await Future.delayed(const Duration(milliseconds: 1000));
        
        // 選択状態をリセット
        setState(() {
          _selectedItem = null;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('データをリセットしました')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('エラーが発生しました: $e')),
          );
        }
      }
    }
  }

  /// 黒板タイプの説明を取得
  String _getBlackboardTypeDescription(String type) {
    switch (type) {
      case 'type2':
        return '工種/種別の2段表示';
      case 'type3':
        return '工種/種別/追加項目の3段表示';
      case 'type4':
        return '工種/種別/追加項目/追加項目2の4段表示';
      case 'typeDetail':
        return '工種/種別/略図の表示';
      default:
        return '工種/種別の2段表示';
    }
  }
}
