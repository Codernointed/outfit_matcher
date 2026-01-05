import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vestiq/core/models/profile_data.dart';
import 'package:vestiq/core/models/wardrobe_item.dart';
import 'package:vestiq/core/models/saved_outfit.dart';
import 'package:vestiq/core/services/profile_service.dart';
import 'package:vestiq/core/services/enhanced_wardrobe_storage_service.dart';
import 'package:vestiq/core/services/outfit_storage_service.dart';
import 'package:vestiq/core/services/favorites_service.dart';
import 'package:vestiq/core/di/service_locator.dart';
import 'package:vestiq/core/utils/logger.dart';
import 'package:vestiq/features/auth/domain/services/user_profile_service.dart';
import 'package:vestiq/features/auth/presentation/providers/auth_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Provider for user profile data
final profileProvider = FutureProvider.autoDispose<ProfileData>((ref) async {
  final profileService = getIt<ProfileService>();
  return await profileService.getProfile();
});

/// Provider for profile statistics (FIRESTORE-POWERED!)
final profileStatsProvider = FutureProvider.autoDispose<ProfileStats>((
  ref,
) async {
  try {
    // Try to get from Firestore first
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      try {
        final userProfileService = getIt<UserProfileService>();
        final appUser = await userProfileService.getUserProfile(
          currentUser.uid,
        );

        if (appUser != null) {
          AppLogger.info(
            '📊 Profile stats from Firestore: ${appUser.wardrobeItemCount} items, '
            '${appUser.savedOutfitCount} looks, ${appUser.totalGenerations} generations',
          );

          return ProfileStats(
            itemsCount: appUser.wardrobeItemCount,
            looksCount: appUser.savedOutfitCount,
            totalWears: appUser.totalWears,
          );
        }
      } catch (e) {
        AppLogger.warning(
          '⚠️ Failed to get stats from Firestore, falling back to local',
          error: e,
        );
      }
    }

    // Fallback to local storage
    final wardrobeService = getIt<EnhancedWardrobeStorageService>();
    final outfitService = getIt<OutfitStorageService>();

    final items = await wardrobeService.getWardrobeItems();
    final looks = await outfitService.fetchAll();
    final totalWears = items.fold<int>(0, (sum, item) => sum + item.wearCount);

    AppLogger.info(
      '📊 Profile stats from local: ${items.length} items, ${looks.length} looks, $totalWears wears',
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

/// Provider for favorite items (FIRESTORE STREAMS!)
final favoriteItemsProvider = StreamProvider.autoDispose<List<WardrobeItem>>((
  ref,
) async* {
  try {
    // Get current user
    final user = ref.watch(currentUserProvider).value;
    if (user == null) {
      AppLogger.info('⭐ No user logged in, returning empty favorites');
      yield [];
      return;
    }

    // Get favorite IDs from Firestore (real-time stream)
    final favoritesService = FavoritesService();
    final wardrobeService = getIt<EnhancedWardrobeStorageService>();

    await for (final favoriteIds in favoritesService.watchFavoriteItemIds(
      user.uid,
    )) {
      if (favoriteIds.isEmpty) {
        yield [];
        continue;
      }

      // Fetch full item data for each favorite ID
      final allItems = await wardrobeService.getWardrobeItems();
      final favoriteItems = allItems
          .where((item) => favoriteIds.contains(item.id))
          .toList();

      AppLogger.info(
        '⭐ Loaded ${favoriteItems.length} favorite items from Firestore stream',
      );
      yield favoriteItems;
    }
  } catch (e) {
    AppLogger.error('❌ Error loading favorite items', error: e);
    yield [];
  }
});

/// Provider for favorite outfits (FIRESTORE STREAMS!)
final favoriteLooksProvider = StreamProvider.autoDispose<List<SavedOutfit>>((
  ref,
) async* {
  try {
    // Get current user
    final user = ref.watch(currentUserProvider).value;
    if (user == null) {
      AppLogger.info('⭐ No user logged in, returning empty favorite looks');
      yield [];
      return;
    }

    // Get favorite outfit IDs from Firestore (real-time stream)
    final favoritesService = FavoritesService();
    final outfitService = getIt<OutfitStorageService>();

    await for (final favoriteIds in favoritesService.watchFavoriteOutfitIds(
      user.uid,
    )) {
      if (favoriteIds.isEmpty) {
        yield [];
        continue;
      }

      // Fetch full outfit data for each favorite ID
      final allLooks = await outfitService.fetchAll();
      final favoriteLooks = allLooks
          .where((look) => favoriteIds.contains(look.id))
          .toList();

      AppLogger.info(
        '⭐ Loaded ${favoriteLooks.length} favorite looks from Firestore stream',
      );
      yield favoriteLooks;
    }
  } catch (e) {
    AppLogger.error('❌ Error loading favorite looks', error: e);
    yield [];
  }
});

/// Combined favorites count (updated for streams)
final favoritesCountProvider = Provider.autoDispose<int>((ref) {
  final items = ref.watch(favoriteItemsProvider).value ?? [];
  final looks = ref.watch(favoriteLooksProvider).value ?? [];
  return items.length + looks.length;
});
