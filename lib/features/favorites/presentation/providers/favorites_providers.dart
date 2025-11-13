import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vestiq/core/services/favorites_service.dart';
import 'package:vestiq/features/auth/presentation/providers/auth_providers.dart';

// ==================== SERVICE PROVIDER ====================

final favoritesServiceProvider = Provider<FavoritesService>((ref) {
  return FavoritesService();
});

// ==================== FAVORITE ITEMS PROVIDERS ====================

/// Stream provider for favorite wardrobe item IDs
final favoriteItemIdsProvider = StreamProvider<List<String>>((ref) {
  final user = ref.watch(currentUserProvider).value;

  if (user == null) {
    return Stream.value([]);
  }

  final favoritesService = ref.watch(favoritesServiceProvider);
  return favoritesService.watchFavoriteItemIds(user.uid);
});

/// Provider to check if a specific item is favorited
final isItemFavoritedProvider = FutureProvider.family<bool, String>((
  ref,
  itemId,
) async {
  final user = ref.watch(currentUserProvider).value;

  if (user == null) return false;

  final favoritesService = ref.watch(favoritesServiceProvider);
  return favoritesService.isItemFavorited(user.uid, itemId);
});

// ==================== FAVORITE OUTFITS PROVIDERS ====================

/// Stream provider for favorite outfit IDs
final favoriteOutfitIdsProvider = StreamProvider<List<String>>((ref) {
  final user = ref.watch(currentUserProvider).value;

  if (user == null) {
    return Stream.value([]);
  }

  final favoritesService = ref.watch(favoritesServiceProvider);
  return favoritesService.watchFavoriteOutfitIds(user.uid);
});

/// Provider to check if a specific outfit is favorited
final isOutfitFavoritedProvider = FutureProvider.family<bool, String>((
  ref,
  outfitId,
) async {
  final user = ref.watch(currentUserProvider).value;

  if (user == null) return false;

  final favoritesService = ref.watch(favoritesServiceProvider);
  return favoritesService.isOutfitFavorited(user.uid, outfitId);
});

// ==================== AGGREGATE PROVIDERS ====================

/// Provider for total favorites count
final totalFavoritesCountProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(currentUserProvider).value;

  if (user == null) return 0;

  final favoritesService = ref.watch(favoritesServiceProvider);
  return favoritesService.getTotalFavoritesCount(user.uid);
});

/// Provider for favorite items count only
final favoriteItemsCountProvider = Provider<int>((ref) {
  final itemIds = ref.watch(favoriteItemIdsProvider).value ?? [];
  return itemIds.length;
});

/// Provider for favorite outfits count only
final favoriteOutfitsCountProvider = Provider<int>((ref) {
  final outfitIds = ref.watch(favoriteOutfitIdsProvider).value ?? [];
  return outfitIds.length;
});
