import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vestiq/core/models/saved_outfit.dart';
import 'package:vestiq/core/utils/logger.dart';

/// Service for managing generation history (auto-saved generations)
class FirestoreGenerationHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get history collection for a user
  CollectionReference<Map<String, dynamic>> _getUserHistoryCollection(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('generation_history');
  }

  /// Save a generated outfit to history
  Future<void> saveToHistory(String userId, SavedOutfit outfit) async {
    try {
      await _getUserHistoryCollection(
        userId,
      ).doc(outfit.id).set(outfit.toJson());
      AppLogger.info('📜 Saved generation to History: ${outfit.id}');
    } catch (e) {
      AppLogger.error('❌ Error saving to history: $e');
      // Don't rethrow, history saving failure shouldn't block the user
    }
  }

  /// Get all history for a user (most recent first)
  Future<List<SavedOutfit>> getHistory(String userId, {int limit = 50}) async {
    try {
      final snapshot = await _getUserHistoryCollection(
        userId,
      ).orderBy('createdAt', descending: true).limit(limit).get();

      return snapshot.docs
          .map((doc) => SavedOutfit.fromJson(doc.data()))
          .toList();
    } catch (e) {
      AppLogger.error('❌ Error fetching history: $e');
      return [];
    }
  }

  /// Watch history stream
  Stream<List<SavedOutfit>> watchHistory(String userId, {int limit = 50}) {
    return _getUserHistoryCollection(userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SavedOutfit.fromJson(doc.data()))
              .toList(),
        );
  }

  /// Delete a history item
  Future<void> deleteFromHistory(String userId, String id) async {
    try {
      await _getUserHistoryCollection(userId).doc(id).delete();
    } catch (e) {
      AppLogger.error('❌ Error deleting history item: $e');
      rethrow;
    }
  }
}
