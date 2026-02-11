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
  
  const SitePhotoCameraScreen({
    super.key,
    required this.projectName,
    required this.category,
    required this.constructionType,
    required this.photographer,
    this.blackboardType = 'type2',
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
    
    // === メインのStack構造 ===
    // Screenshot の外側に撮影ボタンを配置することで、
    // ボタンが写真に写り込まないようにします
    return Stack(
      children: [
        // === Screenshot でラップする部分（カメラ+黒板のみ） ===
        // この部分だけが画像としてキャプチャされます
        Screenshot(
          controller: _screenshotController,
          child: Stack(
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
              
              // === 電子小黒板（移動・拡大縮小可能） ===
              Positioned(
                right: 16 + _boardPosition.dx,
                bottom: 120 + _boardPosition.dy, // 撮影ボタンの上に配置
                child: GestureDetector(
                  // === スケール操作開始 ===
                  onScaleStart: (details) {
                    _baseScale = _boardScale;
                  },
                  // === スケール操作中（移動と拡大縮小） ===
                  onScaleUpdate: (details) {
                    setState(() {
                      // 移動：focalPointDelta を使用
                      // right/bottom を使用しているため、符号を反転
                      _boardPosition -= details.focalPointDelta;
                      
                      // 拡大縮小：0.5倍〜3.0倍に制限
                      _boardScale = (_baseScale * details.scale).clamp(0.5, 3.0);
                    });
                  },
                  child: Transform.scale(
                    scale: _boardScale,
                    child: _buildKokuban(),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // === 撮影ボタン（Screenshot の外側） ===
        // この部分は画像には写りませんが、画面には表示されます
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
    // 現在の日付を取得（撮影日として表示）
    final today = DateFormat('yyyy/MM/dd').format(DateTime.now());
    
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // === 黒板のタイトル ===
          const Text(
            '工事写真',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(color: Colors.white54, height: 12),
          
          // === 工事名（前の画面から受け取ったデータを表示） ===
          _KokubanRow(label: '工事名', value: widget.projectName),
          const SizedBox(height: 4),
          
          // === 撮影日（現在の日付を表示） ===
          _KokubanRow(label: '撮影日', value: today),
          const SizedBox(height: 4),
          
          // === 黒板タイプに応じた表示 ===
          ..._buildBlackboardContent(),
          
          // === 撮影者（前の画面から受け取ったデータを表示） ===
          _KokubanRow(label: '撮影者', value: widget.photographer),
        ],
      ),
    );
  }

  /// 黒板タイプに応じたコンテンツを構築
  List<Widget> _buildBlackboardContent() {
    final List<Widget> widgets = [];
    
    // 工種（カテゴリー）
    widgets.add(_KokubanRow(label: '工種', value: widget.category));
    widgets.add(const SizedBox(height: 4));
    
    // 種別（子項目）
    widgets.add(_KokubanRow(label: '種別', value: widget.constructionType));
    widgets.add(const SizedBox(height: 4));
    
    // タイプに応じた追加項目
    switch (widget.blackboardType) {
      case 'type2':
        // 2段: 工種/種別のみ（追加なし）
        break;
        
      case 'type3':
        // 3段: 追加項目1つ
        widgets.add(_KokubanRow(label: '項目3', value: '追加項目'));
        widgets.add(const SizedBox(height: 4));
        break;
        
      case 'type4':
        // 4段: 追加項目2つ
        widgets.add(_KokubanRow(label: '項目3', value: '追加項目'));
        widgets.add(const SizedBox(height: 4));
        widgets.add(_KokubanRow(label: '項目4', value: '追加項目2'));
        widgets.add(const SizedBox(height: 4));
        break;
        
      case 'typeDetail':
        // 詳細: 略図エリア
        widgets.add(const SizedBox(height: 4));
        widgets.add(const _KokubanDrawingRow(label: '略図'));
        widgets.add(const SizedBox(height: 4));
        break;
        
      default:
        // デフォルトは2段
        break;
    }
    
    return widgets;
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

/// 略図エリア（描画可能）を表示するウィジェット
class _KokubanDrawingRow extends StatefulWidget {
  final String label;

  const _KokubanDrawingRow({
    super.key,
    required this.label,
  });

  @override
  State<_KokubanDrawingRow> createState() => _KokubanDrawingRowState();
}

class _KokubanDrawingRowState extends State<_KokubanDrawingRow> {
  // 描画したストロークのリスト
  final List<DrawingStroke> _strokes = [];
  // 現在描画中のストローク
  DrawingStroke? _currentStroke;

  /// 描画をクリアする
  void _clearDrawing() {
    setState(() {
      _strokes.clear();
      _currentStroke = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ラベル部分（固定幅）
        SizedBox(
          width: 50,
          child: Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ),
        // 略図エリア
        Expanded(
          child: Container(
            height: 80, // 高さを拡大（60 → 80）
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.all(2),
            child: Stack(
              children: [
                // 描画エリア
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: GestureDetector(
                        // ジェスチャーの競合を防ぐため、このエリア内のタッチを優先
                        behavior: HitTestBehavior.opaque,
                        onPanStart: (details) {
                          setState(() {
                            // 新しいストロークを開始
                            _currentStroke = DrawingStroke(
                              points: [details.localPosition],
                            );
                          });
                        },
                        onPanUpdate: (details) {
                          setState(() {
                            // 現在のストロークに点を追加
                            if (_currentStroke != null) {
                              _currentStroke!.points.add(details.localPosition);
                            }
                          });
                        },
                        onPanEnd: (details) {
                          setState(() {
                            // ストロークを確定
                            if (_currentStroke != null && _currentStroke!.points.isNotEmpty) {
                              _strokes.add(_currentStroke!);
                              _currentStroke = null;
                            }
                          });
                        },
                        child: CustomPaint(
                          painter: DrawingPainter(
                            strokes: [..._strokes, if (_currentStroke != null) _currentStroke!],
                          ),
                          child: _strokes.isEmpty && _currentStroke == null
                              ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.brush, size: 16, color: Colors.grey),
                                      SizedBox(height: 2),
                                      Text(
                                        'タップして描画',
                                        style: TextStyle(fontSize: 8, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
                // クリアボタン
                if (_strokes.isNotEmpty || _currentStroke != null)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _clearDrawing,
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.clear,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

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
