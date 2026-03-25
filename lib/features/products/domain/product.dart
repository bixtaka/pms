import 'package:cloud_firestore/cloud_firestore.dart';

/// 製品モデル（旧フィールドとの後方互換を維持しつつ新構造に対応）
class Product {
  final String id;
  // 新構造
  final String projectId;
  final String productCode;
  final String memberType;
  final String storyOrSet;
  final String grid;
  final String section;
  final int quantity;
  final double totalWeight;
  // 追加: CSV由来のカスタムフィールド
  final int lengthMm;
  final String direction;
  final int d1;
  final int d2;
  final String overallStatus;
  final DateTime? overallStartDate;
  final DateTime? overallEndDate;
  final String remarks;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // 旧構造フィールド（既存画面の後方互換用）
  final String name;
  final String type;
  final String processCategory;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String partName;
  final String material;
  final String area;
  final String setsu;
  final String floor;

  const Product({
    required this.id,
    // 新構造
    this.projectId = '',
    this.productCode = '',
    this.memberType = '',
    this.storyOrSet = '',
    this.grid = '',
    this.section = '',
    this.quantity = 0,
    this.totalWeight = 0,
    this.lengthMm = 0,
    this.direction = '',
    this.d1 = 0,
    this.d2 = 0,
    this.overallStatus = 'not_started',
    this.overallStartDate,
    this.overallEndDate,
    this.remarks = '',
    this.createdAt,
    this.updatedAt,
    // 旧構造
    this.name = '',
    this.type = '',
    this.processCategory = '',
    this.status = 'not_started',
    this.startDate,
    this.endDate,
    this.partName = '',
    this.material = '',
    this.area = '',
    this.setsu = '',
    this.floor = '',
  });

