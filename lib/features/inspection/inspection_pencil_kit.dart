/// PencilKit 検査用手書きモジュール
///
/// 建設業向け PMS の検査入力画面で使用する手書き注釈機能を提供します。
/// iOS PencilKit を使用し、Apple Pencil での描画に対応しています。
///
/// 主な機能:
/// - 現場写真・図面への手書き注釈
/// - ペン・消しゴム・定規ツール
/// - Firebase Storage へのアップロード
/// - Firestore 検査ドキュメントへの連携
///
/// 使用例:
/// ```dart
/// import 'package:pms/features/inspection/inspection_pencil_kit.dart';
///
/// // ボトムシートで表示
/// final url = await showAnnotationSheet(
///   context: context,
///   backgroundImagePath: '/path/to/photo.jpg',
///   projectId: 'project123',
///   productId: 'product456',
///   stepId: 'step789',
/// );
///
/// // フルスクリーンで表示
/// final url = await showAnnotationFullScreen(
///   context: context,
///   backgroundImagePath: '/path/to/photo.jpg',
/// );
/// ```
library;

// Application layer
export 'application/pencil_kit_providers.dart';

// Data layer
export 'data/annotation_storage_service.dart';

// Widgets
export 'widgets/pencil_kit_canvas.dart';
export 'widgets/pencil_kit_toolbar.dart';
export 'widgets/platform_placeholder.dart';
export 'widgets/annotation_image_viewer.dart';
export 'widgets/annotation_display.dart';

// Utils
export 'utils/platform_utils.dart';
