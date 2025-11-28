import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/product.dart';

class WorkTypeGanttData {
  final String type;
  final DateTime? averageStartDate;
  final DateTime? averageEndDate;
  final int totalCount;
  final int completedCount;
  final double completionRate;

  WorkTypeGanttData({
    required this.type,
    this.averageStartDate,
    this.averageEndDate,
    required this.totalCount,
    required this.completedCount,
    required this.completionRate,
  });
}

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 製品リストをリアルタイムで取得
  Stream<List<Product>> getProductsStream() {
    try {
      return _firestore
          .collection('products')
          .orderBy('name')
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList(),
          )
          .handleError((error) {
            debugPrint('Firestore error: $error');
            return <Product>[];
          });
    } catch (e) {
      debugPrint('Firebase service error: $e');
      return Stream.value(<Product>[]);
    }
  }

  // 工種別ガントチャートデータを取得
  Stream<List<WorkTypeGanttData>> getWorkTypeGanttStream() {
    try {
      return _firestore
          .collection('products')
          .snapshots()
          .map((snapshot) {
            Map<String, List<Product>> workTypeGroups = {};

            // 工程カテゴリ（processCategory）でグループ化
            for (var doc in snapshot.docs) {
              Product product = Product.fromFirestore(doc);
              final category = (doc.data())['processCategory'] ?? '未分類';
              if (!workTypeGroups.containsKey(category)) {
                workTypeGroups[category] = [];
              }
              workTypeGroups[category]!.add(product);
            }

            // 各カテゴリのデータを計算
            List<WorkTypeGanttData> workTypeData = [];
            workTypeGroups.forEach((category, products) {
              final totalCount = products.length;
              final completedCount = products
                  .where((p) => p.status == 'completed')
                  .length;
              final completionRate = totalCount > 0
                  ? (completedCount / totalCount) * 100
                  : 0.0;

              // 平均開始日と終了日を計算
              DateTime? averageStartDate;
              DateTime? averageEndDate;

              final productsWithStartDate = products
                  .where((p) => p.startDate != null)
                  .toList();
              final productsWithEndDate = products
                  .where((p) => p.endDate != null)
                  .toList();

              if (productsWithStartDate.isNotEmpty) {
                final totalStartTicks = productsWithStartDate
                    .map((p) => p.startDate!.millisecondsSinceEpoch)
                    .reduce((a, b) => a + b);
                averageStartDate = DateTime.fromMillisecondsSinceEpoch(
                  totalStartTicks ~/ productsWithStartDate.length,
                );
              }

              if (productsWithEndDate.isNotEmpty) {
                final totalEndTicks = productsWithEndDate
                    .map((p) => p.endDate!.millisecondsSinceEpoch)
                    .reduce((a, b) => a + b);
                averageEndDate = DateTime.fromMillisecondsSinceEpoch(
                  totalEndTicks ~/ productsWithEndDate.length,
                );
              }

              workTypeData.add(
                WorkTypeGanttData(
                  type: category, // ←カテゴリ名
                  averageStartDate: averageStartDate,
                  averageEndDate: averageEndDate,
                  totalCount: totalCount,
                  completedCount: completedCount,
                  completionRate: completionRate,
                ),
              );
            });

            // カテゴリ名でソート
            workTypeData.sort((a, b) => a.type.compareTo(b.type));
            return workTypeData;
          })
          .handleError((error) {
            debugPrint('WorkType gantt error: $error');
            return <WorkTypeGanttData>[];
          });
    } catch (e) {
      debugPrint('WorkType gantt service error: $e');
      return Stream.value(<WorkTypeGanttData>[]);
    }
  }

  // 製品の進捗状態を更新
  Future<void> updateProductStatus(String productId, String newStatus) async {
    try {
      Map<String, dynamic> updateData = {'status': newStatus};

      // 作業開始時
      if (newStatus == 'in_progress') {
        updateData['startDate'] = FieldValue.serverTimestamp();
      }
      // 完了時
      else if (newStatus == 'completed') {
        updateData['endDate'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection('products').doc(productId).update(updateData);
    } catch (e) {
      debugPrint('Update product status error: $e');
      rethrow;
    }
  }

  // 工種ごとの進捗率を取得
  Stream<Map<String, Map<String, int>>> getProgressSummaryStream() {
    try {
      return _firestore
          .collection('products')
          .snapshots()
          .map((snapshot) {
            Map<String, Map<String, int>> summary = {};

            for (var doc in snapshot.docs) {
              Product product = Product.fromFirestore(doc);

              if (!summary.containsKey(product.type)) {
                summary[product.type] = {
                  'total': 0,
                  'completed': 0,
                  'in_progress': 0,
                  'not_started': 0,
                };
              }

              summary[product.type]!['total'] =
                  (summary[product.type]!['total'] ?? 0) + 1;
              summary[product.type]![product.status] =
                  (summary[product.type]![product.status] ?? 0) + 1;
            }

            return summary;
          })
          .handleError((error) {
            debugPrint('Firestore summary error: $error');
            return <String, Map<String, int>>{};
          });
    } catch (e) {
      debugPrint('Firebase summary service error: $e');
      return Stream.value(<String, Map<String, int>>{});
    }
  }

  // サンプルデータを追加（開発用）
  Future<void> addSampleData() async {
    try {
      // サンプルデータの追加は行わないように変更
    } catch (e) {
      debugPrint('addSampleData error: $e');
      rethrow;
    }
  }

  // サンプル部材データを追加（開発用）
  Future<void> addSampleParts(String productId) async {
    try {
      final partsRef = _firestore
          .collection('products')
          .doc(productId)
          .collection('parts');
      final sampleParts = [
        {'partName': 'コア組立', 'floor': '2F'},
        {'partName': 'コア溶接', 'floor': '2F'},
        {'partName': 'コアＵＴ', 'floor': '2F'},
        {'partName': '仕口組立', 'floor': '2F'},
        {'partName': '仕口検品', 'floor': '2F'},
        {'partName': '仕口溶接', 'floor': '2F'},
        {'partName': '仕口仕上げ', 'floor': '2F'},
        {'partName': '仕口ＵＴ', 'floor': '2F'},
      ];
      for (final part in sampleParts) {
        await partsRef.add(part);
      }
    } catch (e) {
      debugPrint('addSampleParts error: $e');
      rethrow;
    }
  }

  Future<void> updateProductProgress({
    required String productId,
    required String status,
    required DateTime date,
  }) async {
    final data = {'status': status, 'updatedAt': Timestamp.fromDate(date)};
    await _firestore.collection('products').doc(productId).update(data);
  }

  // 製品ID＋工種名ごとの進捗データを保存
  // 旧API（progress サブコレクションへの書き込み）は今後使用しない方針。
  // upsertDaily を利用するため、このメソッドは呼び出し元が存在する場合でも使わず、
  // バルク入力などでは ProcessProgressDailyRepository.upsertDaily を直接呼ぶよう統一する。
  // TODO: 互換目的で残すが、呼び出し箇所がなければ削除検討。

  // 製品ID＋工種名ごとの進捗データを取得
  Future<Map<String, dynamic>?> getProductProcessProgress({
    required String productId,
    required String processName,
  }) async {
    try {
      final doc = await _firestore
          .collection('products')
          .doc(productId)
          .collection('progress')
          .doc(processName)
          .get();
      if (doc.exists) {
        return doc.data();
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('getProductProcessProgress error: $e');
      return null;
    }
  }

  // 製品IDごとの全工種進捗データを取得（Map<工種名, Map>）
  Future<Map<String, Map<String, dynamic>>> getAllProductProgress(
    String productId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .doc(productId)
          .collection('progress')
          .get();
      final result = <String, Map<String, dynamic>>{};
      for (var doc in snapshot.docs) {
        result[doc.id] = doc.data();
      }
      return result;
    } catch (e) {
      debugPrint('getAllProductProgress error: $e');
      return {};
    }
  }

  // 製品IDの部材サブコレクションを取得
  Future<QuerySnapshot<Map<String, dynamic>>> getPartsSnapshot(
    String productId,
  ) async {
    return await _firestore
        .collection('products')
        .doc(productId)
        .collection('parts')
        .get();
  }

  // 製品IDの部材リストを取得
  Future<List<Map<String, dynamic>>> fetchParts(String productId) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .doc(productId)
          .collection('parts')
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('fetchParts error: $e');
      return [];
    }
  }

  // CSVから製品データを追加または更新
  Future<void> addOrUpdateProductFromCsv({
    required String id,
    required String name,
    required String type,
    required String area,
    required String size,
    required int length,
    required int quantity,
    required double totalWeight,
  }) async {
    try {
      final docRef = _firestore.collection('products').doc(id);
      await docRef.set({
        'id': id,
        'name': name,
        'type': type,
        'area': area,
        'partName': size, // 寸法
        'length': length,
        'quantity': quantity,
        'totalWeight': totalWeight,
        'processCategory': type, // 必要に応じて調整
        'status': 'not_started',
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('addOrUpdateProductFromCsv error: $e');
      rethrow;
    }
  }
}
