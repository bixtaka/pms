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
  String? imagePath;
  
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
    this.memo,
    this.contentText,
    this.blackboardType = 'type2',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 撮影済みかどうか
  bool get isCompleted => status == 'completed';

  /// Firestore ドキュメントから PhotoItem を作成
  /// 
  /// [id] ドキュメント ID
  /// [data] ドキュメントデータ
  factory PhotoItem.fromFirestore(String id, Map<String, dynamic> data) {
    return PhotoItem(
      id: id,
      category: data['category'] as String? ?? '',
      name: data['name'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      imagePath: data['imagePath'] as String?,
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
      'imagePath': imagePath,
      'memo': memo,
      'contentText': contentText,
      'blackboardType': blackboardType,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// コピーを作成（一部フィールドを更新）
  PhotoItem copyWith({
    String? id,
    String? category,
    String? name,
    String? status,
    String? imagePath,
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
      memo: memo ?? this.memo,
      contentText: contentText ?? this.contentText,
      blackboardType: blackboardType ?? this.blackboardType,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
