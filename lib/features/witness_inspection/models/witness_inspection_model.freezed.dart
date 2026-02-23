// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'witness_inspection_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProductData {

 String get id; String get section; String get category; String get productCode;
/// Create a copy of ProductData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductDataCopyWith<ProductData> get copyWith => _$ProductDataCopyWithImpl<ProductData>(this as ProductData, _$identity);

  /// Serializes this ProductData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductData&&(identical(other.id, id) || other.id == id)&&(identical(other.section, section) || other.section == section)&&(identical(other.category, category) || other.category == category)&&(identical(other.productCode, productCode) || other.productCode == productCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,section,category,productCode);

@override
String toString() {
  return 'ProductData(id: $id, section: $section, category: $category, productCode: $productCode)';
}


}

/// @nodoc
abstract mixin class $ProductDataCopyWith<$Res>  {
  factory $ProductDataCopyWith(ProductData value, $Res Function(ProductData) _then) = _$ProductDataCopyWithImpl;
@useResult
$Res call({
 String id, String section, String category, String productCode
});




}
/// @nodoc
class _$ProductDataCopyWithImpl<$Res>
    implements $ProductDataCopyWith<$Res> {
  _$ProductDataCopyWithImpl(this._self, this._then);

  final ProductData _self;
  final $Res Function(ProductData) _then;

/// Create a copy of ProductData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? section = null,Object? category = null,Object? productCode = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,section: null == section ? _self.section : section // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,productCode: null == productCode ? _self.productCode : productCode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductData].
extension ProductDataPatterns on ProductData {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductData() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductData value)  $default,){
final _that = this;
switch (_that) {
case _ProductData():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductData value)?  $default,){
final _that = this;
switch (_that) {
case _ProductData() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String section,  String category,  String productCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductData() when $default != null:
return $default(_that.id,_that.section,_that.category,_that.productCode);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String section,  String category,  String productCode)  $default,) {final _that = this;
switch (_that) {
case _ProductData():
return $default(_that.id,_that.section,_that.category,_that.productCode);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String section,  String category,  String productCode)?  $default,) {final _that = this;
switch (_that) {
case _ProductData() when $default != null:
return $default(_that.id,_that.section,_that.category,_that.productCode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProductData implements ProductData {
  const _ProductData({required this.id, required this.section, required this.category, required this.productCode});
  factory _ProductData.fromJson(Map<String, dynamic> json) => _$ProductDataFromJson(json);

@override final  String id;
@override final  String section;
@override final  String category;
@override final  String productCode;

/// Create a copy of ProductData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductDataCopyWith<_ProductData> get copyWith => __$ProductDataCopyWithImpl<_ProductData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductData&&(identical(other.id, id) || other.id == id)&&(identical(other.section, section) || other.section == section)&&(identical(other.category, category) || other.category == category)&&(identical(other.productCode, productCode) || other.productCode == productCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,section,category,productCode);

@override
String toString() {
  return 'ProductData(id: $id, section: $section, category: $category, productCode: $productCode)';
}


}

/// @nodoc
abstract mixin class _$ProductDataCopyWith<$Res> implements $ProductDataCopyWith<$Res> {
  factory _$ProductDataCopyWith(_ProductData value, $Res Function(_ProductData) _then) = __$ProductDataCopyWithImpl;
@override @useResult
$Res call({
 String id, String section, String category, String productCode
});




}
/// @nodoc
class __$ProductDataCopyWithImpl<$Res>
    implements _$ProductDataCopyWith<$Res> {
  __$ProductDataCopyWithImpl(this._self, this._then);

  final _ProductData _self;
  final $Res Function(_ProductData) _then;

/// Create a copy of ProductData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? section = null,Object? category = null,Object? productCode = null,}) {
  return _then(_ProductData(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,section: null == section ? _self.section : section // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,productCode: null == productCode ? _self.productCode : productCode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$InspectionRecord {

 String get id; String get productId; String get measurementPoint; String get photoUrl; DateTime get inspectionDate;
/// Create a copy of InspectionRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InspectionRecordCopyWith<InspectionRecord> get copyWith => _$InspectionRecordCopyWithImpl<InspectionRecord>(this as InspectionRecord, _$identity);

  /// Serializes this InspectionRecord to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InspectionRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.measurementPoint, measurementPoint) || other.measurementPoint == measurementPoint)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.inspectionDate, inspectionDate) || other.inspectionDate == inspectionDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,productId,measurementPoint,photoUrl,inspectionDate);

@override
String toString() {
  return 'InspectionRecord(id: $id, productId: $productId, measurementPoint: $measurementPoint, photoUrl: $photoUrl, inspectionDate: $inspectionDate)';
}


}

/// @nodoc
abstract mixin class $InspectionRecordCopyWith<$Res>  {
  factory $InspectionRecordCopyWith(InspectionRecord value, $Res Function(InspectionRecord) _then) = _$InspectionRecordCopyWithImpl;
@useResult
$Res call({
 String id, String productId, String measurementPoint, String photoUrl, DateTime inspectionDate
});




}
/// @nodoc
class _$InspectionRecordCopyWithImpl<$Res>
    implements $InspectionRecordCopyWith<$Res> {
  _$InspectionRecordCopyWithImpl(this._self, this._then);

  final InspectionRecord _self;
  final $Res Function(InspectionRecord) _then;

/// Create a copy of InspectionRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? productId = null,Object? measurementPoint = null,Object? photoUrl = null,Object? inspectionDate = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,measurementPoint: null == measurementPoint ? _self.measurementPoint : measurementPoint // ignore: cast_nullable_to_non_nullable
as String,photoUrl: null == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String,inspectionDate: null == inspectionDate ? _self.inspectionDate : inspectionDate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [InspectionRecord].
extension InspectionRecordPatterns on InspectionRecord {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InspectionRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InspectionRecord() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InspectionRecord value)  $default,){
final _that = this;
switch (_that) {
case _InspectionRecord():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InspectionRecord value)?  $default,){
final _that = this;
switch (_that) {
case _InspectionRecord() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String productId,  String measurementPoint,  String photoUrl,  DateTime inspectionDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InspectionRecord() when $default != null:
return $default(_that.id,_that.productId,_that.measurementPoint,_that.photoUrl,_that.inspectionDate);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String productId,  String measurementPoint,  String photoUrl,  DateTime inspectionDate)  $default,) {final _that = this;
switch (_that) {
case _InspectionRecord():
return $default(_that.id,_that.productId,_that.measurementPoint,_that.photoUrl,_that.inspectionDate);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String productId,  String measurementPoint,  String photoUrl,  DateTime inspectionDate)?  $default,) {final _that = this;
switch (_that) {
case _InspectionRecord() when $default != null:
return $default(_that.id,_that.productId,_that.measurementPoint,_that.photoUrl,_that.inspectionDate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InspectionRecord implements InspectionRecord {
  const _InspectionRecord({required this.id, required this.productId, required this.measurementPoint, required this.photoUrl, required this.inspectionDate});
  factory _InspectionRecord.fromJson(Map<String, dynamic> json) => _$InspectionRecordFromJson(json);

@override final  String id;
@override final  String productId;
@override final  String measurementPoint;
@override final  String photoUrl;
@override final  DateTime inspectionDate;

/// Create a copy of InspectionRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InspectionRecordCopyWith<_InspectionRecord> get copyWith => __$InspectionRecordCopyWithImpl<_InspectionRecord>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InspectionRecordToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InspectionRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.measurementPoint, measurementPoint) || other.measurementPoint == measurementPoint)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.inspectionDate, inspectionDate) || other.inspectionDate == inspectionDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,productId,measurementPoint,photoUrl,inspectionDate);

@override
String toString() {
  return 'InspectionRecord(id: $id, productId: $productId, measurementPoint: $measurementPoint, photoUrl: $photoUrl, inspectionDate: $inspectionDate)';
}


}

/// @nodoc
abstract mixin class _$InspectionRecordCopyWith<$Res> implements $InspectionRecordCopyWith<$Res> {
  factory _$InspectionRecordCopyWith(_InspectionRecord value, $Res Function(_InspectionRecord) _then) = __$InspectionRecordCopyWithImpl;
@override @useResult
$Res call({
 String id, String productId, String measurementPoint, String photoUrl, DateTime inspectionDate
});




}
/// @nodoc
class __$InspectionRecordCopyWithImpl<$Res>
    implements _$InspectionRecordCopyWith<$Res> {
  __$InspectionRecordCopyWithImpl(this._self, this._then);

  final _InspectionRecord _self;
  final $Res Function(_InspectionRecord) _then;

/// Create a copy of InspectionRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? productId = null,Object? measurementPoint = null,Object? photoUrl = null,Object? inspectionDate = null,}) {
  return _then(_InspectionRecord(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,measurementPoint: null == measurementPoint ? _self.measurementPoint : measurementPoint // ignore: cast_nullable_to_non_nullable
as String,photoUrl: null == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String,inspectionDate: null == inspectionDate ? _self.inspectionDate : inspectionDate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
