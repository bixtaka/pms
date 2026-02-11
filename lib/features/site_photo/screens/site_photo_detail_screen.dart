// site_photo_detail_screen.dart
// 撮影詳細画面
// 撮影済みの写真を表示し、備考を入力できる画面

import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'site_photo_camera_screen.dart';

/// 撮影詳細画面
/// 
/// 撮影済みの写真を表示し、備考を入力できます。
/// 「撮り直す」ボタンでカメラ画面へ遷移できます。
class SitePhotoDetailScreen extends StatefulWidget {
  // === 前の画面から受け取るデータ ===
  final String projectName;      // 工事名
  final String constructionType; // 工種
  final String photographer;     // 撮影者
  final String? imagePath;       // 画像パス（モバイルのみ）

  const SitePhotoDetailScreen({
    super.key,
    required this.projectName,
    required this.constructionType,
    required this.photographer,
    this.imagePath,
  });

  @override
  State<SitePhotoDetailScreen> createState() => _SitePhotoDetailScreenState();
}

class _SitePhotoDetailScreenState extends State<SitePhotoDetailScreen> {
  // 備考欄のコントローラー
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
        backgroundColor: const Color(0xFFF2F2F7),
        title: Text(
          widget.constructionType,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      
      // 本体部分
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // === 写真表示エリア ===
              _buildPhotoArea(),
              
              const SizedBox(height: 24),
              
              // === 備考欄 ===
              _buildNotesSection(),
              
              const SizedBox(height: 24),
              
              // === 撮り直すボタン ===
              _buildRetakeButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// 写真表示エリアを構築
  Widget _buildPhotoArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: kIsWeb
              ? _buildDummyImage()
              : _buildActualImage(),
        ),
      ),
    );
  }

  /// ダミー画像を構築（Web用）
  Widget _buildDummyImage() {
    return Container(
      color: const Color(0xFF2D5016), // 黒板風の緑色
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.photo,
            color: Colors.white54,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            '【Webテスト】\n撮影済み画像',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.constructionType,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// 実際の画像を構築（モバイル用）
  Widget _buildActualImage() {
    if (widget.imagePath == null) {
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: Icon(
            Icons.image_not_supported,
            color: Colors.grey,
            size: 64,
          ),
        ),
      );
    }

    // TODO: 実機では File(widget.imagePath!) を使って画像を表示
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Text('画像表示（実機対応予定）'),
      ),
    );
  }

  /// 備考欄セクションを構築
  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              CupertinoIcons.doc_text,
              color: Color(0xFF007AFF),
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              '備考',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFE5E5EA),
            ),
          ),
          child: TextField(
            controller: _notesController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: '写真に関するメモを入力してください',
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  /// 撮り直すボタンを構築
  Widget _buildRetakeButton() {
    return CupertinoButton(
      color: const Color(0xFF007AFF),
      borderRadius: BorderRadius.circular(14),
      onPressed: _onRetakePressed,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.camera_fill),
          SizedBox(width: 8),
          Text(
            '撮り直す',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 撮り直すボタンが押されたときの処理
  Future<void> _onRetakePressed() async {
    // カメラ画面へ遷移
    final result = await Navigator.of(context).push<bool>(
      CupertinoPageRoute(
        builder: (context) => SitePhotoCameraScreen(
          projectName: widget.projectName,
          category: '工種',  // デフォルト値（このファイルは現在未使用）
          constructionType: widget.constructionType,
          photographer: widget.photographer,
          blackboardType: 'type2',  // デフォルト値
        ),
      ),
    );

    // 撮影が完了した場合、詳細画面を閉じてリスト画面に戻る
    if (result == true && mounted) {
      Navigator.of(context).pop(true); // リスト画面に「更新あり」を返す
    }
  }
}
