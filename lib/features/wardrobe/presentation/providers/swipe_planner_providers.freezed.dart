// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'swipe_planner_providers.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SwipeClosetPools _$SwipeClosetPoolsFromJson(Map<String, dynamic> json) {
  return _SwipeClosetPools.fromJson(json);
}

/// @nodoc
mixin _$SwipeClosetPools {
  List<WardrobeItem> get tops => throw _privateConstructorUsedError;
  List<WardrobeItem> get bottoms => throw _privateConstructorUsedError;
  List<WardrobeItem> get footwear => throw _privateConstructorUsedError;
  List<WardrobeItem> get accessories => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SwipeClosetPoolsCopyWith<SwipeClosetPools> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SwipeClosetPoolsCopyWith<$Res> {
  factory $SwipeClosetPoolsCopyWith(
          SwipeClosetPools value, $Res Function(SwipeClosetPools) then) =
      _$SwipeClosetPoolsCopyWithImpl<$Res, SwipeClosetPools>;
  @useResult
  $Res call(
      {List<WardrobeItem> tops,
      List<WardrobeItem> bottoms,
      List<WardrobeItem> footwear,
      List<WardrobeItem> accessories});
}

/// @nodoc
class _$SwipeClosetPoolsCopyWithImpl<$Res, $Val extends SwipeClosetPools>
    implements $SwipeClosetPoolsCopyWith<$Res> {
  _$SwipeClosetPoolsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tops = null,
    Object? bottoms = null,
    Object? footwear = null,
    Object? accessories = null,
  }) {
    return _then(_value.copyWith(
      tops: null == tops
          ? _value.tops
          : tops // ignore: cast_nullable_to_non_nullable
              as List<WardrobeItem>,
      bottoms: null == bottoms
          ? _value.bottoms
          : bottoms // ignore: cast_nullable_to_non_nullable
              as List<WardrobeItem>,
      footwear: null == footwear
          ? _value.footwear
          : footwear // ignore: cast_nullable_to_non_nullable
              as List<WardrobeItem>,
      accessories: null == accessories
          ? _value.accessories
          : accessories // ignore: cast_nullable_to_non_nullable
              as List<WardrobeItem>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SwipeClosetPoolsImplCopyWith<$Res>
    implements $SwipeClosetPoolsCopyWith<$Res> {
  factory _$$SwipeClosetPoolsImplCopyWith(_$SwipeClosetPoolsImpl value,
          $Res Function(_$SwipeClosetPoolsImpl) then) =
      __$$SwipeClosetPoolsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<WardrobeItem> tops,
      List<WardrobeItem> bottoms,
      List<WardrobeItem> footwear,
      List<WardrobeItem> accessories});
}

/// @nodoc
class __$$SwipeClosetPoolsImplCopyWithImpl<$Res>
    extends _$SwipeClosetPoolsCopyWithImpl<$Res, _$SwipeClosetPoolsImpl>
    implements _$$SwipeClosetPoolsImplCopyWith<$Res> {
  __$$SwipeClosetPoolsImplCopyWithImpl(_$SwipeClosetPoolsImpl _value,
      $Res Function(_$SwipeClosetPoolsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tops = null,
    Object? bottoms = null,
    Object? footwear = null,
    Object? accessories = null,
  }) {
    return _then(_$SwipeClosetPoolsImpl(
      tops: null == tops
          ? _value._tops
          : tops // ignore: cast_nullable_to_non_nullable
              as List<WardrobeItem>,
      bottoms: null == bottoms
          ? _value._bottoms
          : bottoms // ignore: cast_nullable_to_non_nullable
              as List<WardrobeItem>,
      footwear: null == footwear
          ? _value._footwear
          : footwear // ignore: cast_nullable_to_non_nullable
              as List<WardrobeItem>,
      accessories: null == accessories
          ? _value._accessories
          : accessories // ignore: cast_nullable_to_non_nullable
              as List<WardrobeItem>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SwipeClosetPoolsImpl implements _SwipeClosetPools {
  const _$SwipeClosetPoolsImpl(
      {final List<WardrobeItem> tops = const [],
      final List<WardrobeItem> bottoms = const [],
      final List<WardrobeItem> footwear = const [],
      final List<WardrobeItem> accessories = const []})
      : _tops = tops,
        _bottoms = bottoms,
        _footwear = footwear,
        _accessories = accessories;

  factory _$SwipeClosetPoolsImpl.fromJson(Map<String, dynamic> json) =>
      _$$SwipeClosetPoolsImplFromJson(json);

  final List<WardrobeItem> _tops;
  @override
  @JsonKey()
  List<WardrobeItem> get tops {
    if (_tops is EqualUnmodifiableListView) return _tops;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tops);
  }

  final List<WardrobeItem> _bottoms;
  @override
  @JsonKey()
  List<WardrobeItem> get bottoms {
    if (_bottoms is EqualUnmodifiableListView) return _bottoms;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_bottoms);
  }

  final List<WardrobeItem> _footwear;
  @override
  @JsonKey()
  List<WardrobeItem> get footwear {
    if (_footwear is EqualUnmodifiableListView) return _footwear;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_footwear);
  }

  final List<WardrobeItem> _accessories;
  @override
  @JsonKey()
  List<WardrobeItem> get accessories {
    if (_accessories is EqualUnmodifiableListView) return _accessories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_accessories);
  }

  @override
  String toString() {
    return 'SwipeClosetPools(tops: $tops, bottoms: $bottoms, footwear: $footwear, accessories: $accessories)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SwipeClosetPoolsImpl &&
            const DeepCollectionEquality().equals(other._tops, _tops) &&
            const DeepCollectionEquality().equals(other._bottoms, _bottoms) &&
            const DeepCollectionEquality().equals(other._footwear, _footwear) &&
            const DeepCollectionEquality()
                .equals(other._accessories, _accessories));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_tops),
      const DeepCollectionEquality().hash(_bottoms),
      const DeepCollectionEquality().hash(_footwear),
      const DeepCollectionEquality().hash(_accessories));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SwipeClosetPoolsImplCopyWith<_$SwipeClosetPoolsImpl> get copyWith =>
      __$$SwipeClosetPoolsImplCopyWithImpl<_$SwipeClosetPoolsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SwipeClosetPoolsImplToJson(
      this,
    );
  }
}

