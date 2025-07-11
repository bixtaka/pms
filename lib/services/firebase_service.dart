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
              final category =
                  (doc.data() as Map<String, dynamic>)['processCategory'] ??
                  '未分類';
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
        {
          'name': '柱-001',
          'type': '柱',
          'processCategory': '一次加工',
          'status': 'completed',
          'startDate': Timestamp.fromDate(
            startDate.add(const Duration(days: 1)),
          ),
          'endDate': Timestamp.fromDate(startDate.add(const Duration(days: 3))),
        },
        {
          'name': '柱-002',
          'type': '柱',
          'processCategory': '一次加工',
          'status': 'in_progress',
          'startDate': Timestamp.fromDate(
            startDate.add(const Duration(days: 4)),
          ),
          'endDate': null,
        },
        {
          'name': '柱-003',
          'type': '柱',
          'processCategory': '一次加工',
          'status': 'not_started',
          'startDate': null,
          'endDate': null,
        },
        {
          'name': '大梁-001',
          'type': '大梁',
          'processCategory': '組立',
          'status': 'completed',
          'startDate': Timestamp.fromDate(
            startDate.add(const Duration(days: 2)),
          ),
          'endDate': Timestamp.fromDate(startDate.add(const Duration(days: 5))),
        },
        {
          'name': '大梁-002',
          'type': '大梁',
          'processCategory': '組立',
          'status': 'in_progress',
          'startDate': Timestamp.fromDate(
            startDate.add(const Duration(days: 6)),
          ),
          'endDate': null,
        },
        {
          'name': '小梁-001',
          'type': '小梁',
          'processCategory': '検査',
          'status': 'completed',
          'startDate': Timestamp.fromDate(
            startDate.add(const Duration(days: 3)),
          ),
          'endDate': Timestamp.fromDate(startDate.add(const Duration(days: 4))),
        },
        {
          'name': '小梁-002',
          'type': '小梁',
          'processCategory': '検査',
          'status': 'not_started',
          'startDate': null,
          'endDate': null,
        },
        {
          'name': '小梁-003',
          'type': '小梁',
          'processCategory': '検査',
          'status': 'in_progress',
          'startDate': Timestamp.fromDate(
            startDate.add(const Duration(days: 7)),
          ),
          'endDate': null,
        },
        {
          'name': '間柱-001',
          'type': '間柱',
          'processCategory': '一次加工',
          'status': 'completed',
          'startDate': Timestamp.fromDate(
            startDate.add(const Duration(days: 5)),
          ),
          'endDate': Timestamp.fromDate(startDate.add(const Duration(days: 6))),
        },
        {
          'name': '間柱-002',
          'type': '間柱',
          'processCategory': '一次加工',
          'status': 'not_started',
          'startDate': null,
          'endDate': null,
        },
      ];

      for (var productData in sampleProducts) {
        await _firestore.collection('products').add(productData);
      }
    } catch (e) {
      print('Add sample data error: $e');
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
}
