import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'product_filter_state.dart';

/// 製品フィルタ StateNotifier（複数選択トグル対応）
class ProductFilterNotifier extends StateNotifier<ProductFilterState> {
  ProductFilterNotifier() : super(const ProductFilterState());

  void toggleBlock(String value) {
    final next = _toggle(state.selectedBlocks, value);
    state = state.copyWith(selectedBlocks: next);
  }

  void setBlocks(Set<String> blocks) {
    state = state.copyWith(selectedBlocks: blocks);
  }

  void toggleSegment(String value) {
    final next = _toggle(state.selectedSegments, value);
    state = state.copyWith(selectedSegments: next);
  }

  void toggleFloor(String value) {
    final next = _toggle(state.selectedFloors, value);
    state = state.copyWith(selectedFloors: next);
  }

  void toggleMemberType(String value) {
    final next = _toggle(state.selectedMemberTypes, value);
    state = state.copyWith(selectedMemberTypes: next);
  }

  void toggleSection(String value) {
    final next = _toggle(state.selectedSections, value);
    state = state.copyWith(selectedSections: next);
  }

  void setSegments(Set<String> segments) {
    state = state.copyWith(selectedSegments: segments);
  }

  void setFloors(Set<String> floors) {
    state = state.copyWith(selectedFloors: floors);
  }

  void setSections(Set<String> sections) {
    state = state.copyWith(selectedSections: sections);
  }

  void setIncompleteOnly(bool value) {
    state = state.copyWith(incompleteOnly: value);
  }

  void setKeyword(String value) {
    state = state.copyWith(keyword: value);
  }

  /// 既存単一選択UI互換：工区を単一値で上書き
  void setStoryOrSet(String? value) {
    final normalized = value?.isEmpty == true ? null : value;
    state = state.copyWith(
      selectedBlocks: normalized == null ? <String>{} : {normalized},
    );
  }

  /// 既存単一選択UI互換：節を単一値で上書き
  void setGrid(String? value) {
    final normalized = value?.isEmpty == true ? null : value;
    state = state.copyWith(
      selectedSegments: normalized == null ? <String>{} : {normalized},
    );
  }

  /// 既存単一選択UI互換：部材種別を単一値で上書き
  void setMemberType(String? value) {
    final normalized = value?.isEmpty == true ? null : value;
    state = state.copyWith(
      selectedMemberTypes: normalized == null ? <String>{} : {normalized},
    );
  }

  void setStatus(String? value) {
    state = state.copyWith(status: value ?? '');
  }

  void clearAll() {
    state = const ProductFilterState();
  }

  Set<String> _toggle(Set<String> source, String value) {
    if (source.contains(value)) {
      final next = Set<String>.from(source)..remove(value);
      return next;
    }
    return Set<String>.from(source)..add(value);
  }
}
