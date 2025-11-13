import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vestiq/core/utils/logger.dart';
import 'package:vestiq/features/auth/domain/models/app_user.dart';

/// Service for managing user profiles in Firestore
class UserProfileService {
  UserProfileService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Collection reference for users
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  // ==================== CREATE & READ ====================

  /// Create a new user profile in Firestore
  Future<AppUser> createUserProfile({
    required String uid,
    required String email,
    required String username,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    String? gender,
    required AuthProvider authProvider,
  }) async {
    try {
      AppLogger.info('📝 Creating user profile: $uid');

      final now = DateTime.now();
      final appUser = AppUser(
        uid: uid,
        email: email,
        username: username,
        displayName: displayName,
        photoUrl: photoUrl,
        phoneNumber: phoneNumber,
        authProvider: authProvider,
        createdAt: now,
        lastLoginAt: now,
        gender: gender,
        preferences: const UserPreferences(),
      );

      // Save to Firestore
      await _usersCollection.doc(uid).set(appUser.toFirestore());

      AppLogger.info('✅ User profile created successfully');
      return appUser;
    } catch (e) {
      AppLogger.error('❌ Error creating user profile', error: e);
      rethrow;
    }
  }

  /// Get user profile from Firestore
  Future<AppUser?> getUserProfile(String uid) async {
    try {
      AppLogger.debug('📖 Fetching user profile: $uid');

      final doc = await _usersCollection.doc(uid).get();

      if (!doc.exists) {
        AppLogger.warning('⚠️ User profile not found: $uid');
        return null;
      }

      final data = doc.data();
      if (data == null) return null;

      return AppUser.fromFirestore(data);
    } catch (e) {
      AppLogger.error('❌ Error fetching user profile', error: e);
      rethrow;
    }
  }

