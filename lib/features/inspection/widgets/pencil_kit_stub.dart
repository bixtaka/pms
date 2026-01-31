/// Web 環境用の PencilKit スタブ
/// 
/// Web では pencil_kit パッケージがサポートされていないため、
/// ダミーの型と定数を提供します。
library;

import 'package:flutter/material.dart';

/// PencilKit の DrawingPolicy スタブ
enum PencilKitIos14DrawingPolicy {
  anyInput,
  pencilOnly,
}

/// PencilKit コントローラーのスタブ
class PencilKitController {
  Future<void> show() async {}
  Future<void> hide() async {}
  Future<void> clear() async {}
  Future<void> undo() async {}
  Future<void> redo() async {}
  Future<String> getBase64PngData() async => '';
  Future<String> getBase64JpegData() async => '';
}

/// PencilKit ウィジェットのスタブ（Web では使用されない）
class PencilKit extends StatelessWidget {
  const PencilKit({
    super.key,
    this.onPencilKitViewCreated,
    this.alwaysBounceVertical = true,
    this.alwaysBounceHorizontal = true,
    this.isRulerActive = false,
    this.drawingPolicy = PencilKitIos14DrawingPolicy.anyInput,
    this.backgroundColor = Colors.white,
    this.isOpaque = true,
  });

  final void Function(PencilKitController)? onPencilKitViewCreated;
  final bool alwaysBounceVertical;
  final bool alwaysBounceHorizontal;
  final bool isRulerActive;
  final PencilKitIos14DrawingPolicy drawingPolicy;
  final Color backgroundColor;
  final bool isOpaque;

  @override
  Widget build(BuildContext context) {
    // Web 環境では PencilKitPlatformPlaceholder が表示されるため、
    // このウィジェットは実際には表示されない
    return const SizedBox.shrink();
  }
}
