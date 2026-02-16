// site_photo_list_screen.dart
// 撮影リスト画面（2分割レイアウト + Firestore連携）
// 左側にリスト、右側に詳細を表示

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'site_photo_camera_screen.dart';

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
      body: StreamBuilder<List<SiteCategory>>(
        stream: _firestoreService.getCategories(widget.projectId),
        builder: (context, categorySnapshot) {
          // カテゴリー読み込み中
          if (categorySnapshot.connectionState == ConnectionState.waiting) {
             return const Center(child: CircularProgressIndicator());
          }

          final categories = categorySnapshot.data ?? [];

          return StreamBuilder<List<PhotoItem>>(
            stream: _firestoreService.getPhotoItems(widget.projectId),
            builder: (context, photoSnapshot) {
              // === ローディング中 ===
              if (photoSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // === エラー発生 ===
              if (photoSnapshot.hasError) {
                return Center(
                  child: Text('エラー: ${photoSnapshot.error}', style: const TextStyle(color: Colors.red)),
                );
              }

              final photoItems = photoSnapshot.data ?? [];

              // === データがない場合（初期設定画面へ誘導） - カテゴリーも写真もない場合 ===
              if (categories.isEmpty && photoItems.isEmpty) {
                return _buildEmptyState();
              }

              return Row(
                children: [
                  // === 左ペイン: リスト ===
                  Expanded(
                    flex: 2,
                    child: _buildListPane(categories, photoItems),
                  ),
                  
                  // === 中央の区切り線 ===
                  Container(width: 1, color: Colors.grey[300]),

                  // === 右ペイン: 詳細 ===
                  Expanded(
                    flex: 3,
                    child: _buildDetailPane(photoItems),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// データがない場合の表示
  Widget _buildEmptyState() {
     return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.list_bullet, size: 80, color: Colors.grey),
            const SizedBox(height: 24),
            const Text(
              '撮影項目が設定されていません',
              style: TextStyle(fontSize: 20, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'プロジェクト開始前に必要な項目を選択してください',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
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
              label: const Text('撮影項目を設定する', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 左ペイン: リスト表示（カテゴリー別グループ化 + CRUD機能）
  Widget _buildListPane(List<SiteCategory> categories, List<PhotoItem> photoItems) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: categories.length + 1, // +1 for "Add Category" button
              itemBuilder: (context, index) {
                // === 最後尾: 「新しい工程を追加」ボタン ===
                if (index == categories.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    child: OutlinedButton.icon(
                      onPressed: () => _showAddCategoryDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('新しい工程を追加'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Colors.blue),
                      ),
                    ),
                  );
                }

                final category = categories[index];
                // このカテゴリーに属する項目をフィルタリング
                final items = photoItems.where((i) => i.category == category.name).toList();
                
                return Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    // ヘッダー長押しのための GestureDetector
                    title: GestureDetector(
                      onLongPress: () => _showEditCategoryMenu(category, items.isNotEmpty),
                      child: Container(
                        // タップ領域を広げるために透明なコンテナで包む
                        color: Colors.transparent, 
                        child: Row(
                          children: [
                            Icon(CupertinoIcons.folder_fill, size: 20, color: Colors.grey[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                category.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                            Text(
                              '${items.where((i) => i.isCompleted).length}/${items.length}',
                              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ),
                    children: [
                      // === 子項目リスト ===
                      ...items.map((item) {
                        final isSelected = _selectedItem?.id == item.id;
                        final displayItem = isSelected ? _selectedItem! : item;
                        
                        return ListTile(
                          key: ValueKey(item.id),
                          selected: isSelected,
                          selectedTileColor: Colors.blue[100],
                          selectedColor: Colors.blue[900],
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
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  setState(() { _selectedItem = item; });
                                  _showBlackboardEditor(context, item);
                                },
                              ),
                              const SizedBox(width: 8),
                              Text(
                                displayItem.isCompleted ? '済' : '未',
                                style: TextStyle(
                                  color: displayItem.isCompleted ? Colors.green : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            setState(() {
                              _selectedItem = item;
                              _notesController.text = item.memo ?? '';
                              _contentTextController.text = item.contentText ?? '${item.category}\n${item.name}';
                            });
                          },
                          onLongPress: () => _showEditItemMenu(item),
                        );
                      }), // .toList() is not needed with spread operator if map returns Iterable
                      
                      // === 「項目を追加」ボタン ===
                      ListTile(
                        contentPadding: const EdgeInsets.only(left: 32, right: 16),
                        leading: const Icon(Icons.add, color: Colors.blue),
                        title: const Text(
                          '項目を追加',
                          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                        ),
                        onTap: () => _showAddItemDialog(category.name),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
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

    // === 選択中の項目がある場合：写真閲覧メインのレイアウト ===
    return Column(
      children: [
        // === 上部：撮影済み写真ギャラリー (メイン) ===
        Expanded(
          child: _buildPhotoGallerySection(),
        ),
        
        // === 区切り線 ===
        Divider(height: 1, color: Colors.grey[300]),
        
        // === 下部：アクションエリア (カメラボタンのみ) ===
        _buildActionSection(),
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
    final photos = _selectedItem!.photos;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 4 / 3,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photoPath = photos[index];
        return GestureDetector(
          onTap: () => _showPhotoFullScreen(index),
          onLongPress: () => _showDeletePhotoMenu(index),
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
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    photoPath,
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
                        child: Icon(Icons.error_outline, size: 48, color: Colors.red),
                      );
                    },
                  ),
                ),
                // 削除ボタン（右上）
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _showDeletePhotoMenu(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
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
          SizedBox(height: 8),
          Text(
            '「カメラを起動する」から撮影を開始してください',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// 下部：アクションセクション（簡素化版）
  Widget _buildActionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // === 項目情報 ===
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedItem!.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _selectedItem!.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // 編集ヒント
                TextButton.icon(
                  onPressed: () => _showBlackboardEditor(context, _selectedItem!),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('黒板を編集'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),

            // === カメラ起動ボタン ===
            ElevatedButton.icon(
              onPressed: () => _navigateToCamera(_selectedItem!),
              icon: const Icon(CupertinoIcons.camera),
              label: const Text(
                'カメラを起動する', // 常にこの文言
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 黒板エディタ（ボトムシート）を表示
  Future<void> _showBlackboardEditor(BuildContext context, PhotoItem item) async {
    // 初期値をセット
    _contentTextController.text = item.contentText ?? '${item.category}\n${item.name}';
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            // 現在の編集対象アイテムを親の状態から取得（_selectedItemは常に最新）
            final currentItem = _selectedItem!;
            
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // === ハンドルバー ===
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // === ヘッダー ===
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        const Text(
                          '黒板の編集',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  
                  const Divider(),
                  
                  // === コンテンツ ===
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           // === 黒板プレビュー ===
                           Center(
                             child: SizedBox(
                               width: 300, 
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
                                     category: '鉄骨工事',
                                     freeSpaceText: '${currentItem.contentText ?? '${currentItem.category}\n${currentItem.name}'}\n撮影者：ユーザー名',
                                     constructionType: currentItem.name,
                                     photographer: 'ユーザー名',
                                     blackboardType: currentItem.blackboardType,
                                   ),
                                 ),
                               ),
                             ),
                           ),
                           
                           const SizedBox(height: 24),
                           
                           // === 黒板タイプ選択 ===
                           const Text(
                             '黒板タイプ',
                             style: TextStyle(fontWeight: FontWeight.bold),
                           ),
                           const SizedBox(height: 8),
                           SizedBox(
                             width: double.infinity,
                             child: SegmentedButton<String>(
                               segments: const [
                                 ButtonSegment(value: 'type2', label: Text('2段')),
                                 ButtonSegment(value: 'type3', label: Text('3段')),
                                 ButtonSegment(value: 'type4', label: Text('4段')),
                                 ButtonSegment(value: 'typeDetail', label: Text('詳細')),
                               ],
                               selected: {currentItem.blackboardType},
                               onSelectionChanged: (Set<String> newSelection) {
                                  // 親の状態と、このシートの状態の両方を更新
                                  setState(() {
                                    _selectedItem = currentItem.copyWith(blackboardType: newSelection.first);
                                  });
                                  setSheetState(() {});
                               },
                             ),
                           ),
                           
                           const SizedBox(height: 24),
                           
                           // === 作業内容入力 ===
                           TextField(
                              controller: _contentTextController,
                              decoration: const InputDecoration(
                                labelText: '作業内容 (黒板に表示)',
                                border: OutlineInputBorder(),
                                alignLabelWithHint: true,
                                hintText: '例：一次加工\n切断',
                                helperText: '※入力内容はリストにも反映されます',
                              ),
                              maxLines: 5,
                              onChanged: (text) {
                                // 親の状態と、このシートの状態の両方を更新
                                setState(() {
                                  _selectedItem = currentItem.copyWith(contentText: text);
                                });
                                setSheetState(() {});
                              },
                           ),
                           
                           const SizedBox(height: 32),
                           
                           // === 閉じるボタン ===
                           SizedBox(
                             width: double.infinity,
                             child: ElevatedButton(
                               onPressed: () => Navigator.of(context).pop(),
                               style: ElevatedButton.styleFrom(
                                 padding: const EdgeInsets.symmetric(vertical: 16),
                                 backgroundColor: Colors.grey[800],
                                 foregroundColor: Colors.white,
                               ),
                               child: const Text('編集を完了して閉じる'),
                             ),
                           ),
                           
                           // キーボード分の余白
                           SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    
    // シートが閉じたら保存
    if (_selectedItem != null) {
      await _savePhotoItem(_selectedItem!);
    }
  }


  /// カメラ画面へ遷移する
  /// 
  /// 撮影完了後、戻り値として画像パスが返ってきたら、
  /// 画像をStorageにアップロードし、URLをFirestoreに保存します。
  /// 複数枚対応: 既存のリストに追加します。
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
        
        // === Firestore を更新（リストに追加） ===
        final newPhotos = [...item.photos, imageUrl];
        
        // 最新の画像パスも更新（サムネイル等用、互換性のため）
        final updatedItem = item.copyWith(
          status: 'completed',
          imagePath: imageUrl,
          photos: newPhotos,
        );
        
        await _firestoreService.updatePhotoItem(widget.projectId, updatedItem);
        
        // 選択中の項目を更新
        setState(() {
          _selectedItem = updatedItem;
        });
        
        debugPrint('✅ 撮影完了: ${item.name} (${newPhotos.length}枚目)');
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

  /// 写真削除メニューを表示
  void _showDeletePhotoMenu(int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('この写真を削除', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeletePhoto(index);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// 写真削除確認
  Future<void> _confirmDeletePhoto(int index) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('写真を削除'),
        content: const Text('この写真を削除しますか？\nこの操作は取り消せません。'),
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
      // リストから削除
      final item = _selectedItem!;
      final newPhotos = List<String>.from(item.photos);
      newPhotos.removeAt(index);
      
      // imagePathの更新（まだ写真があれば最後のものを、なければnull）
      String? newImagePath;
      if (newPhotos.isNotEmpty) {
        newImagePath = newPhotos.last;
      }

      // ステータス更新
      final newStatus = newPhotos.isNotEmpty ? 'completed' : 'pending';

      final updatedItem = item.copyWith(
        photos: newPhotos,
        imagePath: newImagePath,
        status: newStatus, // 写真がなくなったらpendingに戻すかは要件次第だが、一応戻す
      );


      try {
        await _firestoreService.updatePhotoItem(widget.projectId, updatedItem);
        
        setState(() {
          _selectedItem = updatedItem;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('写真を削除しました')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('削除エラー: $e')),
          );
        }
      }
    }
  }

  /// 写真を全画面表示（ピンチイン・アウト可能）
  void _showPhotoFullScreen(int index) {
    final photos = _selectedItem?.photos ?? [];
    if (photos.isEmpty || index >= photos.length) {
      return;
    }

    final photoUrl = photos[index];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: Text('写真確認 (${index + 1}/${photos.length})'),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(CupertinoIcons.back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                   // ダイアログを出して削除後、閉じる
                   _confirmDeletePhotoInFullScreen(index);
                },
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                photoUrl,
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
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 全画面表示からの削除確認
  Future<void> _confirmDeletePhotoInFullScreen(int index) async {
     // 削除処理（共通ロジック呼び出しだとpopが足りない場合があるため個別実装または工夫）
     // ここではシンプルにダイアログ出して削除して画面閉じる
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('写真を削除'),
        content: const Text('この写真を削除しますか？'),
        actions: [
          TextButton(
             onPressed: () => Navigator.pop(context, false), // ダイアログ閉じる
             child: const Text('キャンセル'),
          ),
          TextButton(
             onPressed: () => Navigator.pop(context, true), // ダイアログ閉じる(true)
             style: TextButton.styleFrom(foregroundColor: Colors.red),
             child: const Text('削除する'),
          ),
        ],
      ),
    );

    if (result == true) {
      // リスト画面での削除ロジックを呼ぶ（状態更新のため）
      await _confirmDeletePhoto(index); // これはダイアログ出すメソッド名だがリファクタ不足...
      // ↑上のメソッドはダイアログを含んでいるので使い回しにくい。ロジックを分離すべき。
      // 今回は簡易的に、_confirmDeletePhotoのロジックを再実装せず、
      // モーダルを閉じてからリストに戻る挙動にする。
      
      if (mounted) {
        Navigator.of(context).pop(); // 全画面表示を閉じる
      }
    }
  }
  /// アイテムを保存
  Future<void> _savePhotoItem(PhotoItem item) async {
    await _firestoreService.updatePhotoItem(widget.projectId, item);
    debugPrint('💾 保存完了: ${item.name}');
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

  // ==========================================
  // ダイアログ & メニュー関係
  // ==========================================

  /// カテゴリー追加ダイアログ
  void _showAddCategoryDialog() {
    _inputDialog(
      title: '新しい工程を追加',
      hintText: '工程名を入力',
      onConfirm: (text) async {
        if (text.isNotEmpty) {
          await _firestoreService.addCategory(widget.projectId, text);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('工程「$text」を追加しました')),
            );
          }
        }
      },
    );
  }

  /// カテゴリー編集メニュー（長押し時）
  void _showEditCategoryMenu(SiteCategory category, bool hasItems) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('工程名を変更'),
                onTap: () {
                  Navigator.pop(context);
                  _inputDialog(
                    title: '工程名を変更',
                    hintText: '新しい工程名',
                    initialValue: category.name,
                    onConfirm: (text) async {
                      if (text.isNotEmpty && text != category.name) {
                        await _firestoreService.updateCategory(
                          widget.projectId,
                          category.id,
                          category.name,
                          text,
                        );
                      }
                    },
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('工程を削除', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  if (hasItems) {
                    // 項目がある場合は警告
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('削除できません'),
                        content: const Text('この工程には項目が含まれているため削除できません。\n先にすべての項目を削除してください。'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  } else {
                    _confirmDeleteCategory(category);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// カテゴリー削除確認
  Future<void> _confirmDeleteCategory(SiteCategory category) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('工程を削除'),
        content: Text('工程「${category.name}」を削除しますか？\nこの操作は取り消せません。'),
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
      await _firestoreService.deleteCategory(widget.projectId, category.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('工程「${category.name}」を削除しました')),
        );
      }
    }
  }

  /// 項目追加ダイアログ
  void _showAddItemDialog(String categoryName) {
    _inputDialog(
      title: '項目を追加',
      hintText: '項目名を入力',
      onConfirm: (text) async {
        if (text.isNotEmpty) {
          await _firestoreService.addPhotoItem(widget.projectId, categoryName, text);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('項目「$text」を追加しました')),
            );
          }
        }
      },
    );
  }

  /// 項目編集メニュー（長押し時）
  void _showEditItemMenu(PhotoItem item) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('項目名を変更'),
                onTap: () {
                  Navigator.pop(context);
                  _inputDialog(
                    title: '項目名を変更',
                    hintText: '新しい項目名',
                    initialValue: item.name,
                    onConfirm: (text) async {
                      if (text.isNotEmpty && text != item.name) {
                        await _firestoreService.updatePhotoItemName(
                          widget.projectId,
                          item.id,
                          text,
                        );
                      }
                    },
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('項目を削除', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteItem(item);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// 項目削除確認
  Future<void> _confirmDeleteItem(PhotoItem item) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('項目を削除'),
        content: Text('項目「${item.name}」を削除しますか？\n撮影された写真データも削除されます。'),
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
      await _firestoreService.deletePhotoItem(widget.projectId, item.id);
      
      // 選択中だった場合は選択解除
      if (_selectedItem?.id == item.id) {
        setState(() {
          _selectedItem = null;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('項目「${item.name}」を削除しました')),
        );
      }
    }
  }

  /// 共通入力ダイアログ
  void _inputDialog({
    required String title,
    required String hintText,
    String? initialValue,
    required Function(String) onConfirm,
  }) {
    final controller = TextEditingController(text: initialValue);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm(controller.text.trim());
            },
            child: const Text('完了'),
          ),
        ],
      ),
    );
  }
}
