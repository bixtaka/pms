import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/products/data/product_repository.dart';
import '../models/product.dart';

// リポジトリのプロバイダ
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

// プロジェクトIDごとの製品一覧
final productsByProjectProvider =
    StreamProvider.family<List<Product>, String>((ref, projectId) {
  final repo = ref.watch(productRepositoryProvider);
  return repo.streamByProject(projectId);
});
