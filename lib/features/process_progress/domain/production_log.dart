import 'package:cloud_firestore/cloud_firestore.dart';

/// 日別実績ログ（任意）
class ProductionLog {
  final String id;
  final DateTime date;
  final String productId;
  final String processId;
  final int quantityDone;
  final String person;
  final String remark;
  final DateTime? createdAt;

  const ProductionLog({
    required this.id,
    required this.date,
    required this.productId,
    required this.processId,
    required this.quantityDone,
    required this.person,
    this.remark = '',
    this.createdAt,
  });

  ProductionLog copyWith({
    String? id,
    DateTime? date,
    String? productId,
    String? processId,
    int? quantityDone,
    String? person,
    String? remark,
    DateTime? createdAt,
  }) =>
      ProductionLog(
        id: id ?? this.id,
        date: date ?? this.date,
        productId: productId ?? this.productId,
        processId: processId ?? this.processId,
        quantityDone: quantityDone ?? this.quantityDone,
        person: person ?? this.person,
        remark: remark ?? this.remark,
        createdAt: createdAt ?? this.createdAt,
      );

  factory ProductionLog.fromJson(Map<String, dynamic> json, String id) =>
      ProductionLog(
        id: id,
        date: (json['date'] as Timestamp).toDate(),
        productId: json['productId'] ?? '',
        processId: json['processId'] ?? '',
        quantityDone: (json['quantityDone'] ?? 0) as int,
        person: json['person'] ?? '',
        remark: json['remark'] ?? '',
        createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toJson() => {
        'date': Timestamp.fromDate(date),
        'productId': productId,
        'processId': processId,
        'quantityDone': quantityDone,
        'person': person,
        'remark': remark,
        'createdAt': createdAt,
      };
}
