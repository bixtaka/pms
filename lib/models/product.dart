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
  }) =>
      Product(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        productCode: productCode ?? this.productCode,
        memberType: memberType ?? this.memberType,
        storyOrSet: storyOrSet ?? this.storyOrSet,
        grid: grid ?? this.grid,
        section: section ?? this.section,
        quantity: quantity ?? this.quantity,
        totalWeight: totalWeight ?? this.totalWeight,
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
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? data['productCode'] ?? '',
      type: data['type'] ?? data['memberType'] ?? '',
      processCategory: data['processCategory'] ?? '',
      status: data['status'] ?? data['overallStatus'] ?? 'not_started',
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      partName: data['partName'] ?? '',
      material: data['material'] ?? '',
      area: data['area'] ?? '',
      setsu: data['setsu'] ?? '',
      floor: data['floor'] ?? '',
      // 新構造もセット
      projectId: data['projectId'] ?? '',
      productCode: data['productCode'] ?? data['name'] ?? '',
      memberType: data['memberType'] ?? data['type'] ?? '',
      storyOrSet: data['storyOrSet'] ?? '',
      grid: data['grid'] ?? '',
      section: data['section'] ?? '',
      quantity: (data['quantity'] ?? 0) is int
          ? data['quantity'] as int
          : (data['quantity'] ?? 0).toInt(),
      totalWeight: (data['totalWeight'] ?? 0).toDouble(),
      overallStatus: data['overallStatus'] ?? data['status'] ?? 'not_started',
      overallStartDate: (data['overallStartDate'] as Timestamp?)?.toDate(),
      overallEndDate: (data['overallEndDate'] as Timestamp?)?.toDate(),
      remarks: data['remarks'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// 新構造の fromJson
  factory Product.fromJson(Map<String, dynamic> json, String id) => Product(
        id: id,
        projectId: json['projectId'] ?? '',
        productCode: json['productCode'] ?? json['name'] ?? '',
        memberType: json['memberType'] ?? json['type'] ?? '',
        storyOrSet: json['storyOrSet'] ?? '',
        grid: json['grid'] ?? '',
        section: json['section'] ?? '',
        quantity: (json['quantity'] ?? 0) is int
            ? json['quantity'] as int
            : (json['quantity'] ?? 0).toInt(),
        totalWeight: (json['totalWeight'] ?? 0).toDouble(),
        overallStatus: json['overallStatus'] ?? json['status'] ?? 'not_started',
        overallStartDate: (json['overallStartDate'] as Timestamp?)?.toDate(),
        overallEndDate: (json['overallEndDate'] as Timestamp?)?.toDate(),
        remarks: json['remarks'] ?? '',
        createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
        updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
        // 旧構造側も埋める
        name: json['name'] ?? json['productCode'] ?? '',
        type: json['type'] ?? json['memberType'] ?? '',
        processCategory: json['processCategory'] ?? '',
        status: json['status'] ?? json['overallStatus'] ?? 'not_started',
        startDate: (json['startDate'] as Timestamp?)?.toDate(),
        endDate: (json['endDate'] as Timestamp?)?.toDate(),
        partName: json['partName'] ?? '',
        material: json['material'] ?? '',
        area: json['area'] ?? '',
        setsu: json['setsu'] ?? '',
        floor: json['floor'] ?? '',
      );

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
        'overallStatus': overallStatus,
        'overallStartDate': overallStartDate != null
            ? Timestamp.fromDate(overallStartDate!)
            : null,
        'overallEndDate':
            overallEndDate != null ? Timestamp.fromDate(overallEndDate!) : null,
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
