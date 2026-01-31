import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../application/pencil_kit_providers.dart';
import '../utils/platform_utils.dart';
import 'annotation_image_viewer.dart';
import 'pencil_kit_canvas.dart';

/// 図面と注釈を自動読み込みで表示するセクション
/// 
/// 1:1 関係（製品:図面）を前提とした設計:
/// - 図面: products/{productId}/drawing.png
/// - 注釈: products/{productId}/annotations/*.png
/// 
/// プラットフォームに応じた表示:
/// - iPad (iOS): PencilKit で編集可能
/// - その他: 読み取り専用で閲覧
class ProductAnnotationSection extends ConsumerWidget {
  const ProductAnnotationSection({
    super.key,
    required this.productId,
    this.projectId,
    this.stepId,
    this.inspectionDate,
    this.height = 280,
    this.onAnnotationSaved,
  });

  /// 製品 ID（必須 - 図面と注釈の取得に使用）
  final String productId;
  
  /// プロジェクト ID（オプショナル - Firebase パス互換性用）
  final String? projectId;
  
  /// 工程ステップ ID
  final String? stepId;
  
  /// 検査日
  final DateTime? inspectionDate;
  
  /// ウィジェットの高さ
  final double height;
  
  /// 注釈保存完了時のコールバック
  final void Function(String url)? onAnnotationSaved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 図面と注釈をまとめて取得
    final dataAsync = ref.watch(productAnnotationDataProvider(productId));

