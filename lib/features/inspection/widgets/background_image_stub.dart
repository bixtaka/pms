import 'package:flutter/material.dart';

/// Web 環境用のスタブ実装
/// 
/// Web では dart:io の File が使用できないため、
/// このスタブがフォールバックとして使用される。
/// PencilKit 自体が iOS 専用のため、実際にはこのウィジェットは
/// 表示されず、プレースホルダーが表示される。
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
    // Web 環境では表示されないが、フォールバックとしてプレースホルダーを返す
    return Container(
      color: const Color(0xFFFAFAFA),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_not_supported,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Text(
              '画像の読み込みはサポートされていません',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
