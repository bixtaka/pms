// photo_item.dart
// 撮影項目のモデルクラス
// Firestore との変換メソッドを含む

import 'package:cloud_firestore/cloud_firestore.dart';

/// 撮影項目のデータクラス
class PhotoItem {
  /// Firestore ドキュメント ID
  final String id;
  
  /// 工程名（例：一次加工、組立）
  final String name;
  
  /// 撮影ステータス ('pending' | 'completed')
  String status;
  
  /// 画像の保存パス（Webテスト時は空）
  String? imagePath;
  
  /// 備考
  String? memo;
  
  /// 作成日時
  final DateTime createdAt;

  PhotoItem({
    required this.id,
    required this.name,
    this.status = 'pending',
    this.imagePath,
    this.memo,
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
      name: data['name'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      imagePath: data['imagePath'] as String?,
      memo: data['memo'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// PhotoItem を Firestore 用 Map に変換
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'status': status,
      'imagePath': imagePath,
      'memo': memo,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// コピーを作成（一部フィールドを更新）
  PhotoItem copyWith({
    String? id,
    String? name,
    String? status,
    String? imagePath,
    String? memo,
    DateTime? createdAt,
  }) {
    return PhotoItem(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      imagePath: imagePath ?? this.imagePath,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
