// site_photo_list_screen.dart
// 撮影リスト画面（2分割レイアウト + Firestore連携）
// 左側にリスト、右側に詳細を表示

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'site_photo_camera_screen.dart';
import 'site_photo_detail_screen.dart';
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
        // === PDFボタン (Windowsエラーのため無効化) ===
        // iPadでテストする際に有効化してください
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.picture_as_pdf),
        //     tooltip: 'PDF作成',
        //     onPressed: _onPdfButtonPressed,
        //   ),
        // ],
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

          return Row(
            children: [
              // === 左ペイン: リスト ===
              Expanded(
                flex: 2,
                child: _buildListPane(photoItems),
              ),

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

  /// 左ペイン: リスト表示
  Widget _buildListPane(List<PhotoItem> photoItems) {
    return Container(
      color: Colors.white,
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: photoItems.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = photoItems[index];
          final isSelected = _selectedItem?.id == item.id;

          return ListTile(
            selected: isSelected,
            selectedTileColor: Colors.blue[50],
            leading: Icon(
              item.isCompleted
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.circle,
              color: item.isCompleted ? Colors.green : Colors.grey,
            ),
            title: Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            trailing: Text(
              item.isCompleted ? '済' : '未',
              style: TextStyle(
                color: item.isCompleted ? Colors.green : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              setState(() {
                _selectedItem = item;
                _notesController.text = item.memo ?? '';
              });
            },
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.camera_fill,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            Text(
              _selectedItem!.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
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
      );
    }

    // === 選択中の項目が撮影済みの場合 ===
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 工程名
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
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.photo,
                      size: 64,
                      color: Colors.green,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Webダミー画像\nタップで拡大',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
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
  /// 撮影完了後、戻り値として true が返ってきたら、
  /// 該当項目の isCompleted を true に更新します。
  Future<void> _navigateToCamera(PhotoItem item) async {
    // === カメラ画面へ遷移し、戻り値を待つ ===
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => SitePhotoCameraScreen(
          projectName: widget.projectName,
          constructionType: item.name,
          photographer: 'ユーザー名',
        ),
      ),
    );
    
    // === 撮影が完了した場合（result == true）、ステータスを更新 ===
    if (result == true) {
      // Firestore を更新
      final updatedItem = item.copyWith(status: 'completed');
      await _firestoreService.updatePhotoItem(widget.projectId, updatedItem);
      
      // 選択中の項目を更新
      setState(() {
        _selectedItem = updatedItem;
      });
      
      debugPrint('✅ 撮影完了: ${item.name}');
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

  /// 写真を全画面表示
  void _showPhotoFullScreen() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: Container(
                color: Colors.green[100],
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.photo,
                        size: 128,
                        color: Colors.green,
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Webダミー画像（拡大表示）',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
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

  // === PDF機能（Windows環境でエラーのため無効化） ===
  // Windows環境では pdf パッケージのパスエラーが発生します。
  // iPad（実機）でテストする際に、以下のコメントアウトを解除してください。
  
  // /// PDFボタンが押されたときの処理
  // Future<void> _onPdfButtonPressed() async {
  //   // === 撮影済みの項目だけを抽出 ===
  //   final completedItems = _photoItems.where((item) => item.isCompleted).toList();
  //   
  //   // 撮影済み項目がない場合はエラーメッセージを表示
  //   if (completedItems.isEmpty) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('撮影済みの項目がありません'),
  //           duration: Duration(seconds: 2),
  //         ),
  //       );
  //     }
  //     return;
  //   }
  //   
  //   debugPrint('📄 PDF作成開始: ${completedItems.length}件の撮影済み項目');
  //   
  //   // === PDF を作成してプレビュー表示 ===
  //   await PdfService.createAndPreviewPdf(
  //     widget.projectName,
  //     completedItems,
  //   );
  //   
  //   debugPrint('✅ PDF作成完了');
  // }
}
