import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/template_builder_screen.dart'; // import for TemplateItem

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
