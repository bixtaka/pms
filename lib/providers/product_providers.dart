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
      String _blockOf(Product p) {
        if (p.area.isNotEmpty) return p.area;
        // TODO: area が空の場合の暫定フォールバック
        return p.storyOrSet;
      }

      return products.where((p) {
        final block = _blockOf(p);
        if (filter.selectedBlocks.isNotEmpty &&
            !filter.selectedBlocks.contains(block)) {
          return false;
        }
        if (filter.selectedSegments.isNotEmpty &&
            !filter.selectedSegments.contains(p.grid)) {
          return false;
        }
        if (filter.selectedFloors.isNotEmpty &&
            !filter.selectedFloors.contains(p.floor)) {
          return false;
        }
        if (filter.selectedMemberTypes.isNotEmpty &&
            !filter.selectedMemberTypes.contains(p.memberType)) {
          return false;
        }
        if (filter.selectedSections.isNotEmpty &&
            !filter.selectedSections.contains(p.section)) {
          return false;
        }
        if (filter.status != null &&
            filter.status!.isNotEmpty &&
            p.overallStatus != filter.status) {
          return false;
        }
        if (filter.keyword.isNotEmpty) {
          final kw = filter.keyword.toLowerCase();
          final code = p.productCode.toLowerCase();
          final name = p.name.toLowerCase();
          final remarks = (p.remarks).toLowerCase();
          if (!(code.contains(kw) || name.contains(kw) || remarks.contains(kw))) {
            return false;
          }
        }
        if (filter.incompleteOnly &&
            (p.overallStatus == 'completed' || p.overallStatus == 'completed_all')) {
          return false;
        }
        return true;
      }).toList();
    },
    orElse: () => <Product>[],
  );
});
