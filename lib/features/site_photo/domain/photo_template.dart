import 'package:cloud_firestore/cloud_firestore.dart';

/// テンプレート項目のデータモデル（再帰的構造）
class TemplateItem {
  String id;
  String title; // 項目名
  String inputType; // 'text', 'number', 'select' 等
  List<TemplateItem> children; // 子項目のリスト

  TemplateItem({
    required this.id,
    this.title = '',
    this.inputType = 'text',
    List<TemplateItem>? children,
  }) : children = children ?? [];

  /// ディープコピーを作成するメソッド（編集用）
  TemplateItem clone() {
    return TemplateItem(
      id: this.id,
      title: this.title,
      inputType: this.inputType,
      children: this.children.map((c) => c.clone()).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'inputType': inputType,
      'children': children.map((e) => e.toMap()).toList(),
    };
  }

  factory TemplateItem.fromMap(Map<String, dynamic> map) {
    return TemplateItem(
      id: map['id'] as String,
      title: map['title'] as String,
      inputType: map['inputType'] as String,
      children: (map['children'] as List<dynamic>?)
              ?.map((e) => TemplateItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
class PhotoTemplate {
  final String id;
  final String name;
  final String category;
  final List<TemplateItem> items;
  final DateTime createdAt;

  PhotoTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.items,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory PhotoTemplate.fromFirestore(String id, Map<String, dynamic> data) {
    return PhotoTemplate(
      id: id,
      name: data['name'] as String? ?? '',
      category: data['category'] as String? ?? '未分類',
      items: (data['items'] as List<dynamic>?)
              ?.map((e) => TemplateItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category,
      'items': items.map((e) => e.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
