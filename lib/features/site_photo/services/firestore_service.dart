// firestore_service.dart
// Firestore データベースサービス
// 撮影項目の取得・更新・初期化・画像アップロードを担当

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/photo_item.dart';
import '../../../core/constants/master_data.dart';

/// Firestore データベースサービス
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

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
      // === サブコレクションが空の場合 ===
      if (snapshot.docs.isEmpty) {
        // 自動初期化は廃止。ユーザー操作で初期化させるため、空リストを返す。
        return <PhotoItem>[];
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

  /// 選択された項目で初期化
  /// 
  /// [projectId] 工事ID
  /// [selectedItems] 選択されたカテゴリーと項目のマップ
  /// [blackboardTypes] 各項目の黒板タイプマップ（省略可）
  Future<void> initializeWithSelectedItems(
    String projectId,
    Map<String, List<String>> selectedItems, {
    Map<String, Map<String, String>>? blackboardTypes,
  }) async {
    // まず既存データを全削除（リセットと同じ処理）
    await resetAllData(projectId);

    // 新規データの作成（500件ごとにバッチ分割）
    final photosRef = _firestore
        .collection('projects')
        .doc(projectId)
        .collection('site_photos');
    
    final categoriesRef = _firestore
        .collection('projects')
        .doc(projectId)
        .collection('categories');

    WriteBatch batch = _firestore.batch();
    int batchCount = 0;

    // カテゴリーごとに処理
    for (final categoryName in selectedItems.keys) {
      // 1. カテゴリーを作成
      final catDocRef = categoriesRef.doc();
      final category = SiteCategory(
        id: catDocRef.id,
        name: categoryName,
        createdAt: DateTime.now(), // オーダー代わり
      );
      batch.set(catDocRef, category.toFirestore());
      batchCount++;

      // 2. 項目を作成
      final items = selectedItems[categoryName]!;
      for (final itemName in items) {
        final docRef = photosRef.doc();
        
        // 黒板タイプを取得（指定がなければデフォルト）
        final blackboardType = blackboardTypes?[categoryName]?[itemName] ?? defaultBlackboardType;
        
        final item = PhotoItem(
          id: docRef.id,
          category: categoryName,
          name: itemName,
          status: 'pending', // 必ず pending で初期化
          blackboardType: blackboardType,
          createdAt: DateTime.now(), // 現在時刻を設定
        );
        
        batch.set(docRef, item.toFirestore());
        batchCount++;

        // 500件に達したらコミット
        if (batchCount >= 450) { 
          await batch.commit();
          batch = _firestore.batch();
          batchCount = 0;
        }
      }
    }

    // 残りをコミット
    if (batchCount > 0) {
      await batch.commit();
    }
  }

  /// 工事写真データを全て削除（リセット）
  Future<void> resetAllData(String projectId) async {
    // 1. 写真データの削除
    final photosRef = _firestore
        .collection('projects')
        .doc(projectId)
        .collection('site_photos');

    bool photosRemain = true;
    while (photosRemain) {
      final snapshot = await photosRef.limit(400).get();
      if (snapshot.docs.isEmpty) {
        photosRemain = false;
        break;
      }
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // 2. カテゴリーデータの削除
    final categoriesRef = _firestore
        .collection('projects')
        .doc(projectId)
        .collection('categories');

    bool categoriesRemain = true;
    while (categoriesRemain) {
      final snapshot = await categoriesRef.limit(400).get();
      if (snapshot.docs.isEmpty) {
        categoriesRemain = false;
        break;
      }
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  // ==========================================
  // カテゴリー（工程）管理メソッド
  // ==========================================

  /// カテゴリー一覧を取得
  Stream<List<SiteCategory>> getCategories(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('categories')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SiteCategory.fromFirestore(doc.id, doc.data()))
          .toList();
    });
  }

  /// カテゴリーを追加
  Future<void> addCategory(String projectId, String name) async {
    final ref = _firestore
        .collection('projects')
        .doc(projectId)
        .collection('categories')
        .doc();
    
    final category = SiteCategory(
      id: ref.id,
      name: name,
    );
    
    await ref.set(category.toFirestore());
  }

  /// カテゴリーを更新（名称変更）
  /// 関連する項目のカテゴリー名も一括更新する
  Future<void> updateCategory(String projectId, String categoryId, String oldName, String newName) async {
    // 1. カテゴリー自体の更新
    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('categories')
        .doc(categoryId)
        .update({'name': newName});

    // 2. 関連する項目のカテゴリー名を更新（Batch処理）
    // 注意: データ量が多い場合は分割処理が必要だが、ここでは簡易的に実装
    final photosRef = _firestore
        .collection('projects')
        .doc(projectId)
        .collection('site_photos');
    
    final snapshot = await photosRef.where('category', isEqualTo: oldName).get();
    
    if (snapshot.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'category': newName});
      }
      await batch.commit();
    }
  }

  /// カテゴリーを削除
  /// 項目が含まれている場合はエラーを投げるか、呼び出し元でチェックすること
  Future<void> deleteCategory(String projectId, String categoryId) async {
    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('categories')
        .doc(categoryId)
        .delete();
  }

  // ==========================================
  // 項目（種別）管理メソッド
  // ==========================================

  /// 項目を追加
  Future<void> addPhotoItem(String projectId, String category, String name) async {
    final ref = _firestore
        .collection('projects')
        .doc(projectId)
        .collection('site_photos')
        .doc();

    final item = PhotoItem(
      id: ref.id,
      category: category,
      name: name,
      createdAt: DateTime.now(),
    );

    await ref.set(item.toFirestore());
  }

  /// 項目を削除
  Future<void> deletePhotoItem(String projectId, String itemId) async {
    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('site_photos')
        .doc(itemId)
        .delete();
  }

  /// 項目名を更新
  Future<void> updatePhotoItemName(String projectId, String itemId, String newName) async {
    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('site_photos')
        .doc(itemId)
        .update({'name': newName});
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
      // 全てのマスターデータを使用
      await initializeWithSelectedItems(projectId, masterWorkItems);
    }
  }
}
