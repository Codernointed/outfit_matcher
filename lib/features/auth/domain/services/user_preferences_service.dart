import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:vestiq/core/models/user_preferences.dart';
import 'package:vestiq/core/models/wardrobe_item.dart';
import 'package:vestiq/core/models/saved_outfit.dart';

/// Service for tracking and learning user style preferences
/// This powers intelligent outfit generation that gets smarter over time
class UserPreferencesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection name for user preferences
  static const String _collectionName = 'user_preferences';

  // ==================== GET/CREATE PREFERENCES ====================

  /// Get user preferences (creates if doesn't exist)
  Future<UserPreferences> getUserPreferences(String userId) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(userId)
          .get();

      if (!doc.exists) {
        // Create empty preferences for new user
        final newPrefs = UserPreferences.empty(userId);
        await _savePreferences(newPrefs);
        return newPrefs;
      }

      return UserPreferences.fromFirestore(doc);
    } catch (e) {
      debugPrint('❌ Error fetching user preferences: $e');
      return UserPreferences.empty(userId);
    }
  }

  /// Save preferences to Firestore
  Future<void> _savePreferences(UserPreferences prefs) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(prefs.userId)
          .set(prefs.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('❌ Error saving preferences: $e');
    }
  }

  // ==================== TRACK USER ACTIONS ====================

  /// Track when user generates an outfit
  Future<void> trackOutfitGeneration(String userId) async {
    try {
      final prefs = await getUserPreferences(userId);
      final updated = prefs.copyWith(
        totalGenerations: prefs.totalGenerations + 1,
        lastUpdated: DateTime.now(),
      );
      await _savePreferences(updated);
    } catch (e) {
      debugPrint('❌ Error tracking generation: $e');
    }
  }

  /// Track when user saves an outfit (learns from this!)
  Future<void> trackOutfitSave(
    String userId,
    SavedOutfit outfit, {
    bool wasGenerated = true,
  }) async {
    try {
      final prefs = await getUserPreferences(userId);

      // Extract preferences from saved outfit
      final colors = <String, int>{...prefs.favoriteColors};
      final styles = <String, int>{...prefs.favoriteStyles};
      final occasions = <String, int>{...prefs.favoriteOccasions};
      final categories = <String, int>{...prefs.mostSavedCategories};
      final pairings = <String, int>{...prefs.successfulPairings};

      // Update color preferences
      for (final item in outfit.items) {
        final color = item.primaryColor;
        colors[color] = (colors[color] ?? 0) + 1;

        final category = item.itemType;
        categories[category] = (categories[category] ?? 0) + 1;
      }

      // Update style preferences
      if (outfit.style.isNotEmpty) {
        styles[outfit.style] = (styles[outfit.style] ?? 0) + 1;
      }

      // Update occasion preferences
      if (outfit.occasion.isNotEmpty) {
        occasions[outfit.occasion] = (occasions[outfit.occasion] ?? 0) + 1;
      }

      // Track successful pairings (if 2+ items)
      if (outfit.items.length >= 2) {
        for (var i = 0; i < outfit.items.length; i++) {
          for (var j = i + 1; j < outfit.items.length; j++) {
            final cat1 = outfit.items[i].itemType;
            final cat2 = outfit.items[j].itemType;
            final key = _createPairingKey(cat1, cat2);
            pairings[key] = (pairings[key] ?? 0) + 1;
          }
        }
      }

      // Calculate new average match score
      final totalSaves = prefs.totalSaves + 1;
      final newAvgScore =
          (prefs.avgMatchScoreAccepted * prefs.totalSaves + outfit.matchScore) /
          totalSaves;

      final updated = prefs.copyWith(
        favoriteColors: colors,
        favoriteStyles: styles,
        favoriteOccasions: occasions,
        mostSavedCategories: categories,
        successfulPairings: pairings,
        avgMatchScoreAccepted: newAvgScore,
        totalSaves: totalSaves,
        lastUpdated: DateTime.now(),
      );

      await _savePreferences(updated);
      debugPrint('✅ Learned from outfit save: ${outfit.id}');
    } catch (e) {
      debugPrint('❌ Error tracking outfit save: $e');
    }
  }

  /// Track when user views an outfit (lighter signal than save)
  Future<void> trackOutfitView(String userId, SavedOutfit outfit) async {
    try {
      final prefs = await getUserPreferences(userId);
      final updated = prefs.copyWith(
        totalViews: prefs.totalViews + 1,
        lastUpdated: DateTime.now(),
      );
      await _savePreferences(updated);
    } catch (e) {
      debugPrint('❌ Error tracking view: $e');
    }
  }

  /// Track when user deletes/skips an outfit (learns what to avoid)
  Future<void> trackOutfitRejection(String userId, SavedOutfit outfit) async {
    try {
      final prefs = await getUserPreferences(userId);

      // Track avoided colors
      final avoidedColors = <String, int>{...prefs.avoidedColors};
      for (final item in outfit.items) {
        final color = item.primaryColor;
        avoidedColors[color] = (avoidedColors[color] ?? 0) + 1;
      }

      // Track rejected pairings
      final rejectedPairings = <String, int>{...prefs.rejectedPairings};
      if (outfit.items.length >= 2) {
        for (var i = 0; i < outfit.items.length; i++) {
          for (var j = i + 1; j < outfit.items.length; j++) {
            final cat1 = outfit.items[i].itemType;
            final cat2 = outfit.items[j].itemType;
            final key = _createPairingKey(cat1, cat2);
            rejectedPairings[key] = (rejectedPairings[key] ?? 0) + 1;
          }
        }
      }

      final updated = prefs.copyWith(
        avoidedColors: avoidedColors,
        rejectedPairings: rejectedPairings,
        lastUpdated: DateTime.now(),
      );

      await _savePreferences(updated);
      debugPrint('✅ Learned from outfit rejection');
    } catch (e) {
      debugPrint('❌ Error tracking rejection: $e');
    }
  }

  /// Track when user wears an item (strongest signal!)
  Future<void> trackItemWear(
    String userId,
    WardrobeItem item, {
    String? occasion,
  }) async {
    try {
      final prefs = await getUserPreferences(userId);

      // Update worn categories
      final wornCategories = <String, int>{...prefs.mostWornCategories};
      final category = item.analysis.itemType;
      wornCategories[category] = (wornCategories[category] ?? 0) + 1;

      // Update color preferences (wearing = strong signal)
      final colors = <String, int>{...prefs.favoriteColors};
      final color = item.analysis.primaryColor;
      colors[color] = (colors[color] ?? 0) + 2; // Double weight for actual wear

      // Track brand preferences
      final brands = <String, int>{...prefs.favoriteBrands};
      final brand = item.analysis.brand;
      if (brand != null && brand.isNotEmpty) {
        brands[brand] = (brands[brand] ?? 0) + 1;
      }

      // Track occasion patterns
      final occasions = <String, int>{...prefs.favoriteOccasions};
      if (occasion != null && occasion.isNotEmpty) {
        occasions[occasion] = (occasions[occasion] ?? 0) + 1;
      }

      final updated = prefs.copyWith(
        mostWornCategories: wornCategories,
        favoriteColors: colors,
        favoriteBrands: brands,
        favoriteOccasions: occasions,
        lastUpdated: DateTime.now(),
      );

      await _savePreferences(updated);
      debugPrint('✅ Learned from item wear: ${item.id}');
    } catch (e) {
      debugPrint('❌ Error tracking wear: $e');
    }
  }

  // ==================== PREFERENCE INSIGHTS ====================

  /// Get personalized recommendations based on learned preferences
  Map<String, dynamic> getRecommendations(UserPreferences prefs) {
    return {
      'topColors': prefs.getTopColors(5),
      'topStyles': prefs.getTopStyles(3),
      'topOccasions': prefs.getTopOccasions(3),
      'mostWornCategories': prefs.getMostWornCategories(5),
      'preferredMatchScore': prefs.avgMatchScoreAccepted,
      'hasLearningData': prefs.totalSaves > 0 || prefs.totalViews > 5,
    };
  }

  /// Calculate preference strength (0-1) for outfit generation weighting
  double getPreferenceStrength(UserPreferences prefs) {
    // More data = stronger preferences
    final dataPoints =
        prefs.totalSaves +
        (prefs.totalViews * 0.1) +
        prefs.totalGenerations * 0.05;

    // Sigmoid function to map data points to 0-1
    // 0 saves = 0.0, 50+ saves = ~0.9+
    return 1 / (1 + (50 / (dataPoints + 1)));
  }

  // ==================== HELPERS ====================

  /// Create consistent pairing key
  String _createPairingKey(String cat1, String cat2) {
    final sorted = [cat1, cat2]..sort();
    return sorted.join('+');
  }

  // ==================== REAL-TIME STREAM ====================

  /// Watch user preferences for real-time updates
  Stream<UserPreferences> watchUserPreferences(String userId) {
    return _firestore
        .collection(_collectionName)
        .doc(userId)
        .snapshots()
        .map(
          (doc) => doc.exists
              ? UserPreferences.fromFirestore(doc)
              : UserPreferences.empty(userId),
        );
  }
}
