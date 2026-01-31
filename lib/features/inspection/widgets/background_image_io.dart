import 'dart:io';

import 'package:flutter/material.dart';

/// iOS/Android 環境用の背景画像ウィジェット
/// 
/// dart:io を使用してローカルファイルから画像を読み込み表示する
class BackgroundImageWidget extends StatelessWidget {
  const BackgroundImageWidget({
    super.key,
    required this.imagePath,
    this.fit,
    this.errorBuilder,
  });

  final String imagePath;
  final BoxFit? fit;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  @override
  Widget build(BuildContext context) {
    return Image.file(
      File(imagePath),
      fit: fit,
      errorBuilder: errorBuilder,
    );
  }
}
