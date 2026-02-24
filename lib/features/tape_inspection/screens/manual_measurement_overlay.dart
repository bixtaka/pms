import 'dart:io';
import 'package:flutter/material.dart';

class ManualMeasurementOverlay extends StatefulWidget {
  final String imagePath;

  const ManualMeasurementOverlay({super.key, required this.imagePath});

  @override
  State<ManualMeasurementOverlay> createState() => _ManualMeasurementOverlayState();
}

class _ManualMeasurementOverlayState extends State<ManualMeasurementOverlay> {
  double _lineA = 0; // 赤：基準線
  double _lineB = 0; // 青：スケール線
  double _lineC = 0; // 緑：測定線
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final width = MediaQuery.of(context).size.width;
      // 初期位置を画面サイズに合わせて配置
      _lineA = width * 0.4;
      _lineB = width * 0.6;
      _lineC = width * 0.5;
      _isInitialized = true;
    }
  }

  Widget _buildImage(String path) {
    if (path.startsWith('http') || path.startsWith('blob:')) {
      return Image.network(path, fit: BoxFit.contain, width: double.infinity, height: double.infinity);
    } else {
      return Image.file(File(path), fit: BoxFit.contain, width: double.infinity, height: double.infinity);
    }
  }

  @override
  Widget build(BuildContext context) {
    // PPM: B - A の絶対値
    final double ppm = (_lineB - _lineA).abs();
    // ピクセル差分: A - C (CがAより左にあればプラス、右にあればマイナス)
    final double pixelDiff = _lineA - _lineC;
    // 誤差(mm): ピクセル差分 / PPM
    final double errorMm = ppm > 0 ? pixelDiff / ppm : 0.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // 上部：画像プレビューと操作線
            Expanded(
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 10.0,
                clipBehavior: Clip.none,
                child: Stack(
                  children: [
                    // 背景画像
                    Positioned.fill(
                      child: _buildImage(widget.imagePath),
                    ),

                    // 3本のドラッグ可能な設定線
                    _buildDraggableLine(
                      color: Colors.red,
                      xPos: _lineA,
                      label: 'A: 基準線',
                      onDrag: (dx) => setState(() => _lineA += dx),
                    ),
                    _buildDraggableLine(
                      color: Colors.blue,
                      xPos: _lineB,
                      label: 'B: 1mm隣',
                      onDrag: (dx) => setState(() => _lineB += dx),
                    ),
                    _buildDraggableLine(
                      color: Colors.green,
                      xPos: _lineC,
                      label: 'C: 測定線',
                      onDrag: (dx) => setState(() => _lineC += dx),
                    ),
                  ],
                ),
              ),
            ),

            // 下部：計算結果と操作パネル
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('キャリブレーション（誤差の手動計算）', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoText('PPM (1mm分)', '${ppm.toStringAsFixed(1)} px'),
                      _buildInfoText('ピクセル差分', '${pixelDiff.toStringAsFixed(1)} px'),
                      _buildInfoText(
                        '誤差 (mm)', 
                        '${errorMm > 0 ? '+' : ''}${errorMm.toStringAsFixed(2)} mm', 
                        isHighlight: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        // 0.1mm 単位にフォーマット（+0.5, -1.2, 0.0 など）
                        String formatted = errorMm.toStringAsFixed(1);
                        // "+0.0" や "-0.0" を "0.0" に統一
                        if (errorMm == 0 || formatted == '0.0' || formatted == '-0.0') {
                          formatted = '0.0';
                        } else if (errorMm > 0) {
                          formatted = '+$formatted';
                        }
                        Navigator.of(context).pop(formatted);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('この誤差で確定する', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('キャンセル', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 情報を表示するテキストウィジェット
  Widget _buildInfoText(String label, String value, {bool isHighlight = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(
          value, 
          style: TextStyle(
            fontSize: isHighlight ? 24 : 18, 
            fontWeight: FontWeight.bold,
            color: isHighlight ? Colors.blue : Colors.black87,
          ),
        ),
      ],
    );
  }

  // ドラッグ可能な線のウィジェット
  Widget _buildDraggableLine({
    required Color color,
    required double xPos,
    required String label,
    required Function(double) onDrag,
  }) {
    // ヒットエリアの幅（つかみやすさのため20~40px程度確保）
    const double hitAreaWidth = 40.0; 

    return Positioned(
      left: xPos - (hitAreaWidth / 2),
      top: 0,
      bottom: 0,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // パン操作と競合しないよう、水平方向のドラッグのみを明示的にキャッチする
        onHorizontalDragUpdate: (details) {
          onDrag(details.delta.dx);
        },
        child: SizedBox(
          width: hitAreaWidth,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 実際の中心線 (1~2px)
              Container(
                width: 2,
                color: color,
              ),
              // ラベルを線の上部に浮かせる
              Positioned(
                top: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              // ドラッグ用のツマミ（つまみ部分）を下部に配置して操作性を向上
              Positioned(
                bottom: 40,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: const Icon(Icons.drag_indicator, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
