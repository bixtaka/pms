part of '../gantt_screen.dart';

@immutable
class InspectionFilterState {
  final Set<String> selectedKoukus;
  final String? selectedKind;
  final int? selectedFloor;
  final String? selectedSetsu;
  final String? selectedProcessStepId;
  final String sectionQuery;
  final int? lengthMin;
  final int? lengthMax;
  final String productCodeQuery;

  const InspectionFilterState({
    this.selectedKoukus = const <String>{},
    this.selectedKind,
    this.selectedFloor,
    this.selectedSetsu,
    this.selectedProcessStepId,
    this.sectionQuery = '',
    this.lengthMin,
    this.lengthMax,
    this.productCodeQuery = '',
  });

  InspectionFilterState copyWith({
    Set<String>? selectedKoukus,
    String? selectedKind,
    int? selectedFloor,
    String? selectedSetsu,
    String? selectedProcessStepId,
    String? sectionQuery,
    int? lengthMin,
    int? lengthMax,
    String? productCodeQuery,
    bool clearFloor = false,
    bool clearSetsu = false,
    bool clearProcessStep = false,
    bool clearKouku = false,
  }) {
    return InspectionFilterState(
      selectedKoukus: Set<String>.unmodifiable(
        clearKouku ? <String>{} : (selectedKoukus ?? this.selectedKoukus),
      ),
      selectedKind: selectedKind ?? this.selectedKind,
      selectedFloor: clearFloor ? null : selectedFloor ?? this.selectedFloor,
      selectedSetsu: clearSetsu ? null : selectedSetsu ?? this.selectedSetsu,
      selectedProcessStepId:
          clearProcessStep ? null : selectedProcessStepId ?? this.selectedProcessStepId,
      sectionQuery: sectionQuery ?? this.sectionQuery,
      lengthMin: lengthMin ?? this.lengthMin,
      lengthMax: lengthMax ?? this.lengthMax,
      productCodeQuery: productCodeQuery ?? this.productCodeQuery,
    );
  }
}

class InspectionFilterNotifier extends StateNotifier<InspectionFilterState> {
  InspectionFilterNotifier() : super(const InspectionFilterState());

  void toggleKouku(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return;
    final next = Set<String>.from(state.selectedKoukus);
    if (next.contains(normalized)) {
      next.remove(normalized);
    } else {
      next.add(normalized);
    }
    state = state.copyWith(
      selectedKoukus: next,
      clearFloor: true,
      clearSetsu: true,
    );
  }

  void clearKouku() {
    state = state.copyWith(
      selectedKoukus: <String>{},
      clearFloor: true,
      clearSetsu: true,
    );
  }

  bool isKoukuSelected(String value) => state.selectedKoukus.contains(value);

  bool get isKoukuAllSelected => state.selectedKoukus.isEmpty;

  void setKind(String? value) {
    final normalized = value?.isEmpty == true ? null : value;
    final isColumn = normalized == '柱';
    final isBeam = normalized == '大梁' || normalized == '小梁' || normalized == '間柱';
    state = state.copyWith(
      selectedKind: normalized,
      clearFloor: !isBeam,
      clearSetsu: !isColumn,
    );
  }

  void setFloor(int? value) {
    state = state.copyWith(selectedFloor: value);
  }

  void setSetsu(String? value) {
    state = state.copyWith(selectedSetsu: value?.isEmpty == true ? null : value);
  }

  void setSectionQuery(String value) {
    state = state.copyWith(sectionQuery: value);
  }

  void setProductCodeQuery(String value) {
    state = state.copyWith(productCodeQuery: value);
  }

  void setLengthMin(int? value) {
    state = state.copyWith(lengthMin: value);
  }

  void setLengthMax(int? value) {
    state = state.copyWith(lengthMax: value);
  }

  void setProcessStep(String? stepId) {
    state = state.copyWith(
      selectedProcessStepId: stepId,
      clearProcessStep: stepId == null,
    );
  }

  void clearAll() {
    state = const InspectionFilterState();
  }
}

@immutable
class InspectionProductEntry {
  final ShippingRow shippingRow;
  final Product? product;

  const InspectionProductEntry({
    required this.shippingRow,
    required this.product,
  });
}

final inspectionFilterProvider =
    StateNotifierProvider<InspectionFilterNotifier, InspectionFilterState>(
        (ref) {
  return InspectionFilterNotifier();
});

