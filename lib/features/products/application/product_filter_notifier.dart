import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'product_filter_state.dart';

/// 製品一覧のフィルタ状態を管理する StateNotifier
class ProductFilterNotifier extends StateNotifier<ProductFilterState> {
  ProductFilterNotifier() : super(const ProductFilterState());

  void setMemberType(String? value) {
    state = state.copyWith(memberType: value?.isEmpty == true ? null : value);
  }

  void setStoryOrSet(String? value) {
    state = state.copyWith(storyOrSet: value?.isEmpty == true ? null : value);
  }

  void setGrid(String? value) {
    state = state.copyWith(grid: value?.isEmpty == true ? null : value);
  }

  void setStatus(String? value) {
    state = state.copyWith(status: value?.isEmpty == true ? null : value);
  }

  void setKeyword(String value) {
    state = state.copyWith(keyword: value);
  }

  void clearAll() {
    state = const ProductFilterState();
  }
}
