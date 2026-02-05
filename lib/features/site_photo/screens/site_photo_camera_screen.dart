// site_photo_camera_screen.dart
// 電子小黒板付きのカメラ画面
// 工程写真を撮影するための画面

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

/// 電子小黒板付きカメラ画面
/// 
/// カメラプレビュー上に電子小黒板（工事情報）を重ねて表示し、
/// 工程写真を撮影するための画面です。
class SitePhotoCameraScreen extends StatefulWidget {
  const SitePhotoCameraScreen({super.key});

  @override
  State<SitePhotoCameraScreen> createState() => _SitePhotoCameraScreenState();
}

class _SitePhotoCameraScreenState extends State<SitePhotoCameraScreen> {
  // カメラコントローラー（カメラを操作するためのオブジェクト）
  CameraController? _cameraController;
  
  // 利用可能なカメラのリスト
  List<CameraDescription> _cameras = [];
  
  // カメラの初期化が完了したかどうか
  bool _isInitialized = false;
  
  // エラーメッセージ（カメラが使えない場合など）
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // 画面が開いたらカメラを初期化
    _initializeCamera();
  }

  /// カメラを初期化するメソッド
  Future<void> _initializeCamera() async {
    try {
      // 端末で利用可能なカメラを取得
      _cameras = await availableCameras();
      
      if (_cameras.isEmpty) {
        // カメラが見つからない場合
        setState(() {
          _errorMessage = '利用可能なカメラがありません';
        });
        return;
      }
      
      // 背面カメラを探す（なければ最初のカメラを使用）
      final backCamera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );
      
      // カメラコントローラーを作成
      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high, // 高解像度で撮影
        enableAudio: false,    // 音声は不要
      );
      
      // カメラコントローラーを初期化
      await _cameraController!.initialize();
      
      // 初期化完了
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      // エラーが発生した場合
      setState(() {
        _errorMessage = 'カメラの初期化に失敗しました: $e';
      });
    }
  }

  @override
  void dispose() {
    // 画面を閉じるときにカメラを解放
    _cameraController?.dispose();
    super.dispose();
  }

  /// 撮影ボタンが押されたときの処理
  void _onTakePicturePressed() {
    // TODO: 実際の撮影処理は後で実装
    // 今はログを出力するだけ
    debugPrint('📸 撮影ボタンが押されました！');
    debugPrint('📋 黒板情報: 工事名：〇〇ビル、撮影日：2026/02/05');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 背景を黒に設定（カメラプレビューの周りが黒くなる）
      backgroundColor: Colors.black,
      
      // アプリバー
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('工程写真撮影'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      
      // 本体部分
      body: _buildBody(),
    );
  }

  /// 画面の本体部分を構築
  Widget _buildBody() {
    // エラーがある場合はエラーメッセージを表示
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.no_photography,
              color: Colors.white54,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    // 初期化中はローディング表示
    if (!_isInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoActivityIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'カメラを起動中...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }
    
    // カメラプレビューと電子小黒板を表示
    return Stack(
      children: [
        // === カメラプレビュー ===
        // SizedBox.expandで画面いっぱいに広げる
        SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _cameraController!.value.previewSize!.height,
              height: _cameraController!.value.previewSize!.width,
              child: CameraPreview(_cameraController!),
            ),
          ),
        ),
        
        // === 電子小黒板（右下に配置） ===
        Positioned(
          right: 16,
          bottom: 120, // 撮影ボタンの上に配置
          child: _buildKokuban(),
        ),
        
        // === 撮影ボタン（画面下部中央） ===
        Positioned(
          left: 0,
          right: 0,
          bottom: 32,
          child: Center(
            child: _buildCaptureButton(),
          ),
        ),
      ],
    );
  }

  /// 電子小黒板（緑色のコンテナ）を構築
  Widget _buildKokuban() {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // 黒板風の緑色
        color: const Color(0xFF2D5016),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF8B4513), // 木枠風の茶色
          width: 4,
        ),
        // 影をつけて立体感を出す
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.5),
            blurRadius: 8,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // === 黒板のタイトル ===
          Text(
            '工事写真',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Divider(color: Colors.white54, height: 12),
          
          // === 工事名 ===
          _KokubanRow(label: '工事名', value: '〇〇ビル新築工事'),
          SizedBox(height: 4),
          
          // === 撮影日 ===
          _KokubanRow(label: '撮影日', value: '2026/02/05'),
          SizedBox(height: 4),
          
          // === 工種 ===
          _KokubanRow(label: '工種', value: '基礎工事'),
          SizedBox(height: 4),
          
          // === 撮影者 ===
          _KokubanRow(label: '撮影者', value: '山田 太郎'),
        ],
      ),
    );
  }

  /// 撮影ボタンを構築
  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: _onTakePicturePressed,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color: Colors.white,
            width: 4,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.3),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: const Icon(
            CupertinoIcons.camera_fill,
            color: Colors.black87,
            size: 32,
          ),
        ),
      ),
    );
  }
}

/// 黒板の各行（ラベルと値のペア）を表示するウィジェット
class _KokubanRow extends StatelessWidget {
  final String label;
  final String value;

  const _KokubanRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ラベル部分（固定幅）
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ),
        // 値の部分
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
