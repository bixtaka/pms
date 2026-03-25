import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../inspection/data/annotation_storage_service.dart';

/// 製品図面のサムネイル表示ウィジェット
/// 
/// Firebase Storage から `products/{productCode}/drawing.png` を取得して表示
/// - 読み込み中: Shimmer エフェクト
/// - 画像なし (404): デフォルトアイコン表示
/// - メモリ最適化: CachedNetworkImage + memCacheWidth
class ProductDrawingThumbnail extends StatefulWidget {
  const ProductDrawingThumbnail({
    super.key,
    required this.productCode,
    this.size = 50.0,
    this.borderRadius = 6.0,
    this.borderColor,
    this.borderWidth = 1.0,
  });

  /// 製品コード (Storage パス: products/{productCode}/drawing.png)
  final String productCode;

  /// サムネイルのサイズ (正方形)
  final double size;

  /// 角丸の半径
  final double borderRadius;

  /// 枠線の色 (null の場合は Colors.grey[300])
  final Color? borderColor;

  /// 枠線の幅
  final double borderWidth;

  @override
  State<ProductDrawingThumbnail> createState() => _ProductDrawingThumbnailState();
}

class _ProductDrawingThumbnailState extends State<ProductDrawingThumbnail> {
  String? _cachedUrl;
  bool _loading = true;
  bool _hasError = false;

  final _storageService = AnnotationStorageService();

  @override
  void initState() {
    super.initState();
    _loadDrawingUrl();
  }

  @override
  void didUpdateWidget(covariant ProductDrawingThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productCode != widget.productCode) {
      _loadDrawingUrl();
    }
  }

  Future<void> _loadDrawingUrl() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _hasError = false;
    });

    try {
      debugPrint('🖼️ ProductDrawingThumbnail: Loading for ${widget.productCode}');
      final url = await _storageService.getDrawingUrl(widget.productCode);
      debugPrint('🖼️ ProductDrawingThumbnail: Got URL: $url');
      if (mounted) {
        setState(() {
          _cachedUrl = url;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('ProductDrawingThumbnail: Error loading drawing: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = widget.borderColor ?? Colors.grey[300]!;

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: effectiveBorderColor,
          width: widget.borderWidth,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius - widget.borderWidth),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    // Loading state
    if (_loading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(color: Colors.white),
      );
    }

    // Error or no image
    if (_hasError || _cachedUrl == null) {
      return Container(
        color: Colors.grey[50],
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: widget.size * 0.4,
            color: Colors.grey[400],
          ),
        ),
      );
    }

    // Cached network image
    return CachedNetworkImage(
      imageUrl: _cachedUrl!,
      fit: BoxFit.cover,
      memCacheWidth: 100,
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(color: Colors.white),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[50],
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: widget.size * 0.4,
            color: Colors.grey[400],
          ),
        ),
      ),
    );
  }
}
