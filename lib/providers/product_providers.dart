import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/products/data/product_repository.dart';
import '../features/products/application/product_filter_state.dart';
import '../features/products/application/product_filter_notifier.dart';
import '../features/shipping/application/shipping_table_notifier.dart';
import '../features/shipping/domain/shipping_row.dart';
import '../models/product.dart';

bool _isColumnType(String memberType) {
  // TODO: COLUMN_XX などの派生コードが増えたらここに追加する
  return memberType == 'COLUMN';
}

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
  final shippingLookup = ref.watch(shippingLookupProvider);

  return productsAsync.maybeWhen(
    data: (products) {
      String blockOf(Product p, ShippingRow? shippingRow) {
        if (shippingRow != null && shippingRow.kouku.isNotEmpty) {
          return shippingRow.kouku;
        }
        if (p.area.isNotEmpty) return p.area;
        // TODO: area が空の場合の暫定フォールバック
        return p.storyOrSet;
      }

      String sectionOf(Product p, ShippingRow? shippingRow) {
        if (shippingRow != null && shippingRow.sectionSize.isNotEmpty) {
          return shippingRow.sectionSize;
        }
        return p.section;
      }

      String? setsuOf(Product p, ShippingRow? shippingRow) {
        if (shippingRow != null && (shippingRow.setsu?.isNotEmpty ?? false)) {
          return shippingRow.setsu;
        }
        if (p.grid.isNotEmpty) return p.grid;
        if (p.storyOrSet.isNotEmpty) return p.storyOrSet;
        return null;
      }

      String? floorOf(Product p, ShippingRow? shippingRow) {
        if (shippingRow?.floor != null) return shippingRow!.floor!.toString();
        if (p.floor.isNotEmpty) return p.floor;
        if (p.storyOrSet.isNotEmpty) return p.storyOrSet;
        return null;
      }

      ShippingRow? shippingFor(Product p) {
        final code = p.productCode.trim().toUpperCase();
        if (code.isEmpty) return null;
        return shippingLookup[code];
      }

      return products.where((p) {
        final shippingRow = shippingFor(p);
        final memberType = p.memberType;
        final isColumn = _isColumnType(memberType);
        final block = blockOf(p, shippingRow);

        if (filter.selectedMemberTypes.isNotEmpty &&
            !filter.selectedMemberTypes.contains(memberType)) {
          final matchesShippingKind =
              shippingRow != null && filter.selectedMemberTypes.contains(shippingRow.kind);
          if (!matchesShippingKind) {
            return false;
          }
        }

        if (filter.selectedBlocks.isNotEmpty &&
            !filter.selectedBlocks.contains(block)) {
          return false;
        }

        final sectionValue = sectionOf(p, shippingRow);

        if (filter.selectedSections.isNotEmpty &&
            !filter.selectedSections.contains(sectionValue)) {
          return false;
        }

        if (isColumn) {
          final setsu = setsuOf(p, shippingRow);
          if (filter.selectedSegments.isNotEmpty &&
              !filter.selectedSegments.contains(setsu ?? '')) {
            return false;
          }
        } else {
          final floor = floorOf(p, shippingRow);
          if (filter.selectedFloors.isNotEmpty &&
              !filter.selectedFloors.contains(floor ?? '')) {
            return false;
          }
        }

        if (filter.status != null &&
            filter.status!.isNotEmpty &&
            p.overallStatus != filter.status) {
          return false;
        }
        if (filter.keyword.isNotEmpty) {
          final kw = filter.keyword.toLowerCase();
          final candidates = <String>[
            p.productCode,
            p.name,
            p.remarks,
            p.section,
            p.area,
            p.storyOrSet,
            p.grid,
            if (shippingRow != null) ...[
              shippingRow.productCode,
              shippingRow.kouku,
              shippingRow.kind,
              shippingRow.sectionSize,
              if (shippingRow.setsu != null) shippingRow.setsu!,
              if (shippingRow.floor != null) shippingRow.floor!.toString(),
              shippingRow.lengthMm.toString(),
            ],
          ].map((s) => s.toLowerCase()).toList();
          if (!candidates.any((c) => c.contains(kw))) {
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

final shippingRowsForProjectProvider =
    Provider.family<List<ShippingRow>, String>((ref, projectId) {
  final shippingLookup = ref.watch(shippingLookupProvider);
  final productsAsync = ref.watch(productsByProjectProvider(projectId));
  final products = productsAsync.maybeWhen(
    data: (list) => list,
    orElse: () => const <Product>[],
  );
  if (shippingLookup.isEmpty || products.isEmpty) return const <ShippingRow>[];

  final codes = products.map((p) => p.productCode.trim().toUpperCase()).toSet();
  return shippingLookup.entries
      .where((entry) => codes.contains(entry.key))
      .map((entry) => entry.value)
      .toList();
});

final shippingRowMapForProjectProvider =
    Provider.family<Map<String, ShippingRow>, String>((ref, projectId) {
  final rows = ref.watch(shippingRowsForProjectProvider(projectId));
  final map = <String, ShippingRow>{};
  for (final row in rows) {
    final key = row.productCode.trim().toUpperCase();
    if (key.isEmpty) continue;
    map[key] = row;
  }
  return map;
});
