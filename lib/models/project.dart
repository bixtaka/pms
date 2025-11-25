import 'package:cloud_firestore/cloud_firestore.dart';

/// 工事（プロジェクト）モデル
class Project {
  final String id;
  final String name;
  final String architect;
  final String generalContractor;
  final String tradingCompany;
  final String fabricator;
  final String inspectionAgency;
  final String areaCode;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Project({
    required this.id,
    required this.name,
    this.architect = '',
    this.generalContractor = '',
    this.tradingCompany = '',
    this.fabricator = '',
    this.inspectionAgency = '',
    this.areaCode = '',
    this.startDate,
    this.endDate,
    this.createdAt,
    this.updatedAt,
  });

  Project copyWith({
    String? id,
    String? name,
    String? architect,
    String? generalContractor,
    String? tradingCompany,
    String? fabricator,
    String? inspectionAgency,
    String? areaCode,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Project(
        id: id ?? this.id,
        name: name ?? this.name,
        architect: architect ?? this.architect,
        generalContractor: generalContractor ?? this.generalContractor,
        tradingCompany: tradingCompany ?? this.tradingCompany,
        fabricator: fabricator ?? this.fabricator,
        inspectionAgency: inspectionAgency ?? this.inspectionAgency,
        areaCode: areaCode ?? this.areaCode,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  factory Project.fromJson(Map<String, dynamic> json, String id) => Project(
        id: id,
        name: json['name'] ?? '',
        architect: json['architect'] ?? '',
        generalContractor: json['generalContractor'] ?? '',
        tradingCompany: json['tradingCompany'] ?? '',
        fabricator: json['fabricator'] ?? '',
        inspectionAgency: json['inspectionAgency'] ?? '',
        areaCode: json['areaCode'] ?? '',
        startDate: (json['startDate'] as Timestamp?)?.toDate(),
        endDate: (json['endDate'] as Timestamp?)?.toDate(),
        createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
        updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'architect': architect,
        'generalContractor': generalContractor,
        'tradingCompany': tradingCompany,
        'fabricator': fabricator,
        'inspectionAgency': inspectionAgency,
        'areaCode': areaCode,
        'startDate': startDate,
        'endDate': endDate,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}
