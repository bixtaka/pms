// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tape_inspection_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TapeInspection {

 String get id; String get projectId; DateTime get inspectionDate; String get inspectorName; String get tension; List<TapeInspectionItem> get items;
/// Create a copy of TapeInspection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TapeInspectionCopyWith<TapeInspection> get copyWith => _$TapeInspectionCopyWithImpl<TapeInspection>(this as TapeInspection, _$identity);

  /// Serializes this TapeInspection to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TapeInspection&&(identical(other.id, id) || other.id == id)&&(identical(other.projectId, projectId) || other.projectId == projectId)&&(identical(other.inspectionDate, inspectionDate) || other.inspectionDate == inspectionDate)&&(identical(other.inspectorName, inspectorName) || other.inspectorName == inspectorName)&&(identical(other.tension, tension) || other.tension == tension)&&const DeepCollectionEquality().equals(other.items, items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,projectId,inspectionDate,inspectorName,tension,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'TapeInspection(id: $id, projectId: $projectId, inspectionDate: $inspectionDate, inspectorName: $inspectorName, tension: $tension, items: $items)';
}


}

/// @nodoc
abstract mixin class $TapeInspectionCopyWith<$Res>  {
  factory $TapeInspectionCopyWith(TapeInspection value, $Res Function(TapeInspection) _then) = _$TapeInspectionCopyWithImpl;
@useResult
$Res call({
 String id, String projectId, DateTime inspectionDate, String inspectorName, String tension, List<TapeInspectionItem> items
});




}
/// @nodoc
class _$TapeInspectionCopyWithImpl<$Res>
    implements $TapeInspectionCopyWith<$Res> {
  _$TapeInspectionCopyWithImpl(this._self, this._then);

  final TapeInspection _self;
  final $Res Function(TapeInspection) _then;

/// Create a copy of TapeInspection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? projectId = null,Object? inspectionDate = null,Object? inspectorName = null,Object? tension = null,Object? items = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,projectId: null == projectId ? _self.projectId : projectId // ignore: cast_nullable_to_non_nullable
as String,inspectionDate: null == inspectionDate ? _self.inspectionDate : inspectionDate // ignore: cast_nullable_to_non_nullable
as DateTime,inspectorName: null == inspectorName ? _self.inspectorName : inspectorName // ignore: cast_nullable_to_non_nullable
as String,tension: null == tension ? _self.tension : tension // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<TapeInspectionItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [TapeInspection].
extension TapeInspectionPatterns on TapeInspection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TapeInspection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TapeInspection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TapeInspection value)  $default,){
final _that = this;
switch (_that) {
case _TapeInspection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TapeInspection value)?  $default,){
final _that = this;
switch (_that) {
case _TapeInspection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String projectId,  DateTime inspectionDate,  String inspectorName,  String tension,  List<TapeInspectionItem> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TapeInspection() when $default != null:
return $default(_that.id,_that.projectId,_that.inspectionDate,_that.inspectorName,_that.tension,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String projectId,  DateTime inspectionDate,  String inspectorName,  String tension,  List<TapeInspectionItem> items)  $default,) {final _that = this;
switch (_that) {
case _TapeInspection():
return $default(_that.id,_that.projectId,_that.inspectionDate,_that.inspectorName,_that.tension,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String projectId,  DateTime inspectionDate,  String inspectorName,  String tension,  List<TapeInspectionItem> items)?  $default,) {final _that = this;
switch (_that) {
case _TapeInspection() when $default != null:
return $default(_that.id,_that.projectId,_that.inspectionDate,_that.inspectorName,_that.tension,_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TapeInspection implements TapeInspection {
  const _TapeInspection({required this.id, required this.projectId, required this.inspectionDate, required this.inspectorName, required this.tension, final  List<TapeInspectionItem> items = const []}): _items = items;
  factory _TapeInspection.fromJson(Map<String, dynamic> json) => _$TapeInspectionFromJson(json);

@override final  String id;
@override final  String projectId;
@override final  DateTime inspectionDate;
@override final  String inspectorName;
@override final  String tension;
 final  List<TapeInspectionItem> _items;
@override@JsonKey() List<TapeInspectionItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of TapeInspection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TapeInspectionCopyWith<_TapeInspection> get copyWith => __$TapeInspectionCopyWithImpl<_TapeInspection>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TapeInspectionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TapeInspection&&(identical(other.id, id) || other.id == id)&&(identical(other.projectId, projectId) || other.projectId == projectId)&&(identical(other.inspectionDate, inspectionDate) || other.inspectionDate == inspectionDate)&&(identical(other.inspectorName, inspectorName) || other.inspectorName == inspectorName)&&(identical(other.tension, tension) || other.tension == tension)&&const DeepCollectionEquality().equals(other._items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,projectId,inspectionDate,inspectorName,tension,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'TapeInspection(id: $id, projectId: $projectId, inspectionDate: $inspectionDate, inspectorName: $inspectorName, tension: $tension, items: $items)';
}


}

/// @nodoc
abstract mixin class _$TapeInspectionCopyWith<$Res> implements $TapeInspectionCopyWith<$Res> {
  factory _$TapeInspectionCopyWith(_TapeInspection value, $Res Function(_TapeInspection) _then) = __$TapeInspectionCopyWithImpl;
@override @useResult
$Res call({
 String id, String projectId, DateTime inspectionDate, String inspectorName, String tension, List<TapeInspectionItem> items
});




}
/// @nodoc
class __$TapeInspectionCopyWithImpl<$Res>
    implements _$TapeInspectionCopyWith<$Res> {
  __$TapeInspectionCopyWithImpl(this._self, this._then);

  final _TapeInspection _self;
  final $Res Function(_TapeInspection) _then;

/// Create a copy of TapeInspection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? projectId = null,Object? inspectionDate = null,Object? inspectorName = null,Object? tension = null,Object? items = null,}) {
  return _then(_TapeInspection(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,projectId: null == projectId ? _self.projectId : projectId // ignore: cast_nullable_to_non_nullable
as String,inspectionDate: null == inspectionDate ? _self.inspectionDate : inspectionDate // ignore: cast_nullable_to_non_nullable
as DateTime,inspectorName: null == inspectorName ? _self.inspectorName : inspectorName // ignore: cast_nullable_to_non_nullable
as String,tension: null == tension ? _self.tension : tension // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<TapeInspectionItem>,
  ));
}


}


/// @nodoc
mixin _$TapeInspectionItem {

 String get id; String get name; bool get isMeasurement; String? get widePhotoUrl; String? get closeupPhotoUrl; String get errorValue; bool get isWidePhotoTaken; bool get isCloseupPhotoTaken;
/// Create a copy of TapeInspectionItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TapeInspectionItemCopyWith<TapeInspectionItem> get copyWith => _$TapeInspectionItemCopyWithImpl<TapeInspectionItem>(this as TapeInspectionItem, _$identity);

  /// Serializes this TapeInspectionItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TapeInspectionItem&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.isMeasurement, isMeasurement) || other.isMeasurement == isMeasurement)&&(identical(other.widePhotoUrl, widePhotoUrl) || other.widePhotoUrl == widePhotoUrl)&&(identical(other.closeupPhotoUrl, closeupPhotoUrl) || other.closeupPhotoUrl == closeupPhotoUrl)&&(identical(other.errorValue, errorValue) || other.errorValue == errorValue)&&(identical(other.isWidePhotoTaken, isWidePhotoTaken) || other.isWidePhotoTaken == isWidePhotoTaken)&&(identical(other.isCloseupPhotoTaken, isCloseupPhotoTaken) || other.isCloseupPhotoTaken == isCloseupPhotoTaken));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,isMeasurement,widePhotoUrl,closeupPhotoUrl,errorValue,isWidePhotoTaken,isCloseupPhotoTaken);

@override
String toString() {
  return 'TapeInspectionItem(id: $id, name: $name, isMeasurement: $isMeasurement, widePhotoUrl: $widePhotoUrl, closeupPhotoUrl: $closeupPhotoUrl, errorValue: $errorValue, isWidePhotoTaken: $isWidePhotoTaken, isCloseupPhotoTaken: $isCloseupPhotoTaken)';
}


}

/// @nodoc
abstract mixin class $TapeInspectionItemCopyWith<$Res>  {
  factory $TapeInspectionItemCopyWith(TapeInspectionItem value, $Res Function(TapeInspectionItem) _then) = _$TapeInspectionItemCopyWithImpl;
@useResult
$Res call({
 String id, String name, bool isMeasurement, String? widePhotoUrl, String? closeupPhotoUrl, String errorValue, bool isWidePhotoTaken, bool isCloseupPhotoTaken
});




}
/// @nodoc
class _$TapeInspectionItemCopyWithImpl<$Res>
    implements $TapeInspectionItemCopyWith<$Res> {
  _$TapeInspectionItemCopyWithImpl(this._self, this._then);

  final TapeInspectionItem _self;
  final $Res Function(TapeInspectionItem) _then;

/// Create a copy of TapeInspectionItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? isMeasurement = null,Object? widePhotoUrl = freezed,Object? closeupPhotoUrl = freezed,Object? errorValue = null,Object? isWidePhotoTaken = null,Object? isCloseupPhotoTaken = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isMeasurement: null == isMeasurement ? _self.isMeasurement : isMeasurement // ignore: cast_nullable_to_non_nullable
as bool,widePhotoUrl: freezed == widePhotoUrl ? _self.widePhotoUrl : widePhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,closeupPhotoUrl: freezed == closeupPhotoUrl ? _self.closeupPhotoUrl : closeupPhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,errorValue: null == errorValue ? _self.errorValue : errorValue // ignore: cast_nullable_to_non_nullable
as String,isWidePhotoTaken: null == isWidePhotoTaken ? _self.isWidePhotoTaken : isWidePhotoTaken // ignore: cast_nullable_to_non_nullable
as bool,isCloseupPhotoTaken: null == isCloseupPhotoTaken ? _self.isCloseupPhotoTaken : isCloseupPhotoTaken // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [TapeInspectionItem].
extension TapeInspectionItemPatterns on TapeInspectionItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TapeInspectionItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TapeInspectionItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TapeInspectionItem value)  $default,){
final _that = this;
switch (_that) {
case _TapeInspectionItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TapeInspectionItem value)?  $default,){
final _that = this;
switch (_that) {
case _TapeInspectionItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  bool isMeasurement,  String? widePhotoUrl,  String? closeupPhotoUrl,  String errorValue,  bool isWidePhotoTaken,  bool isCloseupPhotoTaken)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TapeInspectionItem() when $default != null:
return $default(_that.id,_that.name,_that.isMeasurement,_that.widePhotoUrl,_that.closeupPhotoUrl,_that.errorValue,_that.isWidePhotoTaken,_that.isCloseupPhotoTaken);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  bool isMeasurement,  String? widePhotoUrl,  String? closeupPhotoUrl,  String errorValue,  bool isWidePhotoTaken,  bool isCloseupPhotoTaken)  $default,) {final _that = this;
switch (_that) {
case _TapeInspectionItem():
return $default(_that.id,_that.name,_that.isMeasurement,_that.widePhotoUrl,_that.closeupPhotoUrl,_that.errorValue,_that.isWidePhotoTaken,_that.isCloseupPhotoTaken);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  bool isMeasurement,  String? widePhotoUrl,  String? closeupPhotoUrl,  String errorValue,  bool isWidePhotoTaken,  bool isCloseupPhotoTaken)?  $default,) {final _that = this;
switch (_that) {
case _TapeInspectionItem() when $default != null:
return $default(_that.id,_that.name,_that.isMeasurement,_that.widePhotoUrl,_that.closeupPhotoUrl,_that.errorValue,_that.isWidePhotoTaken,_that.isCloseupPhotoTaken);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TapeInspectionItem implements TapeInspectionItem {
  const _TapeInspectionItem({required this.id, required this.name, required this.isMeasurement, this.widePhotoUrl, this.closeupPhotoUrl, this.errorValue = '', this.isWidePhotoTaken = false, this.isCloseupPhotoTaken = false});
  factory _TapeInspectionItem.fromJson(Map<String, dynamic> json) => _$TapeInspectionItemFromJson(json);

@override final  String id;
@override final  String name;
@override final  bool isMeasurement;
@override final  String? widePhotoUrl;
@override final  String? closeupPhotoUrl;
@override@JsonKey() final  String errorValue;
@override@JsonKey() final  bool isWidePhotoTaken;
@override@JsonKey() final  bool isCloseupPhotoTaken;

/// Create a copy of TapeInspectionItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TapeInspectionItemCopyWith<_TapeInspectionItem> get copyWith => __$TapeInspectionItemCopyWithImpl<_TapeInspectionItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TapeInspectionItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TapeInspectionItem&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.isMeasurement, isMeasurement) || other.isMeasurement == isMeasurement)&&(identical(other.widePhotoUrl, widePhotoUrl) || other.widePhotoUrl == widePhotoUrl)&&(identical(other.closeupPhotoUrl, closeupPhotoUrl) || other.closeupPhotoUrl == closeupPhotoUrl)&&(identical(other.errorValue, errorValue) || other.errorValue == errorValue)&&(identical(other.isWidePhotoTaken, isWidePhotoTaken) || other.isWidePhotoTaken == isWidePhotoTaken)&&(identical(other.isCloseupPhotoTaken, isCloseupPhotoTaken) || other.isCloseupPhotoTaken == isCloseupPhotoTaken));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,isMeasurement,widePhotoUrl,closeupPhotoUrl,errorValue,isWidePhotoTaken,isCloseupPhotoTaken);

@override
String toString() {
  return 'TapeInspectionItem(id: $id, name: $name, isMeasurement: $isMeasurement, widePhotoUrl: $widePhotoUrl, closeupPhotoUrl: $closeupPhotoUrl, errorValue: $errorValue, isWidePhotoTaken: $isWidePhotoTaken, isCloseupPhotoTaken: $isCloseupPhotoTaken)';
}


}

/// @nodoc
abstract mixin class _$TapeInspectionItemCopyWith<$Res> implements $TapeInspectionItemCopyWith<$Res> {
  factory _$TapeInspectionItemCopyWith(_TapeInspectionItem value, $Res Function(_TapeInspectionItem) _then) = __$TapeInspectionItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, bool isMeasurement, String? widePhotoUrl, String? closeupPhotoUrl, String errorValue, bool isWidePhotoTaken, bool isCloseupPhotoTaken
});




}
/// @nodoc
class __$TapeInspectionItemCopyWithImpl<$Res>
    implements _$TapeInspectionItemCopyWith<$Res> {
  __$TapeInspectionItemCopyWithImpl(this._self, this._then);

  final _TapeInspectionItem _self;
  final $Res Function(_TapeInspectionItem) _then;

/// Create a copy of TapeInspectionItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? isMeasurement = null,Object? widePhotoUrl = freezed,Object? closeupPhotoUrl = freezed,Object? errorValue = null,Object? isWidePhotoTaken = null,Object? isCloseupPhotoTaken = null,}) {
  return _then(_TapeInspectionItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isMeasurement: null == isMeasurement ? _self.isMeasurement : isMeasurement // ignore: cast_nullable_to_non_nullable
as bool,widePhotoUrl: freezed == widePhotoUrl ? _self.widePhotoUrl : widePhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,closeupPhotoUrl: freezed == closeupPhotoUrl ? _self.closeupPhotoUrl : closeupPhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,errorValue: null == errorValue ? _self.errorValue : errorValue // ignore: cast_nullable_to_non_nullable
as String,isWidePhotoTaken: null == isWidePhotoTaken ? _self.isWidePhotoTaken : isWidePhotoTaken // ignore: cast_nullable_to_non_nullable
as bool,isCloseupPhotoTaken: null == isCloseupPhotoTaken ? _self.isCloseupPhotoTaken : isCloseupPhotoTaken // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
