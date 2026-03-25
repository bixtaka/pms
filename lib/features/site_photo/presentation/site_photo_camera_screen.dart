// site_photo_camera_screen.dart
// 電子小黒板付きのカメラ画面
// 工程写真を撮影するための画面

import 'dart:io';
import 'package:flutter/foundation.dart';  // kIsWeb を使用するため
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:gal/gal.dart';  // 写真アプリに保存するためのパッケージ
import '../widgets/blackboard_preview.dart';

/// 電子小黒板付きカメラ画面
/// 
/// カメラプレビュー上に電子小黒板（工事情報）を重ねて表示し、
/// 工程写真を撮影するための画面です。
class SitePhotoCameraScreen extends StatefulWidget {
  // === 前の画面から受け取るデータ ===
  final String projectName;      // 工事名
  final String category;         // カテゴリー（例：一次加工）
  final String constructionType; // 工種（例：切断）
  final String photographer;     // 撮影者
  final String blackboardType;   // 黒板タイプ（'type2' | 'type3'）
  
  /// 黒板の作業内容（指定がある場合はこれをフリースペースに表示）
  final String? contentText;

  const SitePhotoCameraScreen({
    super.key,
    required this.projectName,
    required this.category,
    required this.constructionType,
    required this.photographer,
    required this.blackboardType,
    this.contentText,
  });

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
  
  // === スクリーンショット用のコントローラー ===
  // このコントローラーを使って画面全体（カメラ映像+黒板）をキャプチャします
  final ScreenshotController _screenshotController = ScreenshotController();

