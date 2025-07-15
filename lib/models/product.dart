import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String type;
  final String processCategory;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  // 追加項目
  final String partName;
  final String material;
  final String area;
  final String setsu;
  final String floor;

  Product({
    required this.id,
    required this.name,
    required this.type,
    required this.processCategory,
    required this.status,
    this.startDate,
    this.endDate,
    this.partName = '',
    this.material = '',
    this.area = '',
    this.setsu = '',
    this.floor = '',
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
      partName: data['partName'] ?? '',
      material: data['material'] ?? '',
      area: data['area'] ?? '',
      setsu: data['setsu'] ?? '',
      floor: data['floor'] ?? '',
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
      'partName': partName,
      'material': material,
      'area': area,
      'setsu': setsu,
      'floor': floor,
    };
  }

  Product copyWith({
    String? name,
    String? type,
    String? processCategory,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? partName,
    String? material,
    String? area,
    String? setsu,
    String? floor,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      processCategory: processCategory ?? this.processCategory,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      partName: partName ?? this.partName,
      material: material ?? this.material,
      area: area ?? this.area,
      setsu: setsu ?? this.setsu,
      floor: floor ?? this.floor,
    );
  }
}
