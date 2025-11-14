import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:vestiq/core/models/saved_outfit.dart';

/// Service for managing saved outfits in Firestore
class FirestoreOutfitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get outfits collection for a user
  CollectionReference<Map<String, dynamic>> _getUserOutfitsCollection(
    String userId,
  ) {
    return _firestore.collection('users').doc(userId).collection('outfits');
  }

  // ==================== SAVE OUTFIT ====================

  /// Save an outfit to Firestore
  Future<void> saveOutfit(String userId, SavedOutfit outfit) async {
    try {
      await _getUserOutfitsCollection(
        userId,
      ).doc(outfit.id).set(outfit.toJson());

      debugPrint('✅ Saved outfit to Firestore: ${outfit.id}');
    } catch (e) {
      debugPrint('❌ Error saving outfit to Firestore: $e');
      rethrow;
    }
  }

  /// Bulk save outfits (for migration)
  Future<void> bulkSaveOutfits(String userId, List<SavedOutfit> outfits) async {
    try {
      final batch = _firestore.batch();
      final collection = _getUserOutfitsCollection(userId);

      for (final outfit in outfits) {
        batch.set(collection.doc(outfit.id), outfit.toJson());
      }

      await batch.commit();
      debugPrint('✅ Bulk saved ${outfits.length} outfits to Firestore');
    } catch (e) {
      debugPrint('❌ Error bulk saving outfits: $e');
      rethrow;
    }
  }

  // ==================== GET OUTFITS ====================

  /// Get all outfits for a user
  Future<List<SavedOutfit>> getAllOutfits(String userId) async {
    try {
      final snapshot = await _getUserOutfitsCollection(
        userId,
      ).orderBy('createdAt', descending: true).get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return SavedOutfit.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('❌ Error fetching outfits from Firestore: $e');
      return [];
    }
  }

  /// Get a single outfit by ID
  Future<SavedOutfit?> getOutfit(String userId, String outfitId) async {
    try {
      final doc = await _getUserOutfitsCollection(userId).doc(outfitId).get();

      if (!doc.exists) {
        return null;
      }

      return SavedOutfit.fromJson(doc.data()!);
    } catch (e) {
      debugPrint('❌ Error fetching outfit: $e');
      return null;
    }
  }

  // ==================== REAL-TIME STREAMS ====================

  /// Watch outfits for a user (real-time updates)
  Stream<List<SavedOutfit>> watchUserOutfits(String userId) {
    return _getUserOutfitsCollection(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return SavedOutfit.fromJson(data);
          }).toList(),
        );
  }

  // ==================== UPDATE ====================

  /// Update an outfit
  Future<void> updateOutfit(String userId, SavedOutfit outfit) async {
    try {
      await _getUserOutfitsCollection(
        userId,
      ).doc(outfit.id).update(outfit.toJson());

      debugPrint('✅ Updated outfit: ${outfit.id}');
    } catch (e) {
      debugPrint('❌ Error updating outfit: $e');
      rethrow;
    }
  }

  // ==================== DELETE ====================

  /// Delete an outfit
  Future<void> deleteOutfit(String userId, String outfitId) async {
    try {
      await _getUserOutfitsCollection(userId).doc(outfitId).delete();
      debugPrint('✅ Deleted outfit from Firestore: $outfitId');
    } catch (e) {
      debugPrint('❌ Error deleting outfit: $e');
      rethrow;
    }
  }

  /// Delete all outfits for a user
  Future<void> deleteAllOutfits(String userId) async {
    try {
      final snapshot = await _getUserOutfitsCollection(userId).get();
      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('✅ Deleted all outfits for user $userId');
    } catch (e) {
      debugPrint('❌ Error deleting all outfits: $e');
      rethrow;
    }
  }

  // ==================== STATISTICS ====================

  /// Get total outfit count for a user
  Future<int> getOutfitCount(String userId) async {
    try {
      final snapshot = await _getUserOutfitsCollection(userId).count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('❌ Error getting outfit count: $e');
      return 0;
    }
  }

  /// Get outfits by occasion
  Future<List<SavedOutfit>> getOutfitsByOccasion(
    String userId,
    String occasion,
  ) async {
    try {
      final snapshot = await _getUserOutfitsCollection(userId)
          .where('occasion', isEqualTo: occasion)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return SavedOutfit.fromJson(data);
      }).toList();
    } catch (e) {
      debugPrint('❌ Error fetching outfits by occasion: $e');
      return [];
    }
  }
}
