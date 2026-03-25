// photo_item.dart
// 撮影項目のモデルクラス
// Firestore との変換メソッドを含む

import 'package:cloud_firestore/cloud_firestore.dart';

/// 撮影項目のデータクラス
class PhotoItem {
  /// Firestore ドキュメント ID
  final String id;
  
  /// 親カテゴリー（例：一次加工、組立）
  final String category;
  
  /// 子項目名（例：切断、開先加工）
  final String name;
  
  /// 撮影ステータス ('pending' | 'completed')
  String status;
  
  /// 画像の保存パス（Webテスト時は空）
  /// ※非推奨: 複数枚対応のため `photos` を使用すること
  String? imagePath;
  
  /// 写真リスト（URLまたはパスのリスト）
  final List<String> photos;
  
  /// 備考
  String? memo;
  
  /// 黒板の作業内容（編集可能なフリースペース等のテキスト）
  String? contentText;
  
  /// 黒板のレイアウトタイプ（'type2' | 'type3'）
  String blackboardType;
  
  /// 作成日時
  final DateTime createdAt;

  PhotoItem({
    required this.id,
    required this.category,
    required this.name,
    this.status = 'pending',
    this.imagePath,
    List<String>? photos,
    this.memo,
    this.contentText,
    this.blackboardType = 'type2',
    DateTime? createdAt,
  }) : photos = photos ?? [],
       createdAt = createdAt ?? DateTime.now();

  /// 撮影済みかどうか（写真が1枚以上あるか）
  bool get isCompleted => status == 'completed' || photos.isNotEmpty;

  /// Firestore ドキュメントから PhotoItem を作成
  factory PhotoItem.fromFirestore(String id, Map<String, dynamic> data) {
    // photosフィールドがあればそれを使用、なければimagePathから移行
    List<String> photos = (data['photos'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [];
    String? imagePath = data['imagePath'] as String?;

    // 互換性維持: photosが空でimagePathがある場合、photosに追加
    if (photos.isEmpty && imagePath != null && imagePath.isNotEmpty) {
      photos = [imagePath];
    }

    return PhotoItem(
      id: id,
      category: data['category'] as String? ?? '',
      name: data['name'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      imagePath: imagePath, // 念のため保持
      photos: photos,
      memo: data['memo'] as String?,
      contentText: data['contentText'] as String?,
      blackboardType: data['blackboardType'] as String? ?? 'type2',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// PhotoItem を Firestore 用 Map に変換
  Map<String, dynamic> toFirestore() {
    return {
      'category': category,
      'name': name,
      'status': status,
      'imagePath': imagePath, // 互換性のため残すが、更新時はphotosの先頭を入れるなどの対応が可能
      'photos': photos,
      'memo': memo,
      'contentText': contentText,
      'blackboardType': blackboardType,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// コピーを作成
  PhotoItem copyWith({
    String? id,
    String? category,
    String? name,
    String? status,
    String? imagePath,
    List<String>? photos,
    String? memo,
    String? contentText,
    String? blackboardType,
    DateTime? createdAt,
  }) {
    return PhotoItem(
      id: id ?? this.id,
      category: category ?? this.category,
      name: name ?? this.name,
      status: status ?? this.status,
      imagePath: imagePath ?? this.imagePath,
      photos: photos ?? this.photos,
      memo: memo ?? this.memo,
      contentText: contentText ?? this.contentText,
      blackboardType: blackboardType ?? this.blackboardType,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// カテゴリー（工程）のデータクラス
class SiteCategory {
  final String id;
  final String name;
  final DateTime createdAt;

  SiteCategory({
    required this.id,
    required this.name,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory SiteCategory.fromFirestore(String id, Map<String, dynamic> data) {
    return SiteCategory(
      id: id,
      name: data['name'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
