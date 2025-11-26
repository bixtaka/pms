/// 製品一覧の検索・フィルタ条件を保持する不変クラス
class ProductFilterState {
  /// 部材種別（COLUMN / GIRDER / BEAM / INTERMEDIATE など）
  final String? memberType;

  /// 節・階（1C, 2C, 2G など任意文字列で入力）
  final String? storyOrSet;

  /// 通り芯（X1Y1, X1Y2 など任意文字列で入力）
  final String? grid;

  /// 全体進捗ステータス（not_started / in_progress / completed / partial）
  final String? status;

  /// フリーテキスト検索（製品符号・名称・備考に対して部分一致）
  final String keyword;

  const ProductFilterState({
    this.memberType,
    this.storyOrSet,
    this.grid,
    this.status,
    this.keyword = '',
  });

  ProductFilterState copyWith({
    String? memberType,
    String? storyOrSet,
    String? grid,
    String? status,
    String? keyword,
  }) {
    return ProductFilterState(
      memberType: memberType ?? this.memberType,
      storyOrSet: storyOrSet ?? this.storyOrSet,
      grid: grid ?? this.grid,
      status: status ?? this.status,
      keyword: keyword ?? this.keyword,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductFilterState &&
        other.memberType == memberType &&
        other.storyOrSet == storyOrSet &&
        other.grid == grid &&
        other.status == status &&
        other.keyword == keyword;
  }

  @override
  int get hashCode =>
      Object.hash(memberType, storyOrSet, grid, status, keyword);
}