  /// Stream of user profile changes
  Stream<AppUser?> watchUserProfile(String uid) {
    return _usersCollection.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      final data = snapshot.data();
      if (data == null) return null;
      return AppUser.fromFirestore(data);
    });
  }

  // ==================== UPDATE OPERATIONS ====================

  /// Update user profile
  Future<void> updateUserProfile(
    String uid,
    Map<String, dynamic> updates,
  ) async {
    try {
      AppLogger.debug('📝 Updating user profile: $uid');

      await _usersCollection.doc(uid).update(updates);

      AppLogger.info('✅ User profile updated');
    } catch (e) {
      AppLogger.error('❌ Error updating user profile', error: e);
      rethrow;
    }
  }

  /// Update last login time
  Future<AppUser?> updateLastLogin(String uid) async {
    try {
      await _usersCollection.doc(uid).update({
        'lastLoginAt': Timestamp.fromDate(DateTime.now()),
        'lastActiveDate': Timestamp.fromDate(DateTime.now()),
        'totalAppOpenCount': FieldValue.increment(1),
      });

      return await getUserProfile(uid);
    } catch (e) {
      AppLogger.error('❌ Error updating last login', error: e);
      rethrow;
    }
  }

  /// Increment generation count
  Future<void> incrementGenerationCount(String uid) async {
    try {
      final now = DateTime.now();
      final user = await getUserProfile(uid);

      if (user == null) return;

      // Check if it's a new day - reset daily count
      final lastGen = user.lastGenerationDate;
      final isNewDay =
          lastGen == null ||
          lastGen.year != now.year ||
          lastGen.month != now.month ||
          lastGen.day != now.day;

      await _usersCollection.doc(uid).update({
        'totalGenerations': FieldValue.increment(1),
        'todayGenerations': isNewDay ? 1 : FieldValue.increment(1),
        'lastGenerationDate': Timestamp.fromDate(now),
        'lastActiveDate': Timestamp.fromDate(now),
      });

      AppLogger.info('📊 Generation count incremented for user: $uid');
    } catch (e) {
      AppLogger.error('❌ Error incrementing generation count', error: e);
      rethrow;
    }
  }

  /// Update wardrobe item count
  Future<void> updateWardrobeItemCount(String uid, int count) async {
    try {
      await _usersCollection.doc(uid).update({
        'wardrobeItemCount': count,
        'lastActiveDate': Timestamp.fromDate(DateTime.now()),
      });

      AppLogger.debug('📊 Wardrobe item count updated: $count');
    } catch (e) {
      AppLogger.error('❌ Error updating wardrobe item count', error: e);
      rethrow;
    }
  }

  /// Increment wardrobe item count
  Future<void> incrementWardrobeItemCount(String uid) async {
    try {
      await _usersCollection.doc(uid).update({
        'wardrobeItemCount': FieldValue.increment(1),
        'lastActiveDate': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      AppLogger.error('❌ Error incrementing wardrobe item count', error: e);
      rethrow;
    }
  }

  /// Decrement wardrobe item count
  Future<void> decrementWardrobeItemCount(String uid) async {
    try {
      await _usersCollection.doc(uid).update({
        'wardrobeItemCount': FieldValue.increment(-1),
        'lastActiveDate': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      AppLogger.error('❌ Error decrementing wardrobe item count', error: e);
      rethrow;
    }
  }

  /// Update saved outfit count
  Future<void> updateSavedOutfitCount(String uid, int count) async {
    try {
      await _usersCollection.doc(uid).update({
        'savedOutfitCount': count,
        'lastActiveDate': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      AppLogger.error('❌ Error updating saved outfit count', error: e);
      rethrow;
    }
  }

  /// Increment saved outfit count
  Future<void> incrementSavedOutfitCount(String uid) async {
    try {
      await _usersCollection.doc(uid).update({
        'savedOutfitCount': FieldValue.increment(1),
        'lastActiveDate': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      AppLogger.error('❌ Error incrementing saved outfit count', error: e);
      rethrow;
    }
  }

  /// Update favorite count
  Future<void> updateFavoriteCount(String uid, int count) async {
    try {
      await _usersCollection.doc(uid).update({
        'favoriteCount': count,
        'lastActiveDate': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      AppLogger.error('❌ Error updating favorite count', error: e);
      rethrow;
    }
  }

  /// Track feature usage
  Future<void> trackFeatureUsage(String uid, String featureName) async {
    try {
      await _usersCollection.doc(uid).update({
        'featureUsageCount.$featureName': FieldValue.increment(1),
        'lastActiveDate': Timestamp.fromDate(DateTime.now()),
      });

      AppLogger.debug('📊 Feature usage tracked: $featureName');
    } catch (e) {
      AppLogger.error('❌ Error tracking feature usage', error: e);
      rethrow;
    }
  }

  /// Update session duration
  Future<void> updateSessionDuration(String uid, int durationMinutes) async {
    try {
      await _usersCollection.doc(uid).update({
        'totalSessionDuration': FieldValue.increment(durationMinutes),
        'lastActiveDate': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      AppLogger.error('❌ Error updating session duration', error: e);
      rethrow;
    }
  }

  /// Update user preferences
  Future<void> updatePreferences(
    String uid,
    UserPreferences preferences,
  ) async {
    try {
      await _usersCollection.doc(uid).update({
        'preferences': preferences.toMap(),
      });

      AppLogger.info('✅ User preferences updated');
    } catch (e) {
      AppLogger.error('❌ Error updating preferences', error: e);
      rethrow;
    }
  }

  /// Update style preferences
  Future<void> updateStylePreferences(
    String uid, {
    List<String>? preferredStyles,
    List<String>? preferredColors,
    List<String>? preferredOccasions,
    String? bodyType,
    String? stylePersonality,
  }) async {
    try {
      final Map<String, dynamic> updates = {};

      if (preferredStyles != null) updates['preferredStyles'] = preferredStyles;
      if (preferredColors != null) updates['preferredColors'] = preferredColors;
      if (preferredOccasions != null) {
        updates['preferredOccasions'] = preferredOccasions;
      }
      if (bodyType != null) updates['bodyType'] = bodyType;
      if (stylePersonality != null) {
        updates['stylePersonality'] = stylePersonality;
      }

      if (updates.isNotEmpty) {
        await _usersCollection.doc(uid).update(updates);
        AppLogger.info('✅ Style preferences updated');
      }
    } catch (e) {
      AppLogger.error('❌ Error updating style preferences', error: e);
      rethrow;
    }
  }

  /// Update subscription
  Future<void> updateSubscription(
    String uid, {
    required SubscriptionTier tier,
    DateTime? expiryDate,
  }) async {
    try {
      final Map<String, dynamic> updates = {'subscriptionTier': tier.name};

      if (expiryDate != null) {
        updates['subscriptionExpiryDate'] = Timestamp.fromDate(expiryDate);
      }

      // Update limits based on tier
      switch (tier) {
        case SubscriptionTier.free:
          updates['generationsLimit'] = 5;
          updates['wardrobeItemLimit'] = 30;
          break;
        case SubscriptionTier.plus:
          updates['generationsLimit'] = -1; // Unlimited
          updates['wardrobeItemLimit'] = -1; // Unlimited
          break;
        case SubscriptionTier.pro:
          updates['generationsLimit'] = -1; // Unlimited
          updates['wardrobeItemLimit'] = -1; // Unlimited
          break;
      }

      await _usersCollection.doc(uid).update(updates);

      AppLogger.info('✅ Subscription updated to: ${tier.name}');
    } catch (e) {
      AppLogger.error('❌ Error updating subscription', error: e);
      rethrow;
    }
  }

  // ==================== DELETE ====================

  /// Delete user profile
  Future<void> deleteUserProfile(String uid) async {
    try {
      AppLogger.info('🗑️ Deleting user profile: $uid');

      await _usersCollection.doc(uid).delete();

      AppLogger.info('✅ User profile deleted');
    } catch (e) {
      AppLogger.error('❌ Error deleting user profile', error: e);
      rethrow;
    }
  }

  // ==================== QUERY OPERATIONS ====================

  /// Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final query = await _usersCollection
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      return query.docs.isEmpty;
    } catch (e) {
      AppLogger.error('❌ Error checking username availability', error: e);
      rethrow;
    }
  }

  /// Search users by username
  Future<List<AppUser>> searchUsersByUsername(String query) async {
    try {
      final snapshot = await _usersCollection
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThan: '${query}z')
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => AppUser.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      AppLogger.error('❌ Error searching users', error: e);
      rethrow;
    }
  }

  // ==================== ANALYTICS ====================

  /// Get user statistics
  Future<Map<String, dynamic>> getUserStatistics(String uid) async {
    try {
      final user = await getUserProfile(uid);
      if (user == null) return {};

      return {
        'totalGenerations': user.totalGenerations,
        'todayGenerations': user.todayGenerations,
        'wardrobeItemCount': user.wardrobeItemCount,
        'savedOutfitCount': user.savedOutfitCount,
        'favoriteCount': user.favoriteCount,
        'totalAppOpenCount': user.totalAppOpenCount,
        'totalSessionDuration': user.totalSessionDuration,
        'featureUsageCount': user.featureUsageCount,
        'memberSince': user.createdAt,
        'lastActive': user.lastActiveDate,
      };
    } catch (e) {
      AppLogger.error('❌ Error getting user statistics', error: e);
      rethrow;
    }
  }
}
