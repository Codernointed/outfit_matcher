import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vestiq/core/models/profile_data.dart';
import 'package:vestiq/core/models/wardrobe_item.dart';
import 'package:vestiq/core/models/saved_outfit.dart';
import 'package:vestiq/core/services/profile_service.dart';
import 'package:vestiq/core/services/enhanced_wardrobe_storage_service.dart';
import 'package:vestiq/core/services/outfit_storage_service.dart';
import 'package:vestiq/core/di/service_locator.dart';
import 'package:vestiq/core/utils/logger.dart';

/// Provider for user profile data
final profileProvider = FutureProvider.autoDispose<ProfileData>((ref) async {
  final profileService = getIt<ProfileService>();
  return await profileService.getProfile();
});

/// Provider for profile statistics
final profileStatsProvider = FutureProvider.autoDispose<ProfileStats>((
  ref,
) async {
  try {
    final wardrobeService = getIt<EnhancedWardrobeStorageService>();
    final outfitService = getIt<OutfitStorageService>();

    final items = await wardrobeService.getWardrobeItems();
    final looks = await outfitService.fetchAll();
    final totalWears = items.fold<int>(0, (sum, item) => sum + item.wearCount);

    AppLogger.info(
      '📊 Profile stats: ${items.length} items, ${looks.length} looks, $totalWears wears',
    );

    return ProfileStats(
      itemsCount: items.length,
      looksCount: looks.length,
      totalWears: totalWears,
    );
  } catch (e) {
    AppLogger.error('❌ Error loading profile stats', error: e);
    return const ProfileStats.empty();
  }
});

/// Provider for favorite items
final favoriteItemsProvider = FutureProvider.autoDispose<List<WardrobeItem>>((
  ref,
) async {
  try {
    final wardrobeService = getIt<EnhancedWardrobeStorageService>();
    final allItems = await wardrobeService.getWardrobeItems();
    final favorites = allItems
        .where((item) => item.isFavorite == true)
        .toList();

    AppLogger.info('⭐ Loaded ${favorites.length} favorite items');
    return favorites;
  } catch (e) {
    AppLogger.error('❌ Error loading favorite items', error: e);
    return [];
  }
});

/// Provider for favorite outfits
final favoriteLooksProvider = FutureProvider.autoDispose<List<SavedOutfit>>((
  ref,
) async {
  try {
    final outfitService = getIt<OutfitStorageService>();
    final allLooks = await outfitService.fetchAll();
    final favorites = allLooks
        .where((look) => look.isFavorite ?? false)
        .toList();

    AppLogger.info('⭐ Loaded ${favorites.length} favorite looks');
    return favorites;
  } catch (e) {
    AppLogger.error('❌ Error loading favorite looks', error: e);
    return [];
  }
});

/// Combined favorites count
final favoritesCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final items = await ref.watch(favoriteItemsProvider.future);
  final looks = await ref.watch(favoriteLooksProvider.future);
  return items.length + looks.length;
});
