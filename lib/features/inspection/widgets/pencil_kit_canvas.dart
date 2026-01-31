import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

// 条件付きインポート: Web ではスタブを、ネイティブでは実際の pencil_kit を使用
import 'pencil_kit_stub.dart'
    if (dart.library.io) 'pencil_kit_native.dart';

import '../application/pencil_kit_providers.dart';
import '../data/annotation_storage_service.dart';
import '../utils/platform_utils.dart';
import 'pencil_kit_toolbar.dart';
import 'platform_placeholder.dart';

// 条件付きインポート: iOS/Android では dart:io を、Web ではスタブを使用
import 'background_image_stub.dart'
    if (dart.library.io) 'background_image_io.dart' as bg_image;

/// 検査用 PencilKit キャンバスウィジェット
/// 
/// 現場写真や図面の上に手書きで注釈を書き込むためのキャンバス。
/// Apple 純正風のミニマルなホワイト基調デザイン。
class InspectionPencilKitCanvas extends ConsumerStatefulWidget {
  const InspectionPencilKitCanvas({
    super.key,
    this.backgroundImagePath,
    this.backgroundImageUrl,
    this.projectId,
    this.productId,
    this.stepId,
    this.inspectionDate,
    this.onSaveComplete,
    this.onClose,
  });

  /// 背景画像のローカルパス（現場写真や図面）
  final String? backgroundImagePath;
  
  /// 背景画像のネットワーク URL（Firebase Storage 等）
  /// backgroundImagePath よりも優先される
  final String? backgroundImageUrl;
  
  /// プロジェクト ID（Firebase 保存用）
  final String? projectId;
  
  /// 製品 ID（Firebase 保存用）
  final String? productId;
  
  /// 工程ステップ ID（Firebase 保存用）
  final String? stepId;
  
  /// 検査日
  final DateTime? inspectionDate;
  
  /// 保存完了時のコールバック
  final void Function(String? annotationUrl)? onSaveComplete;
  
  /// 閉じるボタンのコールバック
  final VoidCallback? onClose;

  @override
  ConsumerState<InspectionPencilKitCanvas> createState() =>
      _InspectionPencilKitCanvasState();
}

