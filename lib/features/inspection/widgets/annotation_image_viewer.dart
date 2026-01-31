import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

/// 注釈画像ビューアー
/// 
/// Firestore から取得した画像 URL を表示する。
/// iPad 以外のプラットフォームで使用。
/// Apple 純正風のミニマルなデザインで、タップで全画面拡大可能。
class AnnotationImageViewer extends StatelessWidget {
  const AnnotationImageViewer({
    super.key,
    required this.imageUrl,
    this.onTap,
    this.borderRadius = 14.0,
    this.showBorder = false,
    this.height,
    this.width,
  });

  /// 画像 URL
  final String imageUrl;
  
  /// タップ時のコールバック
  final VoidCallback? onTap;
  
  /// 角丸の半径
  final double borderRadius;
  
  /// 枠線を表示するかどうか
  final bool showBorder;
  
  /// 高さ（null の場合は親に合わせる）
  final double? height;
  
  /// 幅（null の場合は親に合わせる）
  final double? width;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => _showFullScreen(context),
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: showBorder
              ? Border.all(color: const Color(0xFFE5E5EA), width: 0.5)
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => _buildShimmerPlaceholder(),
            errorWidget: (context, url, error) => _buildErrorWidget(),
          ),
        ),
      ),
    );
  }

  /// Shimmer スケルトン表示
  Widget _buildShimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE5E5EA),
      highlightColor: const Color(0xFFF2F2F7),
      child: Container(
        color: Colors.white,
        child: const Center(
          child: Icon(
            CupertinoIcons.photo,
            size: 48,
            color: Color(0xFFE5E5EA),
          ),
        ),
      ),
    );
  }

  /// エラー時の表示
  Widget _buildErrorWidget() {
    return Container(
      color: const Color(0xFFF2F2F7),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 32,
              color: Color(0xFF8E8E93),
            ),
            SizedBox(height: 8),
            Text(
              '画像を読み込めません',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF8E8E93),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 全画面表示
  void _showFullScreen(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: _FullScreenImageViewer(imageUrl: imageUrl),
          );
        },
      ),
    );
  }
}

/// 全画面画像ビューアー
class _FullScreenImageViewer extends StatelessWidget {
  const _FullScreenImageViewer({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // 画像
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CupertinoActivityIndicator(radius: 16),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(
                      CupertinoIcons.exclamationmark_triangle,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
            // 閉じるボタン
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).pop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.xmark,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 注釈画像のリストビューア
/// 
/// 複数の注釈画像をカルーセル形式で表示
class AnnotationImageCarousel extends StatelessWidget {
  const AnnotationImageCarousel({
    super.key,
    required this.imageUrls,
    this.height = 200,
    this.onImageTap,
  });

  final List<String> imageUrls;
  final double height;
  final void Function(int index, String url)? onImageTap;

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
      return _buildEmptyState();
    }

    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: AnnotationImageViewer(
                imageUrl: imageUrls[index],
                onTap: onImageTap != null
                    ? () => onImageTap!(index, imageUrls[index])
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E5EA),
          width: 0.5,
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.photo_on_rectangle,
              size: 40,
              color: Color(0xFFC7C7CC),
            ),
            SizedBox(height: 12),
            Text(
              '注釈画像がありません',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF8E8E93),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer スケルトンカード
/// 
/// ローディング中に表示するスケルトンカード
class AnnotationSkeletonCard extends StatelessWidget {
  const AnnotationSkeletonCard({
    super.key,
    this.height = 200,
    this.width,
    this.borderRadius = 14.0,
  });

  final double height;
  final double? width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE5E5EA),
      highlightColor: const Color(0xFFF2F2F7),
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
