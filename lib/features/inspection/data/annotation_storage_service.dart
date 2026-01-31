import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'file_loader_stub.dart'
    if (dart.library.io) 'file_loader_io.dart' as file_loader;

/// 手書き注釈を Firebase Storage に保存するサービス
/// 
/// 鉄骨製品は「1図面につき1製品符号」の 1:1 関係
/// - 図面: products/{productId}/drawing.png
/// - 注釈: products/{productId}/annotations/{timestamp}.png
class AnnotationStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─────────────────────────────────────────────────────────────
  // 図面取得
  // ─────────────────────────────────────────────────────────────

  /// 製品の図面 URL を取得
  /// 
  /// Storage パス: products/{productId}/drawing.png
  /// 
  /// 図面が存在しない場合は null を返す
  Future<String?> getDrawingUrl(String productId) async {
    try {
      final ref = _storage.ref('products/$productId/drawing.png');
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      // object-not-found エラーの場合は null を返す
      if (e.code == 'object-not-found') {
        return null;
      }
      rethrow;
    }
  }

  /// 図面が存在するかどうかを確認
  Future<bool> hasDrawing(String productId) async {
    try {
      final ref = _storage.ref('products/$productId/drawing.png');
      await ref.getMetadata();
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        return false;
      }
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 注釈取得
  // ─────────────────────────────────────────────────────────────

  /// 製品の最新注釈 URL を取得
  /// 
  /// Storage パス: products/{productId}/annotations/ 内の最新 PNG
  /// 
  /// 注釈が存在しない場合は null を返す
  Future<String?> getLatestAnnotationUrl(String productId) async {
    try {
      final ref = _storage.ref('products/$productId/annotations');
      final listResult = await ref.listAll();
      
      if (listResult.items.isEmpty) {
        return null;
      }

      // ファイル名でソート（タイムスタンプ順）して最新を取得
      final sortedItems = listResult.items.toList()
        ..sort((a, b) => b.name.compareTo(a.name));
      
      return await sortedItems.first.getDownloadURL();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        return null;
      }
      rethrow;
    }
  }

  /// 製品のすべての注釈 URL を取得
  /// 
  /// 新しい順にソートして返す
  Future<List<String>> getAllAnnotationUrls(String productId) async {
    try {
      final ref = _storage.ref('products/$productId/annotations');
      final listResult = await ref.listAll();
      
      if (listResult.items.isEmpty) {
        return [];
      }

      // ファイル名でソート（タイムスタンプ順）
      final sortedItems = listResult.items.toList()
        ..sort((a, b) => b.name.compareTo(a.name));
      
      final urls = <String>[];
      for (final item in sortedItems) {
        urls.add(await item.getDownloadURL());
      }
      return urls;
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        return [];
      }
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 注釈アップロード
  // ─────────────────────────────────────────────────────────────

  /// 注釈画像を Firebase Storage にアップロード
  ///
  /// Storage パス: products/{productId}/annotations/{timestamp}.png
  ///
  /// Returns: アップロードされた画像の URL
  Future<String> uploadAnnotation({
    required Uint8List imageData,
    required String productId,
    String? projectId,
    DateTime? inspectionDate,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '$timestamp.png';
    
    // Firebase Storage パス（1:1 関係の新しいパス形式）
    final storagePath = 'products/$productId/annotations/$fileName';
    final ref = _storage.ref(storagePath);

    // アップロード実行
    final metadata = SettableMetadata(
      contentType: 'image/png',
      customMetadata: {
        'productId': productId,
        if (projectId != null) 'projectId': projectId,
        if (inspectionDate != null) 
          'inspectionDate': inspectionDate.toIso8601String(),
        'uploadedAt': DateTime.now().toIso8601String(),
      },
    );

    await ref.putData(imageData, metadata);
    
    // ダウンロード URL を取得
    final downloadUrl = await ref.getDownloadURL();
    
    return downloadUrl;
  }

  /// 検査ドキュメントに注釈 URL を保存する
  ///
  /// [projectId] - プロジェクト ID
  /// [productId] - 製品 ID
  /// [stepId] - 工程ステップ ID
  /// [annotationUrl] - 注釈画像の URL
  /// [inspectionDate] - 検査日
  Future<void> saveAnnotationToInspection({
    required String projectId,
    required String productId,
    required String stepId,
    required String annotationUrl,
    required DateTime inspectionDate,
  }) async {
    final docRef = _firestore
        .collection('projects')
        .doc(projectId)
        .collection('inspections')
        .doc('${productId}_$stepId');

    await docRef.set({
      'productId': productId,
      'stepId': stepId,
      'annotationUrls': FieldValue.arrayUnion([annotationUrl]),
      'lastAnnotationAt': FieldValue.serverTimestamp(),
      'inspectionDate': Timestamp.fromDate(inspectionDate),
    }, SetOptions(merge: true));
  }

  /// 製品の注釈一覧を Firestore から取得する
  ///
  /// [projectId] - プロジェクト ID
  /// [productId] - 製品 ID
  Future<List<String>> getAnnotationUrls({
    required String projectId,
    required String productId,
  }) async {
    final querySnapshot = await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('inspections')
        .where('productId', isEqualTo: productId)
        .get();

    final urls = <String>[];
    for (final doc in querySnapshot.docs) {
      final data = doc.data();
      final annotationUrls = data['annotationUrls'] as List<dynamic>?;
      if (annotationUrls != null) {
        urls.addAll(annotationUrls.cast<String>());
      }
    }
    return urls;
  }

  /// ローカルファイルから画像を読み込んで Uint8List に変換
  /// 
  /// 注意: この関数は iOS/Android でのみ動作します。
  /// Web 環境では UnsupportedError がスローされます。
  Future<Uint8List> loadImageFromFile(String filePath) async {
    if (kIsWeb) {
      throw UnsupportedError('loadImageFromFile is not supported on Web. Use file picker with bytes instead.');
    }
    return await file_loader.loadFileBytes(filePath);
  }
}

