import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String type;
  final String processCategory;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;

  Product({
    required this.id,
    required this.name,
    required this.type,
    required this.processCategory,
    required this.status,
    this.startDate,
    this.endDate,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      processCategory: data['processCategory'] ?? '未分類',
      status: data['status'] ?? 'not_started',
      startDate: (data['startDate'] != null)
          ? (data['startDate'] as Timestamp).toDate()
          : null,
      endDate: (data['endDate'] != null)
          ? (data['endDate'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type,
      'processCategory': processCategory,
      'status': status,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
    };
  }

  Product copyWith({
    String? name,
    String? type,
    String? processCategory,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      processCategory: processCategory ?? this.processCategory,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}
