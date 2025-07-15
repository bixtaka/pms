import 'package:cloud_firestore/cloud_firestore.dart';
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
            print('Firestore error: $error');
            return <Product>[];
          });
    } catch (e) {
      print('Firebase service error: $e');
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
            print('WorkType gantt error: $error');
            return <WorkTypeGanttData>[];
          });
    } catch (e) {
      print('WorkType gantt service error: $e');
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
      print('Update product status error: $e');
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
            print('Firestore summary error: $error');
            return <String, Map<String, int>>{};
          });
    } catch (e) {
      print('Firebase summary service error: $e');
      return Stream.value(<String, Map<String, int>>{});
    }
  }

  // サンプルデータを追加（開発用）
  Future<void> addSampleData() async {
    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day);

      List<Map<String, dynamic>> sampleProducts = [
        // 柱
        {
          'id': '1C-Y1X1',
          'name': '1C-Y1X1',
          'type': '柱',
          'processCategory': '柱',
          'status': 'not_started',
          'startDate': null,
          'endDate': null,
          'floor': '2F', // 追加
        },
        {
          'id': '1C-Y1X2',
          'name': '1C-Y1X2',
          'type': '柱',
          'processCategory': '柱',
          'status': 'not_started',
          'startDate': null,
          'endDate': null,
          'floor': '2F', // 追加
        },
        {
          'id': '1C-Y1X3',
          'name': '1C-Y1X3',
          'type': '柱',
          'processCategory': '柱',
          'status': 'not_started',
          'startDate': null,
          'endDate': null,
          'floor': '2F', // 追加
        },
        {
          'id': '1C-Y2X1',
          'name': '1C-Y2X1',
          'type': '柱',
          'processCategory': '柱',
          'status': 'not_started',
          'startDate': null,
          'endDate': null,
          'floor': '3F', // 追加
        },
        {
          'id': '1C-Y2X2',
          'name': '1C-Y2X2',
          'type': '柱',
          'processCategory': '柱',
          'status': 'not_started',
          'startDate': null,
          'endDate': null,
          'floor': '3F', // 追加
        },
        {
          'id': '1C-Y2X3',
          'name': '1C-Y2X3',
          'type': '柱',
          'processCategory': '柱',
          'status': 'not_started',
          'startDate': null,
          'endDate': null,
          'floor': '3F', // 追加
        },
        // 大梁
        {
          'id': '2G-1',
          'name': '2G-1',
          'type': '大梁',
          'processCategory': '大梁',
          'status': 'not_started',
          'startDate': null,
          'endDate': null,
          'floor': '2F', // 追加
        },
        {
          'id': '2G-2',
          'name': '2G-2',
          'type': '大梁',
          'processCategory': '大梁',
          'status': 'not_started',
          'startDate': null,
          'endDate': null,
          'floor': '2F', // 追加
        },
        {
          'id': '2G-3',
          'name': '2G-3',
          'type': '大梁',
          'processCategory': '大梁',
          'status': 'not_started',
          'startDate': null,
          'endDate': null,
          'floor': '3F', // 追加
        },
        {
          'id': '2G-4',
          'name': '2G-4',
          'type': '大梁',
          'processCategory': '大梁',
          'status': 'not_started',
          'startDate': null,
          'endDate': null,
          'floor': '3F', // 追加
        },
        {
          'id': '3G-1',
          'name': '3G-1',
          'type': '大梁',
          'processCategory': '大梁',
          'status': 'not_started',
          'startDate': null,
          'endDate': null,
          'floor': '4F', // 追加
        },
        {
          'id': '3G-2',
          'name': '3G-2',
          'type': '大梁',
          'processCategory': '大梁',
          'status': 'not_started',
          'startDate': null,
          'endDate': null,
          'floor': '4F', // 追加
        },
        {
          'id': '3G-3',
          'name': '3G-3',
          'type': '大梁',
          'processCategory': '大梁',
          'status': 'not_started',
          'startDate': null,
          'endDate': null,
          'floor': '5F', // 追加
        },
        {
          'id': '3G-4',
          'name': '3G-4',
          'type': '大梁',
          'processCategory': '大梁',
          'status': 'not_started',
          'startDate': null,
          'endDate': null,
          'floor': '5F', // 追加
        },
      ];

      final productsRef = _firestore.collection('products');
      for (final data in sampleProducts) {
        // name重複チェック
        final query = await productsRef
            .where('name', isEqualTo: data['name'])
            .get();
        if (query.docs.isEmpty) {
          final doc = productsRef.doc(data['id']);
          await doc.set(data);
        }
        // 既に存在する場合はスキップ
      }
    } catch (e) {
      print('addSampleData error: $e');
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
      print('addSampleParts error: $e');
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
  Future<void> setProductProcessProgress({
    required String productId,
    required String processName,
    required String status,
    required DateTime date,
    required String person,
  }) async {
    try {
      await _firestore
          .collection('products')
          .doc(productId)
          .collection('progress')
          .doc(processName)
          .set({
            'status': status,
            'date': Timestamp.fromDate(date),
            'person': person,
          }, SetOptions(merge: true));
    } catch (e) {
      print('setProductProcessProgress error: $e');
      rethrow;
    }
  }

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
      print('getProductProcessProgress error: $e');
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
      print('getAllProductProgress error: $e');
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
      print('fetchParts error: ' + e.toString());
      return [];
    }
  }
}