List<T> _sortedList<T extends Comparable>(Iterable<T> values) {
  final list = values.toSet().toList()..sort();
  return list;
}

final koukuCandidatesProvider = Provider<List<String>>((ref) {
  final rows = ref.watch(shippingRowsProvider);
  return _sortedList(
    rows.map((r) => r.kouku.trim()).where((v) => v.isNotEmpty),
  );
});

final kindCandidatesProvider = Provider<List<String>>((ref) {
  final rows = ref.watch(shippingRowsProvider);
  return _sortedList(
    rows.map((r) => r.kind.trim()).where((v) => v.isNotEmpty),
  );
});

final floorCandidatesProvider = Provider<List<int>>((ref) {
  final rows = ref.watch(shippingRowsProvider);
  final filter = ref.watch(inspectionFilterProvider);
  final kind = filter.selectedKind;
  final isBeam = kind == '大梁' || kind == '小梁' || kind == '間柱';
  if (!isBeam) return const <int>[];
  final floors =
      rows.map((r) => r.floor).whereType<int>().toSet().toList()..sort();
  return floors;
});

final setsuCandidatesProvider = Provider<List<String>>((ref) {
  final rows = ref.watch(shippingRowsProvider);
  final filter = ref.watch(inspectionFilterProvider);
  if (filter.selectedKind != '柱') return const <String>[];
  return _sortedList(
    rows.map((r) => r.setsu ?? '').where((v) => v.isNotEmpty),
  );
});

final sectionCandidatesProvider = Provider<List<String>>((ref) {
  final rows = ref.watch(shippingRowsProvider);
  final filter = ref.watch(inspectionFilterProvider);
  final query = filter.sectionQuery.trim().toLowerCase();
  final all = _sortedList(
    rows.map((r) => r.sectionSize.trim()).where((v) => v.isNotEmpty),
  );
  if (query.isEmpty) {
    const limit = 50;
    return all.take(limit).toList();
  }
  return all.where((s) => s.toLowerCase().contains(query)).toList();
});

final inspectionFilteredShippingRowsProvider = Provider<List<ShippingRow>>((ref) {
  final rows = ref.watch(shippingRowsProvider);
  final filter = ref.watch(inspectionFilterProvider);

  return rows.where((row) {
    if (filter.selectedKoukus.isNotEmpty &&
        !filter.selectedKoukus.contains(row.kouku.trim())) {
      return false;
    }
    if (filter.selectedKind != null &&
        filter.selectedKind!.isNotEmpty &&
        row.kind.trim().toLowerCase() != filter.selectedKind!.trim().toLowerCase()) {
      return false;
    }
    if (filter.selectedFloor != null) {
      if (row.floor == null || row.floor != filter.selectedFloor) return false;
    }
    if (filter.selectedSetsu != null &&
        filter.selectedSetsu!.isNotEmpty &&
        (row.setsu ?? '').toLowerCase() != filter.selectedSetsu!.toLowerCase()) {
      return false;
    }
    if (filter.sectionQuery.trim().isNotEmpty &&
        !row.sectionSize.toLowerCase().contains(filter.sectionQuery.trim().toLowerCase())) {
      return false;
    }
    if (filter.productCodeQuery.trim().isNotEmpty &&
        !row.productCode
            .toLowerCase()
            .contains(filter.productCodeQuery.trim().toLowerCase())) {
      return false;
    }
    if (filter.lengthMin != null && row.lengthMm < filter.lengthMin!) return false;
    if (filter.lengthMax != null && row.lengthMm > filter.lengthMax!) return false;
    return true;
  }).toList();
});

final inspectionFilteredEntriesProvider =
    Provider.family<List<InspectionProductEntry>, String>((ref, projectId) {
  final rows = ref.watch(inspectionFilteredShippingRowsProvider);
  final productsAsync = ref.watch(productsByProjectProvider(projectId));
  final products = productsAsync.asData?.value ?? const <Product>[];
  final productMap = <String, Product>{};
  for (final p in products) {
    final code = p.productCode.trim().toUpperCase();
    if (code.isEmpty) continue;
    productMap.putIfAbsent(code, () => p);
  }
  return [
    for (final row in rows)
      InspectionProductEntry(
        shippingRow: row,
        product: productMap[row.productCode.trim().toUpperCase()],
      ),
  ];
});
