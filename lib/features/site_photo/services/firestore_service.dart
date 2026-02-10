// firestore_service.dart
// Firestore データベースサービス
// 撮影項目の取得・更新・初期化・画像アップロードを担当

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/photo_item.dart';

/// Firestore データベースサービス
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// デフォルトの鉄骨製作工程リスト
  static const List<String> _defaultProcesses = [
    '一次加工',
    '組立',
    '溶接',
    '検査',
    '塗装',
  ];

  /// 画像を Firebase Storage にアップロード
  /// 
  /// [projectId] 工事ID
  /// [filePath] ローカルファイルパス
  /// 
  /// 戻り値: アップロードされた画像の公開URL
  /// 
  /// Web環境の場合はダミーURLを返します。
  Future<String> uploadImage(String projectId, String filePath) async {
    // === Web環境の場合はダミーURLを返す ===
    if (kIsWeb) {
      debugPrint('🌐 Web環境のため、画像アップロードをスキップします');
      return 'https://via.placeholder.com/800x600.png?text=Web+Dummy+Image';
    }

    try {
      // === ファイルを読み込み ===
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('ファイルが存在しません: $filePath');
      }

      // === タイムスタンプ付きファイル名を生成 ===
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$timestamp.jpg';
      final storagePath = 'projects/$projectId/$fileName';

      // === Firebase Storage にアップロード ===
      debugPrint('📤 画像アップロード開始: $storagePath');
      final ref = _storage.ref().child(storagePath);
      final uploadTask = ref.putFile(file);

      // === アップロード完了を待つ ===
      final snapshot = await uploadTask;
      
      // === 公開URLを取得 ===
      final downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('✅ 画像アップロード完了: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      debugPrint('❌ 画像アップロードエラー: $e');
      rethrow;
    }
  }

  /// 指定した工事の写真リストをリアルタイム取得
  /// 
  /// [projectId] 工事ID
  /// 
  /// 戻り値: 写真リストのストリーム
  /// 
  /// 初期化ロジック:
  /// - サブコレクションが空の場合、デフォルトの工程リストを自動作成
  Stream<List<PhotoItem>> getPhotoItems(String projectId) {
    final collectionRef = _firestore
        .collection('projects')
        .doc(projectId)
        .collection('site_photos');

    return collectionRef
        .orderBy('createdAt')
        .snapshots()
        .asyncMap((snapshot) async {
      // === サブコレクションが空の場合、初期化 ===
      if (snapshot.docs.isEmpty) {
        await _initializeDefaultData(projectId);
        // 初期化後、再度データを取得
        final newSnapshot = await collectionRef.orderBy('createdAt').get();
        return newSnapshot.docs
            .map((doc) => PhotoItem.fromFirestore(doc.id, doc.data()))
            .toList();
      }

      // === データが存在する場合、そのまま返す ===
      return snapshot.docs
          .map((doc) => PhotoItem.fromFirestore(doc.id, doc.data()))
          .toList();
    });
  }

  /// 写真データを更新
  /// 
  /// [projectId] 工事ID
  /// [item] 更新する写真データ
  Future<void> updatePhotoItem(String projectId, PhotoItem item) async {
    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('site_photos')
        .doc(item.id)
        .update(item.toFirestore());
  }

  /// デフォルトの工程リストを初期化
  /// 
  /// [projectId] 工事ID
  /// 
  /// 注意: このメソッドは親コレクション (`projects`) には一切書き込みません。
  /// 全てのデータは `projects/{projectId}/site_photos` サブコレクション内に作成されます。
  Future<void> _initializeDefaultData(String projectId) async {
    final batch = _firestore.batch();
    final collectionRef = _firestore
        .collection('projects')
        .doc(projectId)
        .collection('site_photos');

    for (final processName in _defaultProcesses) {
      final docRef = collectionRef.doc(); // 自動生成ID
      final item = PhotoItem(
        id: docRef.id,
        name: processName,
        status: 'pending',
      );
      batch.set(docRef, item.toFirestore());
    }

    await batch.commit();
  }

  /// テスト用: デモデータを手動で初期化
  /// 
  /// [projectId] 工事ID
  /// 
  /// このメソッドは外部から呼び出し可能です。
  /// 既存データがある場合は何もしません。
  Future<void> initializeDemoData(String projectId) async {
    final snapshot = await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('site_photos')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      await _initializeDefaultData(projectId);
    }
  }
}
