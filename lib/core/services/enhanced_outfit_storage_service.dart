import 'package:flutter/foundation.dart';
import 'package:vestiq/core/models/saved_outfit.dart';
import 'package:vestiq/core/services/outfit_storage_service.dart';
import 'package:vestiq/features/outfit_suggestions/data/firestore_outfit_service.dart';
import 'package:vestiq/features/auth/domain/services/user_profile_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vestiq/core/di/service_locator.dart';
import 'package:vestiq/core/services/analytics_service.dart';

/// Enhanced outfit storage service with Firestore sync
/// Provides dual-layer storage: Firestore (cloud) + SharedPreferences (local cache)
class EnhancedOutfitStorageService {
  final OutfitStorageService _localService;
  final FirestoreOutfitService _firestoreService;
  final UserProfileService _userProfileService;

  bool _hasMigratedToFirestore = false;

  EnhancedOutfitStorageService({
    required OutfitStorageService localService,
    required FirestoreOutfitService firestoreService,
    required UserProfileService userProfileService,
  }) : _localService = localService,
       _firestoreService = firestoreService,
       _userProfileService = userProfileService;

  // ==================== SAVE OUTFIT ====================

  /// Save an outfit (cloud + local)
  /// RESILIENT: Always saves locally even if Firestore fails
  Future<SavedOutfit> saveOutfit(SavedOutfit outfit) async {
    bool firestoreSaved = false;

    try {
      final user = FirebaseAuth.instance.currentUser;

      // Try Firestore if user is logged in
      if (user != null) {
        try {
          // Save to Firestore
          await _firestoreService.saveOutfit(user.uid, outfit);
          firestoreSaved = true;
          debugPrint('☁️ Saved outfit to Firestore: ${outfit.id}');

          // Update user's saved outfit count
          try {
            final count = await _firestoreService.getOutfitCount(user.uid);
            await _userProfileService.updateSavedOutfitCount(user.uid, count);
          } catch (profileError) {
            debugPrint('⚠️ Failed to update profile count: $profileError');
          }

          // Attempt migration if not done yet
          if (!_hasMigratedToFirestore) {
            try {
              await _attemptFirestoreMigration(user.uid);
            } catch (migrationError) {
              debugPrint('⚠️ Migration failed: $migrationError');
            }
          }
        } catch (firestoreError) {
          debugPrint(
            '⚠️ Firestore save failed, saving locally: $firestoreError',
          );
          // Continue to local save - don't rethrow
        }
      }

      // ALWAYS save to local cache (works even if Firestore fails)
      await _localService.save(outfit);
      debugPrint(
        '✅ Saved outfit locally: ${outfit.id} (Firestore: $firestoreSaved)',
      );

      // Track the save event
      getIt<AnalyticsService>().logOutfitSaved(
        occasion: outfit.occasion,
        itemsCount: outfit.items.length,
      );

      return outfit;
    } catch (e) {
      debugPrint('❌ CRITICAL: Failed to save outfit even locally: $e');
      rethrow;
    }
  }

  // ==================== GET OUTFITS ====================

  /// Get all outfits (cloud-first with local fallback)
  Future<List<SavedOutfit>> fetchAll() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Try to get from Firestore
        final firestoreOutfits = await _firestoreService.getAllOutfits(
          user.uid,
        );

        if (firestoreOutfits.isNotEmpty) {
          // Cache to local storage
          for (final outfit in firestoreOutfits) {
            await _localService.save(outfit);
          }

          debugPrint(
            '✅ Loaded ${firestoreOutfits.length} outfits from Firestore',
          );
          return firestoreOutfits;
        }

        // Attempt migration if Firestore is empty
        if (!_hasMigratedToFirestore) {
          await _attemptFirestoreMigration(user.uid);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching from Firestore, using local: $e');
    }

