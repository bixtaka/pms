import 'package:freezed_annotation/freezed_annotation.dart';

part 'witness_inspection_model.freezed.dart';
part 'witness_inspection_model.g.dart';

@freezed
abstract class ProductData with _$ProductData {
  const factory ProductData({
    required String id,
    required String section,
    required String category,
    required String productCode,
  }) = _ProductData;

  factory ProductData.fromJson(Map<String, dynamic> json) => _$ProductDataFromJson(json);
}

@freezed
abstract class InspectionRecord with _$InspectionRecord {
  const factory InspectionRecord({
    required String id,
    required String productId,
    required String measurementPoint,
    required String photoUrl,
    required DateTime inspectionDate,
  }) = _InspectionRecord;

  factory InspectionRecord.fromJson(Map<String, dynamic> json) => _$InspectionRecordFromJson(json);
}
