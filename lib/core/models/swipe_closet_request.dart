import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:vestiq/core/models/wardrobe_item.dart';

part 'swipe_closet_request.freezed.dart';
part 'swipe_closet_request.g.dart';

@freezed
class SwipeClosetRequest with _$SwipeClosetRequest {
  const factory SwipeClosetRequest({
    required String occasion,
    String? mood,
    String? weather,
    String? colorPreference,
    String? notes,
    @Default('') String gender,
  }) = _SwipeClosetRequest;

  factory SwipeClosetRequest.fromJson(Map<String, dynamic> json) =>
      _$SwipeClosetRequestFromJson(json);
}

@freezed
class SwipeClosetPools with _$SwipeClosetPools {
  const factory SwipeClosetPools({
    @Default([]) List<WardrobeItem> tops,
    @Default([]) List<WardrobeItem> bottoms,
    @Default([]) List<WardrobeItem> footwear,
    @Default([]) List<WardrobeItem> accessories,
  }) = _SwipeClosetPools;

  factory SwipeClosetPools.fromJson(Map<String, dynamic> json) =>
      _$SwipeClosetPoolsFromJson(json);
}
