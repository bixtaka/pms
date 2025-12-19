import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/shipping_row.dart';
import 'shipping_csv_parser.dart';

@immutable
class ShippingTableState {
  final List<ShippingRow> rows;
  final bool isLoading;
  final Object? error;

  const ShippingTableState({
    this.rows = const <ShippingRow>[],
    this.isLoading = false,
    this.error,
  });

  ShippingTableState copyWith({
    List<ShippingRow>? rows,
    bool? isLoading,
    Object? error,
    bool clearError = false,
  }) {
    return ShippingTableState(
      rows: rows ?? this.rows,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class ShippingTableNotifier extends StateNotifier<ShippingTableState> {
  ShippingTableNotifier({ShippingCsvParser? parser})
      : _parser = parser ?? const ShippingCsvParser(),
        super(const ShippingTableState());

  final ShippingCsvParser _parser;

  Future<void> loadFromCsvString(
    String csvContent, {
    bool logPreview = true,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final rows = _parser.parse(csvContent, logPreview: logPreview);
      state = state.copyWith(rows: rows, isLoading: false, clearError: true);
    } catch (e, st) {
      debugPrint('ShippingTable loadFromCsvString failed: $e');
      debugPrint('$st');
      state = state.copyWith(isLoading: false, error: e);
      rethrow;
    }
  }

  Future<void> loadFromBytes(
    Uint8List bytes, {
    bool logPreview = true,
  }) async {
    final content = utf8.decode(bytes, allowMalformed: true);
    await loadFromCsvString(content, logPreview: logPreview);
  }

  void clear() {
    state = const ShippingTableState();
  }
}

typedef ShippingLookup = Map<String, ShippingRow>;

final shippingTableProvider =
    StateNotifierProvider<ShippingTableNotifier, ShippingTableState>((ref) {
  return ShippingTableNotifier();
});

final shippingRowsProvider = Provider<List<ShippingRow>>((ref) {
  return ref.watch(shippingTableProvider).rows;
});

final shippingLookupProvider = Provider<ShippingLookup>((ref) {
  final rows = ref.watch(shippingRowsProvider);
  final map = <String, ShippingRow>{};
  for (final row in rows) {
    final code = row.productCode.trim().toUpperCase();
    if (code.isEmpty) continue;
    map.putIfAbsent(code, () => row);
  }
  return map;
});