abstract class _SwipeClosetPools implements SwipeClosetPools {
  const factory _SwipeClosetPools(
      {final List<WardrobeItem> tops,
      final List<WardrobeItem> bottoms,
      final List<WardrobeItem> footwear,
      final List<WardrobeItem> accessories}) = _$SwipeClosetPoolsImpl;

  factory _SwipeClosetPools.fromJson(Map<String, dynamic> json) =
      _$SwipeClosetPoolsImpl.fromJson;

  @override
  List<WardrobeItem> get tops;
  @override
  List<WardrobeItem> get bottoms;
  @override
  List<WardrobeItem> get footwear;
  @override
  List<WardrobeItem> get accessories;
  @override
  @JsonKey(ignore: true)
  _$$SwipeClosetPoolsImplCopyWith<_$SwipeClosetPoolsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SwipeClosetSelections _$SwipeClosetSelectionsFromJson(
    Map<String, dynamic> json) {
  return _SwipeClosetSelections.fromJson(json);
}

/// @nodoc
mixin _$SwipeClosetSelections {
  WardrobeItem? get top => throw _privateConstructorUsedError;
  WardrobeItem? get bottom => throw _privateConstructorUsedError;
  WardrobeItem? get footwear => throw _privateConstructorUsedError;
  WardrobeItem? get accessory => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SwipeClosetSelectionsCopyWith<SwipeClosetSelections> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SwipeClosetSelectionsCopyWith<$Res> {
  factory $SwipeClosetSelectionsCopyWith(SwipeClosetSelections value,
          $Res Function(SwipeClosetSelections) then) =
      _$SwipeClosetSelectionsCopyWithImpl<$Res, SwipeClosetSelections>;
  @useResult
  $Res call(
      {WardrobeItem? top,
      WardrobeItem? bottom,
      WardrobeItem? footwear,
      WardrobeItem? accessory});
}

/// @nodoc
class _$SwipeClosetSelectionsCopyWithImpl<$Res,
        $Val extends SwipeClosetSelections>
    implements $SwipeClosetSelectionsCopyWith<$Res> {
  _$SwipeClosetSelectionsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? top = freezed,
    Object? bottom = freezed,
    Object? footwear = freezed,
    Object? accessory = freezed,
  }) {
    return _then(_value.copyWith(
      top: freezed == top
          ? _value.top
          : top // ignore: cast_nullable_to_non_nullable
              as WardrobeItem?,
      bottom: freezed == bottom
          ? _value.bottom
          : bottom // ignore: cast_nullable_to_non_nullable
              as WardrobeItem?,
      footwear: freezed == footwear
          ? _value.footwear
          : footwear // ignore: cast_nullable_to_non_nullable
              as WardrobeItem?,
      accessory: freezed == accessory
          ? _value.accessory
          : accessory // ignore: cast_nullable_to_non_nullable
              as WardrobeItem?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SwipeClosetSelectionsImplCopyWith<$Res>
    implements $SwipeClosetSelectionsCopyWith<$Res> {
  factory _$$SwipeClosetSelectionsImplCopyWith(
          _$SwipeClosetSelectionsImpl value,
          $Res Function(_$SwipeClosetSelectionsImpl) then) =
      __$$SwipeClosetSelectionsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {WardrobeItem? top,
      WardrobeItem? bottom,
      WardrobeItem? footwear,
      WardrobeItem? accessory});
}

/// @nodoc
class __$$SwipeClosetSelectionsImplCopyWithImpl<$Res>
    extends _$SwipeClosetSelectionsCopyWithImpl<$Res,
        _$SwipeClosetSelectionsImpl>
    implements _$$SwipeClosetSelectionsImplCopyWith<$Res> {
  __$$SwipeClosetSelectionsImplCopyWithImpl(_$SwipeClosetSelectionsImpl _value,
      $Res Function(_$SwipeClosetSelectionsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? top = freezed,
    Object? bottom = freezed,
    Object? footwear = freezed,
    Object? accessory = freezed,
  }) {
    return _then(_$SwipeClosetSelectionsImpl(
      top: freezed == top
          ? _value.top
          : top // ignore: cast_nullable_to_non_nullable
              as WardrobeItem?,
      bottom: freezed == bottom
          ? _value.bottom
          : bottom // ignore: cast_nullable_to_non_nullable
              as WardrobeItem?,
      footwear: freezed == footwear
          ? _value.footwear
          : footwear // ignore: cast_nullable_to_non_nullable
              as WardrobeItem?,
      accessory: freezed == accessory
          ? _value.accessory
          : accessory // ignore: cast_nullable_to_non_nullable
              as WardrobeItem?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SwipeClosetSelectionsImpl implements _SwipeClosetSelections {
  const _$SwipeClosetSelectionsImpl(
      {this.top, this.bottom, this.footwear, this.accessory});

  factory _$SwipeClosetSelectionsImpl.fromJson(Map<String, dynamic> json) =>
      _$$SwipeClosetSelectionsImplFromJson(json);

  @override
  final WardrobeItem? top;
  @override
  final WardrobeItem? bottom;
  @override
  final WardrobeItem? footwear;
  @override
  final WardrobeItem? accessory;

  @override
  String toString() {
    return 'SwipeClosetSelections(top: $top, bottom: $bottom, footwear: $footwear, accessory: $accessory)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SwipeClosetSelectionsImpl &&
            (identical(other.top, top) || other.top == top) &&
            (identical(other.bottom, bottom) || other.bottom == bottom) &&
            (identical(other.footwear, footwear) ||
                other.footwear == footwear) &&
            (identical(other.accessory, accessory) ||
                other.accessory == accessory));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, top, bottom, footwear, accessory);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SwipeClosetSelectionsImplCopyWith<_$SwipeClosetSelectionsImpl>
      get copyWith => __$$SwipeClosetSelectionsImplCopyWithImpl<
          _$SwipeClosetSelectionsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SwipeClosetSelectionsImplToJson(
      this,
    );
  }
}

abstract class _SwipeClosetSelections implements SwipeClosetSelections {
  const factory _SwipeClosetSelections(
      {final WardrobeItem? top,
      final WardrobeItem? bottom,
      final WardrobeItem? footwear,
      final WardrobeItem? accessory}) = _$SwipeClosetSelectionsImpl;

  factory _SwipeClosetSelections.fromJson(Map<String, dynamic> json) =
      _$SwipeClosetSelectionsImpl.fromJson;

  @override
  WardrobeItem? get top;
  @override
  WardrobeItem? get bottom;
  @override
  WardrobeItem? get footwear;
  @override
  WardrobeItem? get accessory;
  @override
  @JsonKey(ignore: true)
  _$$SwipeClosetSelectionsImplCopyWith<_$SwipeClosetSelectionsImpl>
      get copyWith => throw _privateConstructorUsedError;
}