    return dataAsync.when(
      loading: () => _buildShimmerLoading(),
      error: (error, stack) => _buildErrorState(error),
      data: (data) => _buildContent(context, ref, data),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ProductAnnotationData data,
  ) {
    final canEdit = PlatformUtils.isPencilKitSupported;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ヘッダー
        _buildHeader(canEdit, data),
        const SizedBox(height: 8),
        // コンテンツ
        if (canEdit)
          _buildEditableContent(context, ref, data)
        else
          _buildReadOnlyContent(context, data),
      ],
    );
  }

  Widget _buildHeader(bool canEdit, ProductAnnotationData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.doc_text_viewfinder,
            size: 18,
            color: Color(0xFF8E8E93),
          ),
          const SizedBox(width: 6),
          Text(
            '図面・注釈',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 8),
          if (data.hasDrawing)
            _buildStatusChip('図面あり', const Color(0xFF34C759))
          else
            _buildStatusChip('図面未登録', const Color(0xFFFF9500)),
          if (data.hasAnnotations) ...[
            const SizedBox(width: 6),
            _buildStatusChip('注釈 ${data.annotationUrls.length}件', const Color(0xFF007AFF)),
          ],
          const Spacer(),
          if (canEdit)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.pencil, size: 14, color: Color(0xFF007AFF)),
                  SizedBox(width: 4),
                  Text(
                    '編集可能',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF007AFF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEditableContent(
    BuildContext context,
    WidgetRef ref,
    ProductAnnotationData data,
  ) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 背景図面（または未登録プレースホルダー）
            if (data.hasDrawing)
              CachedNetworkImage(
                imageUrl: data.drawingUrl!,
                fit: BoxFit.contain,
                placeholder: (context, url) => _buildImageShimmer(),
                errorWidget: (context, url, error) => _buildDrawingNotFound(),
              )
            else
              _buildDrawingNotFound(),
            // 最新注釈のオーバーレイ
            if (data.latestAnnotationUrl != null)
              CachedNetworkImage(
                imageUrl: data.latestAnnotationUrl!,
                fit: BoxFit.contain,
                placeholder: (context, url) => const SizedBox.shrink(),
                errorWidget: (context, url, error) => const SizedBox.shrink(),
              ),
            // 編集ボタン
            Positioned(
              bottom: 16,
              right: 16,
              child: _buildEditButton(context, ref, data),
            ),
            // 注釈サムネイル（複数ある場合）
            if (data.annotationUrls.length > 1)
              Positioned(
                top: 8,
                right: 8,
                child: _buildAnnotationThumbnails(data.annotationUrls),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditButton(
    BuildContext context,
    WidgetRef ref,
    ProductAnnotationData data,
  ) {
    return CupertinoButton(
      onPressed: () => _openEditor(context, ref, data),
      color: const Color(0xFF007AFF),
      borderRadius: BorderRadius.circular(25),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.pencil, size: 18),
          SizedBox(width: 6),
          Text(
            '注釈を追加',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnotationThumbnails(List<String> urls) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.photo_on_rectangle, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            '${urls.length}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyContent(BuildContext context, ProductAnnotationData data) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 背景図面
            if (data.hasDrawing)
              CachedNetworkImage(
                imageUrl: data.drawingUrl!,
                fit: BoxFit.contain,
                placeholder: (context, url) => _buildImageShimmer(),
                errorWidget: (context, url, error) => _buildDrawingNotFound(),
              )
            else
              _buildDrawingNotFound(),
            // 最新注釈のオーバーレイ
            if (data.latestAnnotationUrl != null)
              CachedNetworkImage(
                imageUrl: data.latestAnnotationUrl!,
                fit: BoxFit.contain,
                placeholder: (context, url) => const SizedBox.shrink(),
                errorWidget: (context, url, error) => const SizedBox.shrink(),
              ),
            // 全画面表示ボタン
            if (data.hasDrawing || data.hasAnnotations)
              Positioned(
                bottom: 12,
                right: 12,
                child: _buildFullScreenButton(context, data),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullScreenButton(BuildContext context, ProductAnnotationData data) {
    return CupertinoButton(
      onPressed: () => _openFullScreen(context, data),
      padding: EdgeInsets.zero,
      minimumSize: const Size.square(36),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          CupertinoIcons.arrow_up_left_arrow_down_right,
          size: 16,
          color: Colors.white,
        ),
      ),
    );
  }

  /// 図面未登録時のプレースホルダー（Apple風クリーンデザイン）
  Widget _buildDrawingNotFound() {
    return Container(
      color: const Color(0xFFFAFAFA),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                CupertinoIcons.doc,
                size: 32,
                color: Color(0xFFC7C7CC),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '図面未登録',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8E8E93),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'この製品の図面はまだ登録されていません',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFFC7C7CC),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE5E5EA),
      highlightColor: const Color(0xFFF2F2F7),
      child: Container(color: Colors.white),
    );
  }

  Widget _buildShimmerLoading() {
    return Container(
      height: height + 40,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー shimmer
          Shimmer.fromColors(
            baseColor: const Color(0xFFE5E5EA),
            highlightColor: const Color(0xFFF2F2F7),
            child: Container(
              height: 24,
              width: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // コンテンツ shimmer
          Expanded(
            child: Shimmer.fromColors(
              baseColor: const Color(0xFFE5E5EA),
              highlightColor: const Color(0xFFF2F2F7),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 40,
              color: Color(0xFFFF3B30),
            ),
            const SizedBox(height: 12),
            const Text(
              '読み込みに失敗しました',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFF3B30),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              error.toString().length > 50 
                  ? '${error.toString().substring(0, 50)}...'
                  : error.toString(),
              style: TextStyle(
                fontSize: 13,
                color: Colors.red[300],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref,
    ProductAnnotationData data,
  ) async {
    // ボトムシートで編集画面を表示（図面を背景に）
    final resultUrl = await showAnnotationSheet(
      context: context,
      projectId: projectId,
      productId: productId,
      stepId: stepId,
      inspectionDate: inspectionDate,
      backgroundImageUrl: data.drawingUrl,
    );

    if (resultUrl != null) {
      // キャッシュを無効化してリフレッシュ
      ref.invalidate(productAnnotationDataProvider(productId));
      onAnnotationSaved?.call(resultUrl);
    }
  }

  void _openFullScreen(BuildContext context, ProductAnnotationData data) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => _FullScreenImageViewer(
        drawingUrl: data.drawingUrl,
        latestAnnotationUrl: data.latestAnnotationUrl,
        annotationUrls: data.annotationUrls,
      ),
    );
  }
}

/// 全画面画像ビューア（図面 + 注釈オーバーレイ）
class _FullScreenImageViewer extends StatelessWidget {
  const _FullScreenImageViewer({
    this.drawingUrl,
    this.latestAnnotationUrl,
    this.annotationUrls = const [],
  });

  final String? drawingUrl;
  final String? latestAnnotationUrl;
  final List<String> annotationUrls;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // メインコンテンツ
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 図面
                    if (drawingUrl != null)
                      CachedNetworkImage(
                        imageUrl: drawingUrl!,
                        fit: BoxFit.contain,
                      ),
                    // 注釈オーバーレイ
                    if (latestAnnotationUrl != null)
                      CachedNetworkImage(
                        imageUrl: latestAnnotationUrl!,
                        fit: BoxFit.contain,
                      ),
                  ],
                ),
              ),
            ),
            // 閉じるボタン
            Positioned(
              top: 8,
              right: 8,
              child: CupertinoButton(
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.xmark,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // 注釈件数バッジ
            if (annotationUrls.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${annotationUrls.length} 件の注釈',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
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

// ─────────────────────────────────────────────────────────────
// 後方互換性のための既存ウィジェット
// ─────────────────────────────────────────────────────────────

/// 注釈表示/編集ウィジェット（後方互換用）
/// 
/// 新規実装では ProductAnnotationSection を使用してください
class AnnotationDisplayWidget extends ConsumerWidget {
  const AnnotationDisplayWidget({
    super.key,
    required this.projectId,
    required this.productId,
    this.stepId,
    this.inspectionDate,
    this.annotationUrls = const [],
    this.backgroundImagePath,
    this.backgroundImageUrl,
    this.height = 250,
    this.onAnnotationSaved,
  });

  final String projectId;
  final String productId;
  final String? stepId;
  final DateTime? inspectionDate;
  final List<String> annotationUrls;
  final String? backgroundImagePath;
  final String? backgroundImageUrl;
  final double height;
  final void Function(String url)? onAnnotationSaved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canEdit = PlatformUtils.isPencilKitSupported;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(canEdit),
        const SizedBox(height: 8),
        if (canEdit)
          _buildEditableContent(context, ref)
        else
          _buildReadOnlyContent(context),
      ],
    );
  }

  Widget _buildHeader(bool canEdit) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(CupertinoIcons.pencil_outline, size: 18, color: Color(0xFF8E8E93)),
          const SizedBox(width: 6),
          Text(
            '手書き注釈',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey[700]),
          ),
          const Spacer(),
          if (canEdit)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.pencil, size: 14, color: Color(0xFF007AFF)),
                  SizedBox(width: 4),
                  Text('編集可能', style: TextStyle(fontSize: 12, color: Color(0xFF007AFF), fontWeight: FontWeight.w500)),
                ],
              ),
            )
          else if (annotationUrls.isNotEmpty)
            Text('${annotationUrls.length} 件', style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
        ],
      ),
    );
  }

  Widget _buildEditableContent(BuildContext context, WidgetRef ref) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          if (annotationUrls.isNotEmpty)
            Positioned(
              top: 8,
              right: 8,
              child: SizedBox(
                height: 60,
                child: Row(
                  children: annotationUrls.take(3).map((url) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: AnnotationImageViewer(imageUrl: url, borderRadius: 8),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          Center(
            child: CupertinoButton(
              onPressed: () => _openEditor(context, ref),
              color: const Color(0xFF007AFF),
              borderRadius: BorderRadius.circular(25),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.pencil, size: 20),
                  SizedBox(width: 8),
                  Text('注釈を追加', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyContent(BuildContext context) {
    if (annotationUrls.isEmpty) {
      return Container(
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E5EA), width: 0.5),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.photo_on_rectangle, size: 40, color: Color(0xFFC7C7CC)),
              SizedBox(height: 12),
              Text('注釈はまだありません', style: TextStyle(fontSize: 15, color: Color(0xFF8E8E93))),
              SizedBox(height: 4),
              Text('iPad で手書き注釈を追加できます', style: TextStyle(fontSize: 13, color: Color(0xFFC7C7CC))),
            ],
          ),
        ),
      );
    }

    return AnnotationImageCarousel(imageUrls: annotationUrls, height: height);
  }

  Future<void> _openEditor(BuildContext context, WidgetRef ref) async {
    if (backgroundImagePath != null) {
      ref.read(annotationBackgroundImageProvider.notifier).state = backgroundImagePath;
    }

    final resultUrl = await showAnnotationSheet(
      context: context,
      projectId: projectId,
      productId: productId,
      stepId: stepId,
      inspectionDate: inspectionDate,
      backgroundImagePath: backgroundImagePath,
      backgroundImageUrl: backgroundImageUrl,
    );

    if (resultUrl != null && onAnnotationSaved != null) {
      onAnnotationSaved!(resultUrl);
    }
  }
}

