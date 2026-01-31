import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../utils/platform_utils.dart';

/// iOS 以外のプラットフォームで表示するプレースホルダーウィジェット
/// 
/// PencilKit は iOS 専用のため、他のプラットフォームでは
/// この代替 UI を表示する。背景画像がある場合は閲覧可能。
class PencilKitPlatformPlaceholder extends StatelessWidget {
  const PencilKitPlatformPlaceholder({
    super.key,
    this.onClose,
    this.backgroundImageUrl,
  });

  /// 閉じるボタンのコールバック
  final VoidCallback? onClose;
  
  /// 背景画像URL（図面）
  final String? backgroundImageUrl;

  @override
  Widget build(BuildContext context) {
    final hasImage = backgroundImageUrl != null && backgroundImageUrl!.isNotEmpty;
    
    return Container(
      color: const Color(0xFFF2F2F7), // iOS システムグレー背景
      child: SafeArea(
        child: Column(
          children: [
            // ヘッダー
            _buildHeader(context),
            // メインコンテンツ
            Expanded(
              child: hasImage 
                  ? _buildImageViewer() 
                  : _buildNoImagePlaceholder(),
            ),
            // フッター（iPad での編集案内）
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  /// 図面ビューア（読み取り専用）
  Widget _buildImageViewer() {
    return Container(
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
            // 図面画像
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: backgroundImageUrl!,
                fit: BoxFit.contain,
                placeholder: (context, url) => _buildShimmerPlaceholder(),
                errorWidget: (context, url, error) => _buildImageError(),
              ),
            ),
            // 読み取り専用バッジ
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.eye,
                      size: 16,
                      color: Colors.white,
                    ),
                    SizedBox(width: 6),
                    Text(
                      '閲覧モード',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ズームヒント
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.hand_draw,
                        size: 14,
                        color: Colors.white70,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'ピンチでズーム',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shimmer プレースホルダー
  Widget _buildShimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE5E5EA),
      highlightColor: const Color(0xFFF2F2F7),
      child: Container(
        color: Colors.white,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.doc,
                size: 48,
                color: Colors.white,
              ),
              SizedBox(height: 12),
              Text(
                '図面を読み込み中...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 画像読み込みエラー
  Widget _buildImageError() {
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
              '図面を読み込めません',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 図面がない場合のプレースホルダー
  Widget _buildNoImagePlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ドキュメント アイコン
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                CupertinoIcons.doc,
                size: 40,
                color: Color(0xFF8E8E93),
              ),
            ),
            const SizedBox(height: 24),
            // メッセージ
            Text(
              '図面が登録されていません',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'この製品の図面はまだアップロードされていません。',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
            onPressed: onClose ?? () => Navigator.of(context).pop(),
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
          Expanded(
            child: Center(
              child: Text(
                backgroundImageUrl != null ? '図面プレビュー' : '手書き注釈',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          // 右側のスペーサー
          const SizedBox(width: 80),
        ],
      ),
    );
  }

  /// フッター（iPad での編集案内）
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              CupertinoIcons.pencil,
              size: 20,
              color: Color(0xFF007AFF),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '手書き注釈を追加するには',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
                Text(
                  'iPad + Apple Pencil で操作してください',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 24,
          color: const Color(0xFF007AFF),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF1C1C1E),
            ),
          ),
        ),
      ],
    );
  }

  /// 現在のプラットフォームが iOS かどうかを判定
  static bool get isIOSPlatform => PlatformUtils.isIOS;
}

