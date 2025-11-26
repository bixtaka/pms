import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/products/data/product_repository.dart';
import '../features/products/application/product_filter_state.dart';
import '../features/products/application/product_filter_notifier.dart';
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

// フィルタ状態を管理する Notifier
final productFilterProvider =
    StateNotifierProvider<ProductFilterNotifier, ProductFilterState>((ref) {
  return ProductFilterNotifier();
});

// フィルタ適用後の製品一覧（クライアント側でフィルタ）
final filteredProductsProvider =
    Provider.family<List<Product>, String>((ref, projectId) {
  final productsAsync = ref.watch(productsByProjectProvider(projectId));
  final filter = ref.watch(productFilterProvider);

  return productsAsync.maybeWhen(
    data: (products) {
      var list = List<Product>.from(products);

      if (filter.memberType != null && filter.memberType!.isNotEmpty) {
        list = list
            .where((p) => p.memberType == filter.memberType)
            .toList();
      }
      if (filter.storyOrSet != null && filter.storyOrSet!.isNotEmpty) {
        list = list
            .where((p) => p.storyOrSet == filter.storyOrSet)
            .toList();
      }
      if (filter.grid != null && filter.grid!.isNotEmpty) {
        list = list.where((p) => p.grid == filter.grid).toList();
      }
      if (filter.status != null && filter.status!.isNotEmpty) {
        list = list
            .where((p) => p.overallStatus == filter.status)
            .toList();
      }
      if (filter.keyword.isNotEmpty) {
        final kw = filter.keyword.toLowerCase();
        list = list.where((p) {
          final code = p.productCode.toLowerCase();
          final name = p.name.toLowerCase();
          final remarks = (p.remarks).toLowerCase();
          return code.contains(kw) ||
              name.contains(kw) ||
              remarks.contains(kw);
        }).toList();
      }
      return list;
    },
    orElse: () => <Product>[],
  );
});
