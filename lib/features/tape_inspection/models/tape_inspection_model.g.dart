// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tape_inspection_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TapeInspection _$TapeInspectionFromJson(Map<String, dynamic> json) =>
    _TapeInspection(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      inspectionDate: DateTime.parse(json['inspectionDate'] as String),
      inspectorName: json['inspectorName'] as String,
      tension: json['tension'] as String,
      checkpoints:
          (json['checkpoints'] as List<dynamic>?)
              ?.map((e) => TapeCheckpoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$TapeInspectionToJson(_TapeInspection instance) =>
    <String, dynamic>{
      'id': instance.id,
      'projectId': instance.projectId,
      'inspectionDate': instance.inspectionDate.toIso8601String(),
      'inspectorName': instance.inspectorName,
      'tension': instance.tension,
      'checkpoints': instance.checkpoints,
    };

_TapeCheckpoint _$TapeCheckpointFromJson(Map<String, dynamic> json) =>
    _TapeCheckpoint(
      distance: json['distance'] as String,
      widePhotoUrl: json['widePhotoUrl'] as String?,
      closeupPhotoUrl: json['closeupPhotoUrl'] as String?,
      errorValue: json['errorValue'] as String? ?? '',
      isWidePhotoTaken: json['isWidePhotoTaken'] as bool? ?? false,
      isCloseupPhotoTaken: json['isCloseupPhotoTaken'] as bool? ?? false,
    );

Map<String, dynamic> _$TapeCheckpointToJson(_TapeCheckpoint instance) =>
    <String, dynamic>{
      'distance': instance.distance,
      'widePhotoUrl': instance.widePhotoUrl,
      'closeupPhotoUrl': instance.closeupPhotoUrl,
      'errorValue': instance.errorValue,
      'isWidePhotoTaken': instance.isWidePhotoTaken,
      'isCloseupPhotoTaken': instance.isCloseupPhotoTaken,
    };
