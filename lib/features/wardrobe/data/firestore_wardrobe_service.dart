import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vestiq/core/models/wardrobe_item.dart';
import 'package:vestiq/core/utils/logger.dart';

/// Firestore service for wardrobe items - cloud sync layer
class FirestoreWardrobeService {
  FirestoreWardrobeService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Get the current user's ID
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  /// Collection reference for wardrobe items
  CollectionReference<Map<String, dynamic>> _wardrobeCollection(String uid) =>
      _firestore.collection('users').doc(uid).collection('wardrobeItems');

  /// Collection reference for wardrobe looks
  CollectionReference<Map<String, dynamic>> _looksCollection(String uid) =>
      _firestore.collection('users').doc(uid).collection('wardrobeLooks');

  // ==================== WARDROBE ITEMS ====================

  /// Save a wardrobe item to Firestore
  Future<void> saveWardrobeItem(WardrobeItem item) async {
    final userId = _currentUserId;
    if (userId == null) {
      AppLogger.warning('⚠️ No user logged in, cannot save to Firestore');
      return;
    }

    try {
      AppLogger.debug('💾 Saving wardrobe item to Firestore: ${item.id}');

      await _wardrobeCollection(userId).doc(item.id).set(
        _wardrobeItemToFirestore(item),
      );

      AppLogger.info('✅ Wardrobe item saved to Firestore');
    } catch (e, stack) {
      AppLogger.error(
        '❌ Error saving wardrobe item to Firestore',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Get all wardrobe items for current user
  Future<List<WardrobeItem>> getAllWardrobeItems() async {
    final userId = _currentUserId;
    if (userId == null) {
      AppLogger.warning('⚠️ No user logged in, returning empty list');
      return [];
    }

    try {
      AppLogger.debug('📖 Fetching wardrobe items from Firestore');

      final snapshot = await _wardrobeCollection(userId).get();

      final items = snapshot.docs
          .map((doc) => _wardrobeItemFromFirestore(doc.data()))
          .whereType<WardrobeItem>()
          .toList();

      AppLogger.info('✅ Fetched ${items.length} wardrobe items from Firestore');
      return items;
    } catch (e, stack) {
      AppLogger.error(
        '❌ Error fetching wardrobe items from Firestore',
        error: e,
        stackTrace: stack,
      );
      return [];
    }
  }

  /// Stream of wardrobe items (real-time updates)
  Stream<List<WardrobeItem>> watchWardrobeItems() {
    final userId = _currentUserId;
    if (userId == null) {
      AppLogger.warning('⚠️ No user logged in, returning empty stream');
      return Stream.value([]);
    }

    return _wardrobeCollection(userId).snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => _wardrobeItemFromFirestore(doc.data()))
          .whereType<WardrobeItem>()
          .toList();

      AppLogger.debug('🔄 Wardrobe stream update: ${items.length} items');
      return items;
    });
  }

  /// Get a single wardrobe item
  Future<WardrobeItem?> getWardrobeItem(String itemId) async {
    final userId = _currentUserId;
    if (userId == null) return null;

    try {
      final doc = await _wardrobeCollection(userId).doc(itemId).get();
      if (!doc.exists) return null;

      return _wardrobeItemFromFirestore(doc.data()!);
    } catch (e) {
      AppLogger.error('❌ Error fetching wardrobe item', error: e);
      return null;
    }
  }

  /// Update a wardrobe item
  Future<void> updateWardrobeItem(WardrobeItem item) async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      await _wardrobeCollection(userId).doc(item.id).update(
        _wardrobeItemToFirestore(item),
      );

      AppLogger.info('✅ Wardrobe item updated in Firestore');
    } catch (e) {
      AppLogger.error('❌ Error updating wardrobe item', error: e);
      rethrow;
    }
  }

  /// Delete a wardrobe item
  Future<void> deleteWardrobeItem(String itemId) async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      await _wardrobeCollection(userId).doc(itemId).delete();
      AppLogger.info('✅ Wardrobe item deleted from Firestore');
    } catch (e) {
      AppLogger.error('❌ Error deleting wardrobe item', error: e);
      rethrow;
    }
  }

  /// Bulk save wardrobe items (for migration)
  Future<void> bulkSaveWardrobeItems(List<WardrobeItem> items) async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      AppLogger.info('📦 Bulk saving ${items.length} wardrobe items...');

      final batch = _firestore.batch();
      for (final item in items) {
        final docRef = _wardrobeCollection(userId).doc(item.id);
        batch.set(docRef, _wardrobeItemToFirestore(item));
      }

      await batch.commit();
      AppLogger.info('✅ Bulk save complete: ${items.length} items');
    } catch (e, stack) {
      AppLogger.error(
        '❌ Error in bulk save',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  // ==================== WARDROBE LOOKS ====================

  /// Save a wardrobe look to Firestore
  Future<void> saveWardrobeLook(WardrobeLook look) async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      await _looksCollection(userId).doc(look.id).set(look.toJson());
      AppLogger.info('✅ Wardrobe look saved to Firestore');
    } catch (e) {
      AppLogger.error('❌ Error saving wardrobe look', error: e);
      rethrow;
    }
  }

  /// Get all wardrobe looks
  Future<List<WardrobeLook>> getAllWardrobeLooks() async {
    final userId = _currentUserId;
    if (userId == null) return [];

    try {
      final snapshot = await _looksCollection(userId).get();
      return snapshot.docs
          .map((doc) => WardrobeLook.fromJson(doc.data()))
          .toList();
    } catch (e) {
      AppLogger.error('❌ Error fetching wardrobe looks', error: e);
      return [];
    }
  }

  /// Stream of wardrobe looks
  Stream<List<WardrobeLook>> watchWardrobeLooks() {
    final userId = _currentUserId;
    if (userId == null) return Stream.value([]);

    return _looksCollection(userId).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => WardrobeLook.fromJson(doc.data()))
          .toList();
    });
  }

  /// Delete a wardrobe look
  Future<void> deleteWardrobeLook(String lookId) async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      await _looksCollection(userId).doc(lookId).delete();
      AppLogger.info('✅ Wardrobe look deleted from Firestore');
    } catch (e) {
      AppLogger.error('❌ Error deleting wardrobe look', error: e);
      rethrow;
    }
  }

  // ==================== CONVERTERS ====================

  /// Convert WardrobeItem to Firestore format
  Map<String, dynamic> _wardrobeItemToFirestore(WardrobeItem item) {
    final json = item.toJson();

    // Convert DateTime to Timestamp
    json['createdAt'] = Timestamp.fromDate(item.createdAt);
    if (item.lastWorn != null) {
      json['lastWorn'] = Timestamp.fromDate(item.lastWorn!);
    }

    // Add server timestamp for tracking
    json['updatedAt'] = FieldValue.serverTimestamp();

    return json;
  }

  /// Convert Firestore data to WardrobeItem
  WardrobeItem? _wardrobeItemFromFirestore(Map<String, dynamic> data) {
    try {
      // Convert Timestamp back to DateTime
      if (data['createdAt'] is Timestamp) {
        data['createdAt'] =
            (data['createdAt'] as Timestamp).toDate().toIso8601String();
      }
      if (data['lastWorn'] is Timestamp) {
        data['lastWorn'] =
            (data['lastWorn'] as Timestamp).toDate().toIso8601String();
      }

      return WardrobeItem.fromJson(data);
    } catch (e) {
      AppLogger.error('❌ Error parsing wardrobe item from Firestore', error: e);
      return null;
    }
  }
}