    // Fallback to local storage
    final localOutfits = await _localService.fetchAll();
    debugPrint('📦 Loaded ${localOutfits.length} outfits from local cache');
    return localOutfits;
  }

  /// Get a single outfit by ID
  Future<SavedOutfit?> getOutfitById(String outfitId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final outfit = await _firestoreService.getOutfit(user.uid, outfitId);
        if (outfit != null) {
          return outfit;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching outfit from Firestore: $e');
    }

    // Fallback to local
    final allOutfits = await _localService.fetchAll();
    try {
      return allOutfits.firstWhere((o) => o.id == outfitId);
    } catch (e) {
      return null;
    }
  }

  // ==================== REAL-TIME STREAM ====================

  /// Watch outfits with real-time updates (Firestore stream)
  Stream<List<SavedOutfit>> watchUserOutfits() {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      return _firestoreService.watchUserOutfits(user.uid);
    }

    // Fallback to empty stream if not logged in
    return Stream.value([]);
  }

  // ==================== DELETE OUTFIT ====================

  /// Delete an outfit (cloud + local)
  Future<void> deleteOutfit(String outfitId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Delete from Firestore
        await _firestoreService.deleteOutfit(user.uid, outfitId);
        debugPrint('✅ Deleted outfit from Firestore: $outfitId');

        // Update user's saved outfit count
        final count = await _firestoreService.getOutfitCount(user.uid);
        await _userProfileService.updateSavedOutfitCount(user.uid, count);
      }

      // Delete from local
      await _localService.delete(outfitId);
      debugPrint('✅ Deleted outfit from local cache: $outfitId');
    } catch (e) {
      debugPrint('❌ Error deleting outfit: $e');

      // Try local delete anyway
      await _localService.delete(outfitId);
    }
  }

  // ==================== MIGRATION ====================

  /// Migrate local outfits to Firestore (one-time)
  Future<void> _attemptFirestoreMigration(String userId) async {
    try {
      debugPrint('🔄 Attempting to migrate local outfits to Firestore...');

      // Get local outfits
      final localOutfits = await _localService.fetchAll();

      if (localOutfits.isEmpty) {
        debugPrint('ℹ️ No local outfits to migrate');
        _hasMigratedToFirestore = true;
        return;
      }

      // Check if Firestore already has outfits
      final firestoreOutfits = await _firestoreService.getAllOutfits(userId);

      if (firestoreOutfits.isNotEmpty) {
        debugPrint('ℹ️ Firestore already has outfits, skipping migration');
        _hasMigratedToFirestore = true;
        return;
      }

      // Bulk upload to Firestore
      await _firestoreService.bulkSaveOutfits(userId, localOutfits);
      debugPrint('✅ Migrated ${localOutfits.length} outfits to Firestore');

      // Update user's outfit count
      await _userProfileService.updateSavedOutfitCount(
        userId,
        localOutfits.length,
      );

      _hasMigratedToFirestore = true;
    } catch (e) {
      debugPrint('❌ Error migrating outfits to Firestore: $e');
    }
  }

  // ==================== LISTENERS ====================

  /// Add a listener for outfit changes
  void addOnChangeListener(VoidCallback callback) {
    _localService.addOnChangeListener(callback);
  }

  /// Remove a listener
  void removeOnChangeListener(VoidCallback callback) {
    _localService.removeOnChangeListener(callback);
  }

  // ==================== STATISTICS ====================

  /// Get outfit count
  Future<int> getOutfitCount() async {
    final outfits = await fetchAll();
    return outfits.length;
  }

  /// Get outfits by occasion
  Future<List<SavedOutfit>> getOutfitsByOccasion(String occasion) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        return await _firestoreService.getOutfitsByOccasion(user.uid, occasion);
      } catch (e) {
        debugPrint('⚠️ Error fetching outfits by occasion from Firestore: $e');
      }
    }

    // Fallback to local filter
    final allOutfits = await fetchAll();
    return allOutfits.where((o) => o.occasion == occasion).toList();
  }
}
