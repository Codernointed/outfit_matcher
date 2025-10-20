// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'swipe_closet_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SwipeClosetRequestImpl _$$SwipeClosetRequestImplFromJson(
        Map<String, dynamic> json) =>
    _$SwipeClosetRequestImpl(
      occasion: json['occasion'] as String,
      mood: json['mood'] as String?,
      weather: json['weather'] as String?,
      colorPreference: json['colorPreference'] as String?,
      notes: json['notes'] as String?,
      gender: json['gender'] as String? ?? '',
    );

Map<String, dynamic> _$$SwipeClosetRequestImplToJson(
        _$SwipeClosetRequestImpl instance) =>
    <String, dynamic>{
      'occasion': instance.occasion,
      'mood': instance.mood,
      'weather': instance.weather,
      'colorPreference': instance.colorPreference,
      'notes': instance.notes,
      'gender': instance.gender,
    };

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
