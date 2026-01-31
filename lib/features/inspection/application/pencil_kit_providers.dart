import 'package:flutter_riverpod/flutter_riverpod.dart';

// 条件付きインポート: Web ではスタブを、ネイティブでは実際の pencil_kit を使用
import '../widgets/pencil_kit_stub.dart'
    if (dart.library.io) '../widgets/pencil_kit_native.dart';

import '../data/annotation_storage_service.dart';

/// 描画モード設定
enum DrawingMode {
  /// Apple Pencil のみで描画可能
  pencilOnly,
  /// 指でも描画可能
  fingerDrawing,
}

/// PencilKit コントローラーを管理するプロバイダー
/// 
/// NOTE: PencilKitController は PencilKit ウィジェットの onPencilKitViewCreated で
/// 取得されるため、このプロバイダーは初期値 null で開始し、
/// ウィジェット生成後に更新される
final pencilKitControllerProvider = StateProvider<PencilKitController?>((ref) => null);

/// ツールパレットの表示状態を管理
final isToolPickerVisibleProvider = StateProvider<bool>((ref) => true);

/// 描画モードを管理（デフォルト: Apple Pencil のみ）
final drawingModeProvider = StateProvider<DrawingMode>((ref) => DrawingMode.pencilOnly);

/// 現在の描画データ（Base64 形式）を管理
final currentDrawingDataProvider = StateProvider<String?>((ref) => null);

/// アップロード状態を管理
enum AnnotationUploadState {
  idle,
  uploading,
  success,
  error,
}

/// アップロード状態プロバイダー
final annotationUploadStateProvider = StateProvider<AnnotationUploadState>((ref) => AnnotationUploadState.idle);

/// アップロードエラーメッセージを管理
final annotationUploadErrorProvider = StateProvider<String?>((ref) => null);

/// アップロード後の URL を管理
final annotationUploadedUrlProvider = StateProvider<String?>((ref) => null);

/// 背景画像パスを管理（現場写真や図面）
final annotationBackgroundImageProvider = StateProvider<String?>((ref) => null);

/// Firestore から注釈 URL を取得するプロバイダー
/// 
/// 使用例:
/// ```dart
/// final urlsAsync = ref.watch(annotationUrlsProvider((
///   projectId: 'project123',
///   productId: 'product456',
/// )));
/// ```
final annotationUrlsProvider = FutureProvider.family<List<String>, ({String projectId, String productId})>(
  (ref, params) async {
    final service = AnnotationStorageService();
    return await service.getAnnotationUrls(
      projectId: params.projectId,
      productId: params.productId,
    );
  },
);

/// 注釈サービスのインスタンスを提供
final annotationStorageServiceProvider = Provider<AnnotationStorageService>((ref) {
  return AnnotationStorageService();
});

// ─────────────────────────────────────────────────────────────
// 1:1 関係用プロバイダー（productId ベース）
// ─────────────────────────────────────────────────────────────

/// 製品の図面 URL を取得するプロバイダー
/// 
/// Storage パス: products/{productId}/drawing.png
/// 
/// 使用例:
/// ```dart
/// final drawingUrlAsync = ref.watch(productDrawingUrlProvider('product123'));
/// drawingUrlAsync.when(
///   data: (url) => url != null ? showImage(url) : showPlaceholder(),
///   loading: () => showShimmer(),
///   error: (e, s) => showError(),
/// );
/// ```
final productDrawingUrlProvider = FutureProvider.family<String?, String>(
  (ref, productId) async {
    final service = ref.read(annotationStorageServiceProvider);
    return await service.getDrawingUrl(productId);
  },
);

/// 製品の最新注釈 URL を取得するプロバイダー
/// 
/// Storage パス: products/{productId}/annotations/ 内の最新ファイル
final productLatestAnnotationProvider = FutureProvider.family<String?, String>(
  (ref, productId) async {
    final service = ref.read(annotationStorageServiceProvider);
    return await service.getLatestAnnotationUrl(productId);
  },
);

/// 製品のすべての注釈 URL を取得するプロバイダー
/// 
/// Storage パス: products/{productId}/annotations/ 内の全ファイル
/// 新しい順にソートされて返される
final productAllAnnotationsProvider = FutureProvider.family<List<String>, String>(
  (ref, productId) async {
    final service = ref.read(annotationStorageServiceProvider);
    return await service.getAllAnnotationUrls(productId);
  },
);

/// 製品の図面と注釈をまとめて取得するデータクラス
class ProductAnnotationData {
  const ProductAnnotationData({
    this.drawingUrl,
    this.annotationUrls = const [],
    this.latestAnnotationUrl,
  });

  /// 図面の URL（存在しない場合は null）
  final String? drawingUrl;
  
  /// すべての注釈 URL（新しい順）
  final List<String> annotationUrls;
  
  /// 最新の注釈 URL
  final String? latestAnnotationUrl;

  /// 図面が存在するかどうか
  bool get hasDrawing => drawingUrl != null;

  /// 注釈が存在するかどうか
  bool get hasAnnotations => annotationUrls.isNotEmpty;
}

/// 製品の図面と注釈をまとめて取得するプロバイダー
/// 
/// 使用例:
/// ```dart
/// final data = ref.watch(productAnnotationDataProvider('product123'));
/// data.when(
///   data: (d) => PencilKitCanvas(
///     backgroundImageUrl: d.drawingUrl,
///     // 最新注釈をオーバーレイとして表示等
///   ),
///   loading: () => Shimmer(),
///   error: (e, s) => ErrorWidget(),
/// );
/// ```
final productAnnotationDataProvider = FutureProvider.family<ProductAnnotationData, String>(
  (ref, productId) async {
    final service = ref.read(annotationStorageServiceProvider);
    
    // 並列で取得してパフォーマンス向上
    final results = await Future.wait([
      service.getDrawingUrl(productId),
      service.getAllAnnotationUrls(productId),
    ]);
    
    final drawingUrl = results[0] as String?;
    final annotationUrls = results[1] as List<String>;
    
    return ProductAnnotationData(
      drawingUrl: drawingUrl,
      annotationUrls: annotationUrls,
      latestAnnotationUrl: annotationUrls.isNotEmpty ? annotationUrls.first : null,
    );
  },
);