/// 検査詳細ページ用の注釈セクション（後方互換用）
class InspectionAnnotationSection extends ConsumerWidget {
  const InspectionAnnotationSection({
    super.key,
    required this.projectId,
    required this.productId,
    this.stepId,
    this.inspectionDate,
    this.backgroundImagePath,
    this.onAnnotationUpdated,
  });

  final String projectId;
  final String productId;
  final String? stepId;
  final DateTime? inspectionDate;
  final String? backgroundImagePath;
  final VoidCallback? onAnnotationUpdated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final annotationUrlsAsync = ref.watch(
      annotationUrlsProvider((projectId: projectId, productId: productId)),
    );

    return annotationUrlsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: AnnotationSkeletonCard(height: 200),
      ),
      error: (error, stack) => _buildErrorState(error),
      data: (urls) => AnnotationDisplayWidget(
        projectId: projectId,
        productId: productId,
        stepId: stepId,
        inspectionDate: inspectionDate,
        annotationUrls: urls,
        backgroundImagePath: backgroundImagePath,
        onAnnotationSaved: (url) {
          ref.invalidate(annotationUrlsProvider((projectId: projectId, productId: productId)));
          onAnnotationUpdated?.call();
        },
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.exclamationmark_triangle, size: 32, color: Color(0xFFFF3B30)),
            const SizedBox(height: 8),
            Text('注釈の読み込みに失敗しました', style: TextStyle(fontSize: 14, color: Colors.red[700])),
          ],
        ),
      ),
    );
  }
}
