/// 製品検索用のフィルタステート（複数選択対応）
class ProductFilterState {
  /// 工区（storyOrSet）
  final Set<String> selectedBlocks;

  /// 節（grid）
  final Set<String> selectedSegments;

  /// 階（floor）
  final Set<String> selectedFloors;

  /// 部材種別
  final Set<String> selectedMemberTypes;

  /// 断面寸法（section）
  final Set<String> selectedSections;

  /// 全体進捗ステータス（既存互換用）
  final String? status;

  /// キーワード（製品コード／製品名／備考への部分一致検索）
  final String keyword;

  /// 未完了のみ
  final bool incompleteOnly;

  const ProductFilterState({
    this.selectedBlocks = const {},
    this.selectedSegments = const {},
    this.selectedFloors = const {},
    this.selectedMemberTypes = const {},
    this.selectedSections = const {},
    this.status,
    this.keyword = '',
    this.incompleteOnly = false,
  });

  ProductFilterState copyWith({
    Set<String>? selectedBlocks,
    Set<String>? selectedSegments,
    Set<String>? selectedFloors,
    Set<String>? selectedMemberTypes,
    Set<String>? selectedSections,
    String? status,
    String? keyword,
    bool? incompleteOnly,
  }) {
    return ProductFilterState(
      selectedBlocks: selectedBlocks ?? this.selectedBlocks,
      selectedSegments: selectedSegments ?? this.selectedSegments,
      selectedFloors: selectedFloors ?? this.selectedFloors,
      selectedMemberTypes: selectedMemberTypes ?? this.selectedMemberTypes,
      selectedSections: selectedSections ?? this.selectedSections,
      status: status ?? this.status,
      keyword: keyword ?? this.keyword,
      incompleteOnly: incompleteOnly ?? this.incompleteOnly,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductFilterState &&
        other.selectedBlocks == selectedBlocks &&
        other.selectedSegments == selectedSegments &&
        other.selectedFloors == selectedFloors &&
        other.selectedMemberTypes == selectedMemberTypes &&
        other.selectedSections == selectedSections &&
        other.status == status &&
        other.keyword == keyword &&
        other.incompleteOnly == incompleteOnly;
  }

  @override
  int get hashCode => Object.hash(
        selectedBlocks,
        selectedSegments,
        selectedFloors,
        selectedMemberTypes,
        selectedSections,
        status,
        keyword,
        incompleteOnly,
      );
}
