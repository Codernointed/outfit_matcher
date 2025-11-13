import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:vestiq/core/models/wear_history_event.dart';

/// Service for managing wear history events in Firestore
class FirestoreWearHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection name for wear history
  static const String _collectionName = 'wear_history';

  // ==================== SAVE WEAR EVENT ====================

  /// Record a wear event
  Future<void> recordWearEvent(WearHistoryEvent event) async {
    try {
      await _firestore.collection(_collectionName).doc(event.id).set(
            event.toFirestore(),
          );

      debugPrint('✅ Recorded wear event: ${event.id}');
    } catch (e) {
      debugPrint('❌ Error recording wear event: $e');
      rethrow;
    }
  }

  // ==================== QUERY WEAR HISTORY ====================

  /// Get all wear events for a user
  Future<List<WearHistoryEvent>> getUserWearHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('wornAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => WearHistoryEvent.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching wear history: $e');
      return [];
    }
  }

  /// Get wear events for a specific item
  Future<List<WearHistoryEvent>> getItemWearHistory(
    String userId,
    String itemId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('itemId', isEqualTo: itemId)
          .orderBy('wornAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => WearHistoryEvent.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching item wear history: $e');
      return [];
    }
  }

  /// Get wear events for a specific outfit
  Future<List<WearHistoryEvent>> getOutfitWearHistory(
    String userId,
    String outfitId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('outfitId', isEqualTo: outfitId)
          .orderBy('wornAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => WearHistoryEvent.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching outfit wear history: $e');
      return [];
    }
  }

  /// Get wear events within a date range
  Future<List<WearHistoryEvent>> getWearHistoryByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('wornAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('wornAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('wornAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => WearHistoryEvent.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching wear history by date: $e');
      return [];
    }
  }

  // ==================== REAL-TIME STREAMS ====================

  /// Watch wear history for a user (real-time updates)
  Stream<List<WearHistoryEvent>> watchUserWearHistory(String userId) {
    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .orderBy('wornAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WearHistoryEvent.fromFirestore(doc))
            .toList());
  }

  // ==================== STATISTICS ====================

  /// Get total wear count for an item
  Future<int> getItemWearCount(String userId, String itemId) async {
    final history = await getItemWearHistory(userId, itemId);
    return history.length;
  }

  /// Get total wear count for an outfit
  Future<int> getOutfitWearCount(String userId, String outfitId) async {
    final history = await getOutfitWearHistory(userId, outfitId);
    return history.length;
  }

  /// Get most worn items (by count)
  Future<Map<String, int>> getMostWornItems(String userId, {int limit = 10}) async {
    final allHistory = await getUserWearHistory(userId);
    final itemCounts = <String, int>{};

    for (final event in allHistory) {
      if (event.itemId != null) {
        itemCounts[event.itemId!] = (itemCounts[event.itemId!] ?? 0) + 1;
      }
    }

    // Sort by count and return top N
    final sorted = itemCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sorted.take(limit));
  }

  /// Get wear frequency by occasion
  Future<Map<String, int>> getWearFrequencyByOccasion(String userId) async {
    final allHistory = await getUserWearHistory(userId);
    final occasionCounts = <String, int>{};

    for (final event in allHistory) {
      if (event.occasion != null && event.occasion!.isNotEmpty) {
        occasionCounts[event.occasion!] = (occasionCounts[event.occasion!] ?? 0) + 1;
      }
    }

    return occasionCounts;
  }

  // ==================== DELETE ====================

  /// Delete a wear event
  Future<void> deleteWearEvent(String eventId) async {
    try {
      await _firestore.collection(_collectionName).doc(eventId).delete();
      debugPrint('✅ Deleted wear event: $eventId');
    } catch (e) {
      debugPrint('❌ Error deleting wear event: $e');
      rethrow;
    }
  }

  /// Delete all wear events for an item (when item is deleted)
  Future<void> deleteItemWearHistory(String userId, String itemId) async {
    try {
      final events = await getItemWearHistory(userId, itemId);
      for (final event in events) {
        await deleteWearEvent(event.id);
      }
      debugPrint('✅ Deleted ${events.length} wear events for item $itemId');
    } catch (e) {
      debugPrint('❌ Error deleting item wear history: $e');
      rethrow;
    }
  }
}
