// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'witness_inspection_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProductData _$ProductDataFromJson(Map<String, dynamic> json) => _ProductData(
  id: json['id'] as String,
  section: json['section'] as String,
  category: json['category'] as String,
  productCode: json['productCode'] as String,
);

Map<String, dynamic> _$ProductDataToJson(_ProductData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'section': instance.section,
      'category': instance.category,
      'productCode': instance.productCode,
    };

_InspectionRecord _$InspectionRecordFromJson(Map<String, dynamic> json) =>
    _InspectionRecord(
      id: json['id'] as String,
      productId: json['productId'] as String,
      measurementPoint: json['measurementPoint'] as String,
      photoUrl: json['photoUrl'] as String,
      inspectionDate: DateTime.parse(json['inspectionDate'] as String),
    );

Map<String, dynamic> _$InspectionRecordToJson(_InspectionRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'productId': instance.productId,
      'measurementPoint': instance.measurementPoint,
      'photoUrl': instance.photoUrl,
      'inspectionDate': instance.inspectionDate.toIso8601String(),
    };
