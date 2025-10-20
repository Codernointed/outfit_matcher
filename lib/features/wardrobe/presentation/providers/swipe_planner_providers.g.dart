// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'swipe_planner_providers.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SwipeClosetPoolsImpl _$$SwipeClosetPoolsImplFromJson(
        Map<String, dynamic> json) =>
    _$SwipeClosetPoolsImpl(
      tops: (json['tops'] as List<dynamic>?)
              ?.map((e) => WardrobeItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      bottoms: (json['bottoms'] as List<dynamic>?)
              ?.map((e) => WardrobeItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      footwear: (json['footwear'] as List<dynamic>?)
              ?.map((e) => WardrobeItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      accessories: (json['accessories'] as List<dynamic>?)
              ?.map((e) => WardrobeItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$SwipeClosetPoolsImplToJson(
        _$SwipeClosetPoolsImpl instance) =>
    <String, dynamic>{
      'tops': instance.tops,
      'bottoms': instance.bottoms,
      'footwear': instance.footwear,
      'accessories': instance.accessories,
    };

_$SwipeClosetSelectionsImpl _$$SwipeClosetSelectionsImplFromJson(
        Map<String, dynamic> json) =>
    _$SwipeClosetSelectionsImpl(
      top: json['top'] == null
          ? null
          : WardrobeItem.fromJson(json['top'] as Map<String, dynamic>),
      bottom: json['bottom'] == null
          ? null
          : WardrobeItem.fromJson(json['bottom'] as Map<String, dynamic>),
      footwear: json['footwear'] == null
          ? null
          : WardrobeItem.fromJson(json['footwear'] as Map<String, dynamic>),
      accessory: json['accessory'] == null
          ? null
          : WardrobeItem.fromJson(json['accessory'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$SwipeClosetSelectionsImplToJson(
        _$SwipeClosetSelectionsImpl instance) =>
    <String, dynamic>{
      'top': instance.top,
      'bottom': instance.bottom,
      'footwear': instance.footwear,
      'accessory': instance.accessory,
    };