class _InspectionPencilKitCanvasState
    extends ConsumerState<InspectionPencilKitCanvas> {
  final AnnotationStorageService _storageService = AnnotationStorageService();

  @override
  Widget build(BuildContext context) {
    // iOS 以外のプラットフォームではプレースホルダーを表示
    // kIsWeb を先にチェックして dart:io のエラーを防ぐ
    if (!PlatformUtils.isPencilKitSupported) {
      return PencilKitPlatformPlaceholder(
        onClose: widget.onClose,
        backgroundImageUrl: widget.backgroundImageUrl,
      );
    }

    final uploadState = ref.watch(annotationUploadStateProvider);
    // Note: drawingMode provider is available but PencilKitIos14DrawingPolicy.anyInput 
    // is used for broad compatibility. The drawing mode toggle still works for UI state.

    return Container(
      color: const Color(0xFFF2F2F7), // iOS システムグレー背景
      child: SafeArea(
        child: Column(
          children: [
            // ヘッダー
            _buildHeader(context, uploadState),
            // キャンバス領域
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 背景画像レイヤー
                      _buildBackgroundLayer(),
                      // PencilKit キャンバス（透明背景）
                      PencilKit(
                        onPencilKitViewCreated: (controller) {
                          ref.read(pencilKitControllerProvider.notifier).state =
                              controller;
                          // 初期設定: ツールパレットを表示
                          controller.show();
                        },
                        alwaysBounceVertical: false,
                        alwaysBounceHorizontal: false,
                        isRulerActive: false,
                        drawingPolicy: PencilKitIos14DrawingPolicy.anyInput,
                        backgroundColor: Colors.transparent,
                        isOpaque: false,
                      ),
                      // アップロード中のオーバーレイ
                      if (uploadState == AnnotationUploadState.uploading)
                        Container(
                          color: Colors.white.withValues(alpha: 0.8),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CupertinoActivityIndicator(radius: 16),
                                SizedBox(height: 12),
                                Text(
                                  '保存中...',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF8E8E93),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // ツールバー
            const PencilKitToolbar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AnnotationUploadState uploadState) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // 戻るボタン
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: uploadState == AnnotationUploadState.uploading
                ? null
                : () => _handleClose(context),
            child: const Row(
              children: [
                Icon(
                  CupertinoIcons.chevron_left,
                  color: Color(0xFF007AFF),
                  size: 22,
                ),
                SizedBox(width: 4),
                Text(
                  '戻る',
                  style: TextStyle(
                    color: Color(0xFF007AFF),
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                '手書き注釈',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          // 保存ボタン
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF007AFF),
            borderRadius: BorderRadius.circular(20),
            onPressed: uploadState == AnnotationUploadState.uploading
                ? null
                : () => _handleSave(context),
            child: const Text(
              '保存',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 背景画像レイヤーを構築
  /// 
  /// 優先順位:
  /// 1. backgroundImageUrl (ネットワーク URL) - CachedNetworkImage + Shimmer
  /// 2. backgroundImagePath (ローカルパス) - プラットフォーム固有の Image.file
  /// 3. なし - 白いキャンバス
  Widget _buildBackgroundLayer() {
    // ネットワーク URL が指定されている場合
    if (widget.backgroundImageUrl != null && widget.backgroundImageUrl!.isNotEmpty) {
      return _buildNetworkImageBackground(widget.backgroundImageUrl!);
    }
    
    // ローカルパスが指定されている場合
    if (widget.backgroundImagePath != null && widget.backgroundImagePath!.isNotEmpty) {
      return bg_image.BackgroundImageWidget(
        imagePath: widget.backgroundImagePath!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildCleanWhiteCanvas();
        },
      );
    }
    
    // 背景なし - クリーンな白いキャンバス
    return _buildCleanWhiteCanvas();
  }

  /// ネットワーク画像背景（CachedNetworkImage + Shimmer）
  Widget _buildNetworkImageBackground(String imageUrl) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.contain,
      placeholder: (context, url) => _buildShimmerPlaceholder(),
      errorWidget: (context, url, error) => _buildImageErrorWidget(),
    );
  }

  /// Shimmer スケルトンプレースホルダー
  Widget _buildShimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE5E5EA),
      highlightColor: const Color(0xFFF2F2F7),
      child: Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 120,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 画像読み込みエラー時のウィジェット
  Widget _buildImageErrorWidget() {
    return Container(
      color: const Color(0xFFFAFAFA),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 40,
              color: Color(0xFFC7C7CC),
            ),
            const SizedBox(height: 12),
            Text(
              '画像を読み込めません',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'そのまま手書きできます',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// クリーンな白いキャンバス（背景画像なし）
  Widget _buildCleanWhiteCanvas() {
    return Container(
      color: Colors.white,
    );
  }

  void _handleClose(BuildContext context) {
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleSave(BuildContext context) async {
    final controller = ref.read(pencilKitControllerProvider);
    if (controller == null) {
      _showErrorSnackBar(context, 'キャンバスが初期化されていません');
      return;
    }

    // アップロード状態を更新
    ref.read(annotationUploadStateProvider.notifier).state =
        AnnotationUploadState.uploading;

    try {
      // PNG として Base64 データを取得
      final base64Data = await controller.getBase64PngData();
      if (base64Data.isEmpty) {
        ref.read(annotationUploadStateProvider.notifier).state =
            AnnotationUploadState.idle;
        if (context.mounted) {
          _showErrorSnackBar(context, '描画データがありません');
        }
        return;
      }

      // 状態を保存
      ref.read(currentDrawingDataProvider.notifier).state = base64Data;

      // Firebase Storage へのアップロード（projectId などが設定されている場合）
      String? uploadedUrl;
      if (widget.projectId != null && widget.productId != null) {
        final bytes = base64Decode(base64Data);
        uploadedUrl = await _storageService.uploadAnnotation(
          imageData: Uint8List.fromList(bytes),
          projectId: widget.projectId!,
          productId: widget.productId!,
          inspectionDate: widget.inspectionDate ?? DateTime.now(),
        );

        // Firestore に保存
        if (widget.stepId != null) {
          await _storageService.saveAnnotationToInspection(
            projectId: widget.projectId!,
            productId: widget.productId!,
            stepId: widget.stepId!,
            annotationUrl: uploadedUrl,
            inspectionDate: widget.inspectionDate ?? DateTime.now(),
          );
        }

        ref.read(annotationUploadedUrlProvider.notifier).state = uploadedUrl;
      }

      ref.read(annotationUploadStateProvider.notifier).state =
          AnnotationUploadState.success;

      // 完了コールバック
      widget.onSaveComplete?.call(uploadedUrl);

      // 成功メッセージ
      if (context.mounted) {
        _showSuccessSnackBar(context, '保存しました');
      }
    } catch (e) {
      ref.read(annotationUploadStateProvider.notifier).state =
          AnnotationUploadState.error;
      ref.read(annotationUploadErrorProvider.notifier).state = e.toString();
      
      if (context.mounted) {
        _showErrorSnackBar(context, '保存に失敗しました: $e');
      }
    }
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(CupertinoIcons.check_mark_circled,
                color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: CupertinoColors.activeGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(CupertinoIcons.exclamationmark_circle,
                color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: CupertinoColors.destructiveRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

/// 手書き注釈シートを表示するヘルパー関数
/// 
/// 検査入力画面から呼び出して使用する
/// 
/// [backgroundImageUrl] と [backgroundImagePath] の両方が指定された場合、
/// URL が優先される
Future<String?> showAnnotationSheet({
  required BuildContext context,
  String? backgroundImagePath,
  String? backgroundImageUrl,
  String? projectId,
  String? productId,
  String? stepId,
  DateTime? inspectionDate,
}) async {
  String? resultUrl;
  
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF2F2F7),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: InspectionPencilKitCanvas(
          backgroundImagePath: backgroundImagePath,
          backgroundImageUrl: backgroundImageUrl,
          projectId: projectId,
          productId: productId,
          stepId: stepId,
          inspectionDate: inspectionDate,
          onSaveComplete: (url) {
            resultUrl = url;
            Navigator.of(context).pop();
          },
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    ),
  );
  
  return resultUrl;
}

/// フルスクリーンで手書き注釈画面を表示するヘルパー関数
/// 
/// [backgroundImageUrl] と [backgroundImagePath] の両方が指定された場合、
/// URL が優先される
Future<String?> showAnnotationFullScreen({
  required BuildContext context,
  String? backgroundImagePath,
  String? backgroundImageUrl,
  String? projectId,
  String? productId,
  String? stepId,
  DateTime? inspectionDate,
}) async {
  String? resultUrl;
  
  await Navigator.of(context).push<void>(
    CupertinoPageRoute(
      fullscreenDialog: true,
      builder: (context) => Scaffold(
        body: InspectionPencilKitCanvas(
          backgroundImagePath: backgroundImagePath,
          backgroundImageUrl: backgroundImageUrl,
          projectId: projectId,
          productId: productId,
          stepId: stepId,
          inspectionDate: inspectionDate,
          onSaveComplete: (url) {
            resultUrl = url;
            Navigator.of(context).pop();
          },
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    ),
  );
  
  return resultUrl;
}