  Product copyWith({
    String? id,
    String? projectId,
    String? productCode,
    String? memberType,
    String? storyOrSet,
    String? grid,
    String? section,
    int? quantity,
    double? totalWeight,
    int? lengthMm,
    String? direction,
    int? d1,
    int? d2,
    String? overallStatus,
    DateTime? overallStartDate,
    DateTime? overallEndDate,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
    // old
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
  }) => Product(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    productCode: productCode ?? this.productCode,
    memberType: memberType ?? this.memberType,
    storyOrSet: storyOrSet ?? this.storyOrSet,
    grid: grid ?? this.grid,
    section: section ?? this.section,
    quantity: quantity ?? this.quantity,
    totalWeight: totalWeight ?? this.totalWeight,
    lengthMm: lengthMm ?? this.lengthMm,
    direction: direction ?? this.direction,
    d1: d1 ?? this.d1,
    d2: d2 ?? this.d2,
    overallStatus: overallStatus ?? this.overallStatus,
    overallStartDate: overallStartDate ?? this.overallStartDate,
    overallEndDate: overallEndDate ?? this.overallEndDate,
    remarks: remarks ?? this.remarks,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
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

  /// 旧構造の読み取り（既存サービス互換）
  factory Product.fromFirestore(DocumentSnapshot doc) {
    final docData = doc.data();
    final data = (docData as Map<String, dynamic>?) ?? <String, dynamic>{};
    return Product(
      id: doc.id,
      name: data['name']?.toString() ?? data['productCode']?.toString() ?? '',
      type: data['type']?.toString() ?? data['memberType']?.toString() ?? '',
      processCategory: data['processCategory']?.toString() ?? '',
      status:
          data['status']?.toString() ??
          data['overallStatus']?.toString() ??
          'not_started',
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      partName: data['partName']?.toString() ?? '',
      material: data['material']?.toString() ?? '',
      area: data['area']?.toString() ?? '',
      setsu: data['setsu']?.toString() ?? '',
      floor: data['floor']?.toString() ?? '',
      // 新構造もセット
      projectId: data['projectId']?.toString() ?? '',
      productCode:
          data['productCode']?.toString() ?? data['name']?.toString() ?? '',
      memberType:
          data['memberType']?.toString() ?? data['type']?.toString() ?? '',
      storyOrSet: data['storyOrSet']?.toString() ?? '',
      grid: data['grid']?.toString() ?? '',
      section: data['section']?.toString() ?? '',
      quantity: _safeInt(data['quantity']),
      totalWeight: _safeDouble(data['totalWeight']),
      lengthMm: _safeInt(data['lengthMm']),
      direction: data['direction']?.toString() ?? '',
      d1: _safeInt(data['d1']),
      d2: _safeInt(data['d2']),
      overallStatus:
          data['overallStatus']?.toString() ??
          data['status']?.toString() ??
          'not_started',
      overallStartDate: (data['overallStartDate'] as Timestamp?)?.toDate(),
      overallEndDate: (data['overallEndDate'] as Timestamp?)?.toDate(),
      remarks: data['remarks']?.toString() ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// 新構造の fromJson
  factory Product.fromJson(Map<String, dynamic> json, String id) => Product(
    id: id,
    projectId: json['projectId']?.toString() ?? '',
    productCode:
        json['productCode']?.toString() ?? json['name']?.toString() ?? '',
    memberType:
        json['memberType']?.toString() ?? json['type']?.toString() ?? '',
    storyOrSet: json['storyOrSet']?.toString() ?? '',
    grid: json['grid']?.toString() ?? '',
    section: json['section']?.toString() ?? '',
    quantity: _safeInt(json['quantity']),
    totalWeight: _safeDouble(json['totalWeight']),
    lengthMm: _safeInt(json['lengthMm']),
    direction: json['direction']?.toString() ?? '',
    d1: _safeInt(json['d1']),
    d2: _safeInt(json['d2']),
    overallStatus:
        json['overallStatus']?.toString() ??
        json['status']?.toString() ??
        'not_started',
    overallStartDate: (json['overallStartDate'] as Timestamp?)?.toDate(),
    overallEndDate: (json['overallEndDate'] as Timestamp?)?.toDate(),
    remarks: json['remarks']?.toString() ?? '',
    createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
    updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
    // 旧構造側も埋める
    name: json['name']?.toString() ?? json['productCode']?.toString() ?? '',
    type: json['type']?.toString() ?? json['memberType']?.toString() ?? '',
    processCategory: json['processCategory']?.toString() ?? '',
    status:
        json['status']?.toString() ??
        json['overallStatus']?.toString() ??
        'not_started',
    startDate: (json['startDate'] as Timestamp?)?.toDate(),
    endDate: (json['endDate'] as Timestamp?)?.toDate(),
    partName: json['partName']?.toString() ?? '',
    material: json['material']?.toString() ?? '',
    area: json['area']?.toString() ?? '',
    setsu: json['setsu']?.toString() ?? '',
    floor: json['floor']?.toString() ?? '',
  );

  static int _safeInt(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) return int.tryParse(val) ?? 0;
    return 0;
  }

  static double _safeDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toFirestore() => toJson();

  Map<String, dynamic> toJson() => {
    'projectId': projectId,
    'productCode': productCode,
    'memberType': memberType,
    'storyOrSet': storyOrSet,
    'grid': grid,
    'section': section,
    'quantity': quantity,
    'totalWeight': totalWeight,
    'lengthMm': lengthMm,
    'direction': direction,
    'd1': d1,
    'd2': d2,
    'overallStatus': overallStatus,
    'overallStartDate': overallStartDate != null
        ? Timestamp.fromDate(overallStartDate!)
        : null,
    'overallEndDate': overallEndDate != null
        ? Timestamp.fromDate(overallEndDate!)
        : null,
    'remarks': remarks,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
    'updatedAt': updatedAt != null
        ? Timestamp.fromDate(updatedAt!)
        : FieldValue.serverTimestamp(),
    // 旧構造も残す
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
