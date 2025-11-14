import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:vestiq/core/models/swipe_closet_request.dart';
import 'package:vestiq/core/models/wardrobe_item.dart';
import 'package:vestiq/core/services/enhanced_wardrobe_storage_service.dart';
import 'package:vestiq/core/di/service_locator.dart';
import 'package:vestiq/core/utils/logger.dart';

part 'swipe_planner_providers.freezed.dart';
part 'swipe_planner_providers.g.dart';

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

@freezed
class SwipeClosetSelections with _$SwipeClosetSelections {
  const factory SwipeClosetSelections({
    WardrobeItem? top,
    WardrobeItem? bottom,
    WardrobeItem? footwear,
    WardrobeItem? accessory,
  }) = _SwipeClosetSelections;

  factory SwipeClosetSelections.fromJson(Map<String, dynamic> json) =>
      _$SwipeClosetSelectionsFromJson(json);
}

// Current swipe request state
final swipeRequestProvider = StateProvider<SwipeClosetRequest?>((ref) => null);

// Filtered item pools for swipe closet
final swipeClosetPoolsProvider = FutureProvider.autoDispose<SwipeClosetPools>((
  ref,
) async {
  final request = ref.watch(swipeRequestProvider);
  final storage = getIt<EnhancedWardrobeStorageService>();

  // Get ALL items first
  final allItems = await storage.getWardrobeItems();

  AppLogger.info('🎯 Total wardrobe items: ${allItems.length}');

  if (request == null || allItems.isEmpty) {
    // Return all items categorized if no request or empty wardrobe
    return SwipeClosetPools(
      tops: allItems
          .where(
            (item) =>
                item.analysis.itemType.toLowerCase().contains('top') ||
                item.analysis.itemType.toLowerCase().contains('shirt') ||
                item.analysis.itemType.toLowerCase().contains('blouse'),
          )
          .toList(),
      bottoms: allItems
          .where(
            (item) =>
                item.analysis.itemType.toLowerCase().contains('bottom') ||
                item.analysis.itemType.toLowerCase().contains('pants') ||
                item.analysis.itemType.toLowerCase().contains('jeans') ||
                item.analysis.itemType.toLowerCase().contains('skirt'),
          )
          .toList(),
      footwear: allItems
          .where(
            (item) =>
                item.analysis.itemType.toLowerCase().contains('shoe') ||
                item.analysis.itemType.toLowerCase().contains('footwear') ||
                item.analysis.itemType.toLowerCase().contains('boot') ||
                item.analysis.itemType.toLowerCase().contains('sneaker'),
          )
          .toList(),
      accessories: allItems
          .where(
            (item) =>
                item.analysis.itemType.toLowerCase().contains('accessory') ||
                item.analysis.itemType.toLowerCase().contains('jewelry') ||
                item.analysis.itemType.toLowerCase().contains('belt') ||
                item.analysis.itemType.toLowerCase().contains('bag'),
          )
          .toList(),
    );
  }

  AppLogger.info('🔍 Filtering items for occasion: ${request.occasion}');

  try {
    // Try filtering with lenient approach - don't filter by category first
    final filtered = await storage.getFilteredWardrobeItems(
      occasion: request.occasion,
      mood: request.mood,
      weather: request.weather,
      colorPreference: request.colorPreference,
    );

    AppLogger.info('📊 Filtered items: ${filtered.length}');

    // If filtering returns nothing or very few items, use all items
    final itemsToUse = (filtered.length < 2) ? allItems : filtered;

    if (filtered.length < 2) {
      AppLogger.info(
        '⚠️ Too few filtered items, using all ${allItems.length} items',
      );
    }

    final pools = SwipeClosetPools(
      tops: itemsToUse
          .where(
            (item) =>
                item.analysis.itemType.toLowerCase().contains('top') ||
                item.analysis.itemType.toLowerCase().contains('shirt') ||
                item.analysis.itemType.toLowerCase().contains('blouse'),
          )
          .toList(),
      bottoms: itemsToUse
          .where(
            (item) =>
                item.analysis.itemType.toLowerCase().contains('bottom') ||
                item.analysis.itemType.toLowerCase().contains('pants') ||
                item.analysis.itemType.toLowerCase().contains('jeans') ||
                item.analysis.itemType.toLowerCase().contains('skirt'),
          )
          .toList(),
      footwear: itemsToUse
          .where(
            (item) =>
                item.analysis.itemType.toLowerCase().contains('shoe') ||
                item.analysis.itemType.toLowerCase().contains('footwear') ||
                item.analysis.itemType.toLowerCase().contains('boot') ||
                item.analysis.itemType.toLowerCase().contains('sneaker'),
          )
          .toList(),
      accessories: itemsToUse
          .where(
            (item) =>
                item.analysis.itemType.toLowerCase().contains('accessory') ||
                item.analysis.itemType.toLowerCase().contains('jewelry') ||
                item.analysis.itemType.toLowerCase().contains('belt') ||
                item.analysis.itemType.toLowerCase().contains('bag'),
          )
          .toList(),
    );

    AppLogger.info(
      '✅ Swipe closet pools loaded',
      data: {
        'tops': pools.tops.length,
        'bottoms': pools.bottoms.length,
        'footwear': pools.footwear.length,
        'accessories': pools.accessories.length,
      },
    );

    return pools;
  } catch (e, stackTrace) {
    AppLogger.error(
      '❌ Filtering error, using all items',
      error: e,
      stackTrace: stackTrace,
    );
    // Fall back to all items on error
    return SwipeClosetPools(
      tops: allItems
          .where(
            (item) =>
                item.analysis.itemType.toLowerCase().contains('top') ||
                item.analysis.itemType.toLowerCase().contains('shirt') ||
                item.analysis.itemType.toLowerCase().contains('blouse'),
          )
          .toList(),
      bottoms: allItems
          .where(
            (item) =>
                item.analysis.itemType.toLowerCase().contains('bottom') ||
                item.analysis.itemType.toLowerCase().contains('pants') ||
                item.analysis.itemType.toLowerCase().contains('jeans') ||
                item.analysis.itemType.toLowerCase().contains('skirt'),
          )
          .toList(),
      footwear: allItems
          .where(
            (item) =>
                item.analysis.itemType.toLowerCase().contains('shoe') ||
                item.analysis.itemType.toLowerCase().contains('footwear') ||
                item.analysis.itemType.toLowerCase().contains('boot') ||
                item.analysis.itemType.toLowerCase().contains('sneaker'),
          )
          .toList(),
      accessories: allItems
          .where(
            (item) =>
                item.analysis.itemType.toLowerCase().contains('accessory') ||
                item.analysis.itemType.toLowerCase().contains('jewelry') ||
                item.analysis.itemType.toLowerCase().contains('belt') ||
                item.analysis.itemType.toLowerCase().contains('bag'),
          )
          .toList(),
    );
  }
});

// Current selections in swipe closet
final swipeClosetSelectionsProvider =
    StateProvider.autoDispose<SwipeClosetSelections>((ref) {
      return const SwipeClosetSelections();
    });
