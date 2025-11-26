import 'package:cloud_firestore/cloud_firestore.dart';

/// 製品 × 工程ごとの進捗
class ProcessProgress {
  final String processId;
  final String status;
  final int totalQuantity;
  final int completedQuantity;
  final DateTime? startDate; // 工程開始日
  final DateTime? endDate; // 工程終了日
  final String remarks;
  final DateTime? updatedAt;
  final String updatedBy;

  const ProcessProgress({
    required this.processId,
    required this.status,
    required this.totalQuantity,
    required this.completedQuantity,
    this.startDate,
    this.endDate,
    this.remarks = '',
    this.updatedAt,
    this.updatedBy = '',
  });

  ProcessProgress copyWith({
    String? processId,
    String? status,
    int? totalQuantity,
    int? completedQuantity,
    DateTime? startDate,
    DateTime? endDate,
    String? remarks,
    DateTime? updatedAt,
    String? updatedBy,
  }) =>
      ProcessProgress(
        processId: processId ?? this.processId,
        status: status ?? this.status,
        totalQuantity: totalQuantity ?? this.totalQuantity,
        completedQuantity: completedQuantity ?? this.completedQuantity,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        remarks: remarks ?? this.remarks,
        updatedAt: updatedAt ?? this.updatedAt,
        updatedBy: updatedBy ?? this.updatedBy,
      );

  factory ProcessProgress.fromJson(Map<String, dynamic> json, String id) =>
      ProcessProgress(
        processId: id,
        status: json['status'] ?? 'not_started',
        totalQuantity: (json['totalQuantity'] ?? 0) as int,
        completedQuantity: (json['completedQuantity'] ?? 0) as int,
        startDate: (json['startDate'] as Timestamp?)?.toDate(),
        endDate: (json['endDate'] as Timestamp?)?.toDate(),
        remarks: json['remarks'] ?? '',
        updatedAt: (json['updatedAt'] as Timestamp?)?.toDate(),
        updatedBy: json['updatedBy'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'status': status,
        'totalQuantity': totalQuantity,
        'completedQuantity': completedQuantity,
        'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
        'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
        'remarks': remarks,
        'updatedAt':
            updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
        'updatedBy': updatedBy,
      };
}
