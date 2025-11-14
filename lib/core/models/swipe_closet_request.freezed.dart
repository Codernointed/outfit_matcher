// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'swipe_closet_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SwipeClosetRequest _$SwipeClosetRequestFromJson(Map<String, dynamic> json) {
  return _SwipeClosetRequest.fromJson(json);
}

/// @nodoc
mixin _$SwipeClosetRequest {
  String get occasion => throw _privateConstructorUsedError;
  String? get mood => throw _privateConstructorUsedError;
  String? get weather => throw _privateConstructorUsedError;
  String? get colorPreference => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  String get gender => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SwipeClosetRequestCopyWith<SwipeClosetRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SwipeClosetRequestCopyWith<$Res> {
  factory $SwipeClosetRequestCopyWith(
    SwipeClosetRequest value,
    $Res Function(SwipeClosetRequest) then,
  ) = _$SwipeClosetRequestCopyWithImpl<$Res, SwipeClosetRequest>;
  @useResult
  $Res call({
    String occasion,
    String? mood,
    String? weather,
    String? colorPreference,
    String? notes,
    String gender,
  });
}

/// @nodoc
class _$SwipeClosetRequestCopyWithImpl<$Res, $Val extends SwipeClosetRequest>
    implements $SwipeClosetRequestCopyWith<$Res> {
  _$SwipeClosetRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? occasion = null,
    Object? mood = freezed,
    Object? weather = freezed,
    Object? colorPreference = freezed,
    Object? notes = freezed,
    Object? gender = null,
  }) {
    return _then(
      _value.copyWith(
            occasion: null == occasion
                ? _value.occasion
                : occasion // ignore: cast_nullable_to_non_nullable
                      as String,
            mood: freezed == mood
                ? _value.mood
                : mood // ignore: cast_nullable_to_non_nullable
                      as String?,
            weather: freezed == weather
                ? _value.weather
                : weather // ignore: cast_nullable_to_non_nullable
                      as String?,
            colorPreference: freezed == colorPreference
                ? _value.colorPreference
                : colorPreference // ignore: cast_nullable_to_non_nullable
                      as String?,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            gender: null == gender
                ? _value.gender
                : gender // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SwipeClosetRequestImplCopyWith<$Res>
    implements $SwipeClosetRequestCopyWith<$Res> {
  factory _$$SwipeClosetRequestImplCopyWith(
    _$SwipeClosetRequestImpl value,
    $Res Function(_$SwipeClosetRequestImpl) then,
  ) = __$$SwipeClosetRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String occasion,
    String? mood,
    String? weather,
    String? colorPreference,
    String? notes,
    String gender,
  });
}

/// @nodoc
class __$$SwipeClosetRequestImplCopyWithImpl<$Res>
    extends _$SwipeClosetRequestCopyWithImpl<$Res, _$SwipeClosetRequestImpl>
    implements _$$SwipeClosetRequestImplCopyWith<$Res> {
  __$$SwipeClosetRequestImplCopyWithImpl(
    _$SwipeClosetRequestImpl _value,
    $Res Function(_$SwipeClosetRequestImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? occasion = null,
    Object? mood = freezed,
    Object? weather = freezed,
    Object? colorPreference = freezed,
    Object? notes = freezed,
    Object? gender = null,
  }) {
    return _then(
      _$SwipeClosetRequestImpl(
        occasion: null == occasion
            ? _value.occasion
            : occasion // ignore: cast_nullable_to_non_nullable
                  as String,
        mood: freezed == mood
            ? _value.mood
            : mood // ignore: cast_nullable_to_non_nullable
                  as String?,
        weather: freezed == weather
            ? _value.weather
            : weather // ignore: cast_nullable_to_non_nullable
                  as String?,
        colorPreference: freezed == colorPreference
            ? _value.colorPreference
            : colorPreference // ignore: cast_nullable_to_non_nullable
                  as String?,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        gender: null == gender
            ? _value.gender
            : gender // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SwipeClosetRequestImpl implements _SwipeClosetRequest {
  const _$SwipeClosetRequestImpl({
    required this.occasion,
    this.mood,
    this.weather,
    this.colorPreference,
    this.notes,
    this.gender = '',
  });

  factory _$SwipeClosetRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$SwipeClosetRequestImplFromJson(json);

  @override
  final String occasion;
  @override
  final String? mood;
  @override
  final String? weather;
  @override
  final String? colorPreference;
  @override
  final String? notes;
  @override
  @JsonKey()
  final String gender;

  @override
  String toString() {
    return 'SwipeClosetRequest(occasion: $occasion, mood: $mood, weather: $weather, colorPreference: $colorPreference, notes: $notes, gender: $gender)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SwipeClosetRequestImpl &&
            (identical(other.occasion, occasion) ||
                other.occasion == occasion) &&
            (identical(other.mood, mood) || other.mood == mood) &&
            (identical(other.weather, weather) || other.weather == weather) &&
            (identical(other.colorPreference, colorPreference) ||
                other.colorPreference == colorPreference) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.gender, gender) || other.gender == gender));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    occasion,
    mood,
    weather,
    colorPreference,
    notes,
    gender,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SwipeClosetRequestImplCopyWith<_$SwipeClosetRequestImpl> get copyWith =>
      __$$SwipeClosetRequestImplCopyWithImpl<_$SwipeClosetRequestImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SwipeClosetRequestImplToJson(this);
  }
}

abstract class _SwipeClosetRequest implements SwipeClosetRequest {
  const factory _SwipeClosetRequest({
    required final String occasion,
    final String? mood,
    final String? weather,
    final String? colorPreference,
    final String? notes,
    final String gender,
  }) = _$SwipeClosetRequestImpl;

  factory _SwipeClosetRequest.fromJson(Map<String, dynamic> json) =
      _$SwipeClosetRequestImpl.fromJson;

  @override
  String get occasion;
  @override
  String? get mood;
  @override
  String? get weather;
  @override
  String? get colorPreference;
  @override
  String? get notes;
  @override
  String get gender;
  @override
  @JsonKey(ignore: true)
  _$$SwipeClosetRequestImplCopyWith<_$SwipeClosetRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

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
    SwipeClosetPools value,
    $Res Function(SwipeClosetPools) then,
  ) = _$SwipeClosetPoolsCopyWithImpl<$Res, SwipeClosetPools>;
  @useResult
  $Res call({
    List<WardrobeItem> tops,
    List<WardrobeItem> bottoms,
    List<WardrobeItem> footwear,
    List<WardrobeItem> accessories,
  });
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
    return _then(
      _value.copyWith(
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
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SwipeClosetPoolsImplCopyWith<$Res>
    implements $SwipeClosetPoolsCopyWith<$Res> {
  factory _$$SwipeClosetPoolsImplCopyWith(
    _$SwipeClosetPoolsImpl value,
    $Res Function(_$SwipeClosetPoolsImpl) then,
  ) = __$$SwipeClosetPoolsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<WardrobeItem> tops,
    List<WardrobeItem> bottoms,
    List<WardrobeItem> footwear,
    List<WardrobeItem> accessories,
  });
}

/// @nodoc
class __$$SwipeClosetPoolsImplCopyWithImpl<$Res>
    extends _$SwipeClosetPoolsCopyWithImpl<$Res, _$SwipeClosetPoolsImpl>
    implements _$$SwipeClosetPoolsImplCopyWith<$Res> {
  __$$SwipeClosetPoolsImplCopyWithImpl(
    _$SwipeClosetPoolsImpl _value,
    $Res Function(_$SwipeClosetPoolsImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tops = null,
    Object? bottoms = null,
    Object? footwear = null,
    Object? accessories = null,
  }) {
    return _then(
      _$SwipeClosetPoolsImpl(
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
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SwipeClosetPoolsImpl implements _SwipeClosetPools {
  const _$SwipeClosetPoolsImpl({
    final List<WardrobeItem> tops = const [],
    final List<WardrobeItem> bottoms = const [],
    final List<WardrobeItem> footwear = const [],
    final List<WardrobeItem> accessories = const [],
  }) : _tops = tops,
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
            const DeepCollectionEquality().equals(
              other._accessories,
              _accessories,
            ));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_tops),
    const DeepCollectionEquality().hash(_bottoms),
    const DeepCollectionEquality().hash(_footwear),
    const DeepCollectionEquality().hash(_accessories),
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SwipeClosetPoolsImplCopyWith<_$SwipeClosetPoolsImpl> get copyWith =>
      __$$SwipeClosetPoolsImplCopyWithImpl<_$SwipeClosetPoolsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SwipeClosetPoolsImplToJson(this);
  }
}

abstract class _SwipeClosetPools implements SwipeClosetPools {
  const factory _SwipeClosetPools({
    final List<WardrobeItem> tops,
    final List<WardrobeItem> bottoms,
    final List<WardrobeItem> footwear,
    final List<WardrobeItem> accessories,
  }) = _$SwipeClosetPoolsImpl;

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
