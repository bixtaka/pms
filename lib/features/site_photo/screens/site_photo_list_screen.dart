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
import '../widgets/blackboard_preview.dart';

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
  
  // === 作業内容（黒板）のコントローラー ===
  final TextEditingController _contentTextController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    _contentTextController.dispose();
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
                // 編集中の内容は _selectedItem にあるため、選択中はそちらを表示用に使用する
                final displayItem = isSelected ? _selectedItem! : item;
                
                return ListTile(
                  key: ValueKey(item.id),
                  selected: isSelected,
                  selectedTileColor: Colors.blue[100], // 濃い目の色に変更
                  selectedColor: Colors.blue[900], // テキスト色も変更
                  contentPadding: const EdgeInsets.only(left: 32, right: 16),
                  leading: Icon(
                    displayItem.isCompleted
                        ? CupertinoIcons.checkmark_circle_fill
                        : CupertinoIcons.circle,
                    color: displayItem.isCompleted ? Colors.green : Colors.grey,
                  ),
                  title: Text(
                    displayItem.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  subtitle: displayItem.contentText != null && displayItem.contentText!.isNotEmpty
                      ? Text(
                          displayItem.contentText!.replaceAll('\n', ' / '),
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  trailing: Text(
                    displayItem.isCompleted ? '済' : '未',
                    style: TextStyle(
                      color: displayItem.isCompleted ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    debugPrint('👆 タップ: ${item.name} / ID: ${item.id}');
                    setState(() {
                      _selectedItem = item;
                      _notesController.text = item.memo ?? '';
                      // コンテンツテキストの初期化（未設定時はカテゴリー+項目名）
                      _contentTextController.text = item.contentText ?? '${item.category}\n${item.name}';
                      // 初期化時にcopyを持っていないと、プレビューが反映されないため、必要に応じてcopyWithしてもよいが
                      // ここではコントローラーとプレビューの同期はbuildメソッドで行うか、onChangedで行う
                      
                      // 初期値で _selectedItem を更新しておく（プレビュー用）
                      if (item.contentText == null) {
                         _selectedItem = item.copyWith(contentText: _contentTextController.text);
                      }
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

  /// 右ペイン: 詳細表示（上下2分割レイアウト）
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

    // === 選択中の項目がある場合：上下2分割レイアウト ===
    return Column(
      children: [
        // === 上部：撮影済み写真ギャラリー (60%) ===
        Expanded(
          flex: 6,
          child: _buildPhotoGallerySection(),
        ),
        
        // === 区切り線 ===
        Divider(height: 1, color: Colors.grey[300]),
        
        // === 下部：アクションエリア (40%) ===
        Expanded(
          flex: 4,
          child: _buildActionSection(),
        ),
      ],
    );
  }

  /// 上部：写真ギャラリーセクション
  Widget _buildPhotoGallerySection() {
    return Container(
      color: Colors.grey[100],
      child: _selectedItem!.imagePath != null && _selectedItem!.imagePath!.isNotEmpty
          ? _buildPhotoGrid()
          : _buildNoPhotoMessage(),
    );
  }

  /// 写真グリッド表示
  Widget _buildPhotoGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 4 / 3,
      ),
      itemCount: 1, // 現在は1枚のみ
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _showPhotoFullScreen(),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
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
                          size: 48,
                          color: Colors.red,
                        ),
                        SizedBox(height: 8),
                        Text(
                          '読み込み失敗',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  /// 写真なしメッセージ
  Widget _buildNoPhotoMessage() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.photo,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            '写真はありません',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 下部：アクションセクション
  /// 下部：アクションセクション
  /// 左右2分割レイアウト:
  /// 左側: 黒板プレビュー
  /// 右側: 操作系（黒板タイプ選択、カメラ起動）
  Widget _buildActionSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === カテゴリー・項目名表示（ヘッダー） ===
          Text(
            _selectedItem!.category,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _selectedItem!.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // === メインコンテンツ（左右分割） ===
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === 左側: 黒板プレビュー ===
                Expanded(
                  flex: 1,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: BlackboardPreview(
                          projectName: widget.projectName,
                          category: '鉄骨工事', // ユーザー要望により固定
                          // contentTextがあればそれを使用、なければ組み立てる
                          freeSpaceText: '${_selectedItem!.contentText ?? '${_selectedItem!.category}\n${_selectedItem!.name}'}\n撮影者：ユーザー名',
                          constructionType: _selectedItem!.name,
                          photographer: 'ユーザー名',
                          blackboardType: _selectedItem!.blackboardType,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 24), // スペース

                // === 右側: 操作パネル ===
                Expanded(
                  flex: 1,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 黒板タイプ選択
                        const Text(
                          '黒板タイプ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'type2',
                              label: Text('2段', style: TextStyle(fontSize: 12)),
                            ),
                            ButtonSegment(
                              value: 'type3',
                              label: Text('3段', style: TextStyle(fontSize: 12)),
                            ),
                            ButtonSegment(
                              value: 'type4',
                              label: Text('4段', style: TextStyle(fontSize: 12)),
                            ),
                            ButtonSegment(
                              value: 'typeDetail',
                              label: Text('詳細', style: TextStyle(fontSize: 12)),
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
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),

                        const SizedBox(height: 16),
                        
                        // === 作業内容（黒板表示用）入力 ===
                        TextField(
                          controller: _contentTextController,
                          decoration: const InputDecoration(
                            labelText: '作業内容 (黒板に表示)',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                            hintText: '例：一次加工\n切断',
                            isDense: true,
                          ),
                          maxLines: 3,
                          onChanged: (text) {
                            setState(() {
                              // データを更新してプレビューに即反映
                              _selectedItem = _selectedItem!.copyWith(contentText: text);
                            });
                          },
                        ),
                        
                        const SizedBox(height: 24),

                        // カメラ起動ボタン
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _navigateToCamera(_selectedItem!),
                            icon: const Icon(CupertinoIcons.camera),
                            label: Text(
                              _selectedItem!.isCompleted ? '撮り直す' : 'カメラを起動する',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                        // 備考欄（完了時のみ）
                        if (_selectedItem!.isCompleted) ...[
                          const SizedBox(height: 24),
                          const Text(
                            '備考',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: '備考を入力してください',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.all(12),
                            ),
                            onChanged: (value) {
                              _updateMemo(value);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
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
          // 編集した作業内容を渡す
          contentText: item.contentText,
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

  /// 写真を全画面表示（ピンチイン・アウト可能）
  void _showPhotoFullScreen() {
    if (_selectedItem?.imagePath == null || _selectedItem!.imagePath!.isEmpty) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text('写真確認'),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(CupertinoIcons.back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
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
                          size: 64,
                          color: Colors.red,
                        ),
                        SizedBox(height: 16),
                        Text(
                          '画像の読み込みに失敗しました',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
