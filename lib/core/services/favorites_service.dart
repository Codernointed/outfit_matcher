import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service to manage user favorites (wardrobe items and outfits)
/// Stores favorites in Firestore for cloud sync across devices
class FavoritesService {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== FAVORITE WARDROBE ITEMS ====================

  /// Get stream of favorite wardrobe item IDs for a user
  Stream<List<String>> watchFavoriteItemIds(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('favorite_items')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  /// Get favorite wardrobe item IDs (one-time fetch)
  Future<List<String>> getFavoriteItemIds(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('favorite_items')
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('❌ Error fetching favorite item IDs: $e');
      return [];
    }
  }

  /// Check if a wardrobe item is favorited
  Future<bool> isItemFavorited(String uid, String itemId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('favorite_items')
          .doc(itemId)
          .get();

      return doc.exists;
    } catch (e) {
      debugPrint('❌ Error checking favorite status: $e');
      return false;
    }
  }

  /// Add a wardrobe item to favorites
  Future<void> addFavoriteItem(String uid, String itemId) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('favorite_items')
          .doc(itemId)
          .set({'addedAt': FieldValue.serverTimestamp()});

      debugPrint('✅ Added item $itemId to favorites');

      // Update user's favorite count
      await _updateFavoriteItemCount(uid);
    } catch (e) {
      debugPrint('❌ Error adding favorite item: $e');
      rethrow;
    }
  }

  /// Remove a wardrobe item from favorites
  Future<void> removeFavoriteItem(String uid, String itemId) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('favorite_items')
          .doc(itemId)
          .delete();

      debugPrint('✅ Removed item $itemId from favorites');

      // Update user's favorite count
      await _updateFavoriteItemCount(uid);
    } catch (e) {
      debugPrint('❌ Error removing favorite item: $e');
      rethrow;
    }
  }

  /// Toggle favorite status of a wardrobe item
  Future<void> toggleFavoriteItem(String uid, String itemId) async {
    final isFavorited = await isItemFavorited(uid, itemId);

    if (isFavorited) {
      await removeFavoriteItem(uid, itemId);
    } else {
      await addFavoriteItem(uid, itemId);
    }
  }

  /// Update the user's favorite item count in their profile
  Future<void> _updateFavoriteItemCount(String uid) async {
    try {
      final count = await getFavoriteItemIds(uid).then((ids) => ids.length);

      await _firestore.collection('users').doc(uid).update({
        'favoriteCount': count,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('⚠️ Error updating favorite count: $e');
    }
  }

  // ==================== FAVORITE OUTFITS ====================

  /// Get stream of favorite outfit IDs for a user
  Stream<List<String>> watchFavoriteOutfitIds(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('favorite_outfits')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  /// Get favorite outfit IDs (one-time fetch)
  Future<List<String>> getFavoriteOutfitIds(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('favorite_outfits')
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('❌ Error fetching favorite outfit IDs: $e');
      return [];
    }
  }

  /// Check if an outfit is favorited
  Future<bool> isOutfitFavorited(String uid, String outfitId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('favorite_outfits')
          .doc(outfitId)
          .get();

      return doc.exists;
    } catch (e) {
      debugPrint('❌ Error checking outfit favorite status: $e');
      return false;
    }
  }

  /// Add an outfit to favorites
  Future<void> addFavoriteOutfit(String uid, String outfitId) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('favorite_outfits')
          .doc(outfitId)
          .set({'addedAt': FieldValue.serverTimestamp()});

      debugPrint('✅ Added outfit $outfitId to favorites');
    } catch (e) {
      debugPrint('❌ Error adding favorite outfit: $e');
      rethrow;
    }
  }

  /// Remove an outfit from favorites
  Future<void> removeFavoriteOutfit(String uid, String outfitId) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('favorite_outfits')
          .doc(outfitId)
          .delete();

      debugPrint('✅ Removed outfit $outfitId from favorites');
    } catch (e) {
      debugPrint('❌ Error removing favorite outfit: $e');
      rethrow;
    }
  }

  /// Toggle favorite status of an outfit
  Future<void> toggleFavoriteOutfit(String uid, String outfitId) async {
    final isFavorited = await isOutfitFavorited(uid, outfitId);

    if (isFavorited) {
      await removeFavoriteOutfit(uid, outfitId);
    } else {
      await addFavoriteOutfit(uid, outfitId);
    }
  }

  // ==================== BATCH OPERATIONS ====================

  /// Get all favorite items for a user (with full item data)
  /// Returns list of item IDs that can be used to fetch full WardrobeItem data
  Future<List<String>> getAllFavoriteItems(String uid) async {
    return getFavoriteItemIds(uid);
  }

  /// Get all favorite outfits for a user
  Future<List<String>> getAllFavoriteOutfits(String uid) async {
    return getFavoriteOutfitIds(uid);
  }

  /// Clear all favorites for a user (useful for account deletion)
  Future<void> clearAllFavorites(String uid) async {
    try {
      // Delete all favorite items
      final itemsSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('favorite_items')
          .get();

      for (final doc in itemsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete all favorite outfits
      final outfitsSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('favorite_outfits')
          .get();

      for (final doc in outfitsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Update favorite count
      await _firestore.collection('users').doc(uid).update({
        'favoriteCount': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Cleared all favorites for user $uid');
    } catch (e) {
      debugPrint('❌ Error clearing favorites: $e');
      rethrow;
    }
  }

  /// Get total favorites count (items + outfits)
  Future<int> getTotalFavoritesCount(String uid) async {
    final itemIds = await getFavoriteItemIds(uid);
    final outfitIds = await getFavoriteOutfitIds(uid);
    return itemIds.length + outfitIds.length;
  }
}
