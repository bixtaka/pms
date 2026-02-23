import 'package:freezed_annotation/freezed_annotation.dart';

part 'tape_inspection_model.freezed.dart';
part 'tape_inspection_model.g.dart';

@freezed
abstract class TapeInspection with _$TapeInspection {
  const factory TapeInspection({
    required String id,
    required String projectId,
    required DateTime inspectionDate,
    required String inspectorName,
    required String tension,
    @Default([]) List<TapeCheckpoint> checkpoints,
  }) = _TapeInspection;

  factory TapeInspection.fromJson(Map<String, dynamic> json) =>
      _$TapeInspectionFromJson(json);
}

@freezed
abstract class TapeCheckpoint with _$TapeCheckpoint {
  const factory TapeCheckpoint({
    required String distance,
    String? widePhotoUrl,
    String? closeupPhotoUrl,
    @Default('') String errorValue,
    @Default(false) bool isWidePhotoTaken,
    @Default(false) bool isCloseupPhotoTaken,
  }) = _TapeCheckpoint;

  factory TapeCheckpoint.fromJson(Map<String, dynamic> json) =>
      _$TapeCheckpointFromJson(json);
}