  // === 黒板の位置とサイズの状態変数 ===
  Offset _boardPosition = const Offset(0, 0); // 初期位置（右下はPositionedで指定）
  double _boardScale = 1.0; // 拡大率
  double _baseScale = 1.0; // ピンチ操作開始時の基準スケール

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
        ResolutionPreset.high, // 高解像度（通常4:3）で撮影
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
  /// 画面全体（カメラ映像+黒板）をキャプチャして保存します
  Future<void> _onTakePicturePressed() async {
    // === Web 環境の場合はダミー処理 ===
    if (kIsWeb) {
      try {
        debugPrint('🌐 Web環境でのテスト実行中...');
        
        // 1秒待って保存したふりをする
        await Future.delayed(const Duration(seconds: 1));
        
        debugPrint('✅ 【Webテスト】保存成功（ダミー）');
        
        // リスト画面に戻り、ダミーパスを返す
        if (mounted) {
          // 現在の描画フレームが終わるのを待ってから画面を閉じる
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).pop('web_dummy_image.png');
            }
          });
        }
      } catch (e) {
        debugPrint('❌ Webテストエラー: $e');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Webテストエラー: $e')),
          );
        }
      }
      return;
    }
    
    // === モバイル環境の場合は既存の保存処理 ===
    try {
      // === 1. スクリーンショットをキャプチャ ===
      // Screenshot ウィジェットでラップした部分を画像として取得
      final imageBytes = await _screenshotController.capture();
      
      if (imageBytes == null) {
        // キャプチャに失敗した場合
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('画像のキャプチャに失敗しました')),
          );
        }
        return;
      }
      
      // === 2. 保存先のパスを取得 ===
      // アプリのドキュメントフォルダを取得
      final directory = await getApplicationDocumentsDirectory();
      
      // ファイル名を生成（例: site_photo_20260206_091830.png）
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'site_photo_$timestamp.png';
      final filePath = '${directory.path}/$fileName';
      
      // === 3. 画像をファイルに保存 ===
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);
      
      // === 4. 写真アプリ（カメラロール）に保存 ===
      await Gal.putImage(filePath);
      
      // === 5. 保存完了をログに出力 ===
      debugPrint('📸 画像を保存しました: $filePath');
      debugPrint('📱 写真アプリにも保存しました');
      
      // === 6. プレビューダイアログを表示 ===
      if (mounted) {
        _showPreviewDialog(file, filePath);
      }
    } catch (e) {
      // エラーが発生した場合
      debugPrint('❌ 画像の保存に失敗しました: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました: $e')),
        );
      }
    }
  }

  /// 撮影結果のプレビューダイアログを表示
  void _showPreviewDialog(File imageFile, String filePath) {
    // カメラ画面のcontextを保存（ダイアログのcontextと区別するため）
    final cameraContext = context;
    
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.black,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // === ダイアログのヘッダー ===
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black87,
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '撮影完了',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          // プレビューダイアログを閉じる
                          Navigator.of(dialogContext).pop();
                          // カメラ画面も閉じて、画像パスを返す
                          // 現在の描画フレームが終わるのを待ってから画面を閉じる
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (cameraContext.mounted) {
                              Navigator.of(cameraContext).pop(filePath);
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(
                        Icons.photo_library,
                        color: Colors.white70,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '写真アプリに保存しました',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // === 撮影した画像のプレビュー ===
            Container(
              constraints: const BoxConstraints(
                maxHeight: 500,
              ),
              child: Image.file(
                imageFile,
                fit: BoxFit.contain,
              ),
            ),
            
            // === ボタンエリア ===
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black87,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 閉じるボタン
                  Expanded(
                    child: CupertinoButton(
                      color: const Color(0xFF007AFF),
                      onPressed: () {
                        // プレビューダイアログを閉じる
                        Navigator.of(dialogContext).pop();
                        // カメラ画面も閉じて、撮影成功（filePath）を返す
                        Navigator.of(cameraContext).pop(filePath);
                      },
                      child: const Text('閉じる'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
    
    // === メインのコンテナ（全体レイアウト） ===
    // 横画面を前提としたレイアウト（左にプレビュー、右にコントロール）
    // 縦画面の場合は適宜Columnなどに切り替えることも可能ですが、
    // ここではリクエストに従い、黒帯付きの4:3プレビューを実装します。
    return SafeArea(
      child: Container(
        color: Colors.black,
        child: Row(
          children: [
            // === 左側: カメラプレビューエリア (4:3) ===
            Expanded(
              child: Center(
                // アスペクト比を 4:3 に強制
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Screenshot(
                    controller: _screenshotController,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          clipBehavior: Clip.hardEdge, // はみ出しをカット
                          children: [
                            // === カメラプレビュー ===
                            SizedBox.expand(
                              child: FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  // カメラのプレビューサイズに合わせて表示
                                  // ※多くの場合、ResolutionPreset.highで4:3になるが、
                                  //  念のためFittedBox.coverで4:3の枠内に収める
                                  width: _cameraController!.value.previewSize!.height,
                                  height: _cameraController!.value.previewSize!.width,
                                  child: CameraPreview(_cameraController!),
                                ),
                              ),
                            ),
                            
                            // === 電子小黒板（移動・拡大縮小可能） ===
                            Positioned(
                              left: _boardPosition.dx,
                              top: _boardPosition.dy,
                              child: GestureDetector(
                                // === スケール操作開始 ===
                                onScaleStart: (details) {
                                  _baseScale = _boardScale;
                                },
                                // === スケール操作中（移動と拡大縮小） ===
                                onScaleUpdate: (details) {
                                  setState(() {
                                    // 黒板のサイズ（固定サイズ x スケール）
                                    final blackboardWidth = 300.0 * _boardScale;
                                    final blackboardHeight = 225.0 * _boardScale;

                                    // 移動：focalPointDelta を使用して新しい位置を計算
                                    double newLeft = _boardPosition.dx + details.focalPointDelta.dx;
                                    double newTop = _boardPosition.dy + details.focalPointDelta.dy;

                                    // 移動可能範囲の最大値（4:3プレビュー領域 - 黒板サイズ）
                                    // ★ constraintsはAspectRatio(4/3)のサイズになっている
                                    double maxLeft = constraints.maxWidth - blackboardWidth;
                                    double maxTop = constraints.maxHeight - blackboardHeight;
                                    
                                    // 画面外にはみ出さないように制限 (0.0 〜 max)
                                    newLeft = newLeft.clamp(0.0, maxLeft > 0 ? maxLeft : 0.0);
                                    newTop = newTop.clamp(0.0, maxTop > 0 ? maxTop : 0.0);

                                    _boardPosition = Offset(newLeft, newTop);
                                    
                                    // 拡大縮小：0.5倍〜3.0倍に制限
                                    _boardScale = (_baseScale * details.scale).clamp(0.5, 3.0);
                                  });
                                },
                                child: Transform.scale(
                                  scale: _boardScale,
                                  alignment: Alignment.topLeft,
                                  child: SizedBox(
                                    width: 300, // 固定サイズ
                                    height: 225, // 固定サイズ
                                    child: _buildKokuban(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            
            // === 右側: コントロールエリア（黒帯） ===
            Container(
              width: 120, // 固定幅
              color: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  
                  const Spacer(), // スペーサーでシャッターボタンを下部に寄せる

                  // シャッターボタン
                  _buildCaptureButton(),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  /// 電子小黒板（共通ウィジェット使用）を構築
  Widget _buildKokuban() {
    // フリースペースのテキストを構築
    final freeSpaceLines = <String>[];
    
    // タイプに応じた追加項目
    switch (widget.blackboardType) {
      case 'type3':
        freeSpaceLines.add('項目3：追加項目');
        break;
      case 'type4':
        freeSpaceLines.add('項目3：追加項目');
        freeSpaceLines.add('項目4：追加項目2');
        break;
      default:
        break;
    }
    
    // 撮影者情報を追加
    if (widget.photographer.isNotEmpty) {
      freeSpaceLines.add('撮影者：${widget.photographer}');
    }
    
    return SizedBox(
      width: 300,
      height: 225,
      child: BlackboardPreview(
        projectName: widget.projectName,
        category: '鉄骨工事', // ユーザー要望により固定
        constructionType: widget.constructionType,
        photographer: widget.photographer,
        blackboardType: widget.blackboardType,
        // Category(Process) + Name(Type) + Other free space lines
        // contentTextが指定されている場合はそれを優先使用（撮影者名は自動付与）
        freeSpaceText: widget.contentText != null 
            ? '${widget.contentText}\n撮影者：${widget.photographer}'
            : '${widget.category}\n${widget.constructionType}\n${freeSpaceLines.join('\n')}',
        showDate: true,
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
/// ※ DrawingStroke/DrawingPainter は略図機能で使用するため残置

/// 描画ストローク（1本の線）を表すクラス
class DrawingStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  DrawingStroke({
    required this.points,
    this.color = Colors.black,
    this.strokeWidth = 2.0,
  });
}

/// 描画内容をキャンバスに描画するPainter
class DrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;

  DrawingPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      // 線を描画
      for (int i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) {
    return oldDelegate.strokes != strokes;
  }
}
