import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/product.dart';

/// 製品関連の CRUD / ストリーム
class ProductRepository {
  CollectionReference<Map<String, dynamic>> _col(String projectId) =>
      FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('products');

  Stream<List<Product>> streamByProject(String projectId) => _col(projectId)
      .orderBy('productCode')
      .snapshots()
      .map(
        (s) => s.docs.map((d) => Product.fromJson(d.data(), d.id)).toList(),
      );

  Stream<Product> streamOne(String projectId, String productId) =>
      _col(projectId).doc(productId).snapshots().map(
            (d) => Product.fromJson(d.data() ?? {}, d.id),
          );

  Future<void> add(Product product) =>
      _col(product.projectId).doc(product.id).set(product.toJson());

  Future<void> update(Product product) =>
      _col(product.projectId).doc(product.id).update(product.toJson());

  Future<void> delete(String projectId, String productId) async {
    final ref = _col(projectId).doc(productId);
    final progress = await ref.collection('processProgress').get();
    for (final doc in progress.docs) {
      await doc.reference.delete();
    }
    await ref.delete();
  }
}
