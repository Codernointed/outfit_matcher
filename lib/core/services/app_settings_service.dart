import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestiq/core/models/user_profile.dart';
import 'package:vestiq/core/utils/logger.dart';

/// Service for managing app settings and preferences
class AppSettingsService {
  static const String _premiumPolishingKey = 'premium_polishing_enabled';
  static const String _autoSaveKey = 'auto_save_enabled';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _subscriptionCacheKey = 'subscription_snapshot';
  static const String _usageSnapshotKey = 'subscription_usage_snapshot';

  final SharedPreferences _prefs;
  final _usageController =
      StreamController<SubscriptionUsageSnapshot>.broadcast();

  SubscriptionUsageSnapshot? _usageCache;
  UserSubscription? _subscriptionCache;

  AppSettingsService(this._prefs);

  /// Dispose stream controllers.
  void dispose() {
    _usageController.close();
  }

  /// Premium image polishing setting
  bool get isPremiumPolishingEnabled =>
      _prefs.getBool(_premiumPolishingKey) ?? false;

  Future<void> setPremiumPolishing(bool enabled) async {
    await _prefs.setBool(_premiumPolishingKey, enabled);
    AppLogger.info('🎨 Premium polishing ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Auto-save setting
  bool get isAutoSaveEnabled => _prefs.getBool(_autoSaveKey) ?? true;

  Future<void> setAutoSave(bool enabled) async {
    await _prefs.setBool(_autoSaveKey, enabled);
    AppLogger.info('💾 Auto-save ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Notifications setting
  bool get areNotificationsEnabled => _prefs.getBool(_notificationsKey) ?? true;

  Future<void> setNotifications(bool enabled) async {
    await _prefs.setBool(_notificationsKey, enabled);
    AppLogger.info('🔔 Notifications ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Cached subscription snapshot (falls back to Free tier).
  UserSubscription get subscriptionSnapshot => _subscriptionCache ??=
      UserSubscription.fromJson(_decodePrefs(_subscriptionCacheKey));

  /// Persist subscription snapshot locally (e.g., after backend verification).
  Future<UserSubscription> saveSubscriptionSnapshot(
    UserSubscription snapshot,
  ) async {
    _subscriptionCache = snapshot;
    await _prefs.setString(
      _subscriptionCacheKey,
      jsonEncode(snapshot.toJson()),
    );
    AppLogger.info(
      '🪪 Subscription snapshot saved: ${snapshot.tier.name}/${snapshot.status.name}',
    );
    return snapshot;
  }

  /// Stream of usage snapshot updates for UI/guards.
  Stream<SubscriptionUsageSnapshot> get usageStream => _usageController.stream;

  /// Latest usage snapshot (cached in-memory).
  SubscriptionUsageSnapshot get usageSnapshot => _usageCache ??=
      SubscriptionUsageSnapshot.fromJson(_decodePrefs(_usageSnapshotKey));

  /// Reset usage counters when moving between tiers or after full sync.
  Future<void> clearUsageSnapshot() async {
    _usageCache = SubscriptionUsageSnapshot();
    await _prefs.remove(_usageSnapshotKey);
    _usageController.add(_usageCache!);
    AppLogger.info('🧹 Subscription usage snapshot cleared');
  }

  /// Ensure daily/monthly counters reset as needed given the active policy.
  Future<SubscriptionUsageSnapshot> reconcileUsageIfNeeded(
    SubscriptionUsagePolicy policy, {
    DateTime? timestamp,
  }) async {
    final now = timestamp ?? DateTime.now();
    var snapshot = usageSnapshot;
    var mutated = false;

    if (snapshot.needsDailyReset(now)) {
      snapshot = snapshot.copyWith(
        dailyUploadsUsed: 0,
        dailyResetAt: DateTime(now.year, now.month, now.day),
      );
      mutated = true;
      AppLogger.info('🗓️ Daily usage counters reset');
    }

    if (snapshot.needsMonthlyReset(now)) {
      snapshot = snapshot.copyWith(
        monthlyMannequinsUsed: 0,
        monthlyPairingsUsed: 0,
        monthlyInspirationUsed: 0,
        monthlyPolishingUsed: 0,
        monthlyResetAt: DateTime(now.year, now.month),
      );
      mutated = true;
      AppLogger.info('📆 Monthly usage counters reset');
    }

    if (mutated) {
      await _persistUsage(snapshot);
    }
    return snapshot;
  }

  /// Increment usage counters while respecting tier limits.
  Future<SubscriptionUsageSnapshot> incrementUsage({
    int uploads = 0,
    int mannequins = 0,
    int pairings = 0,
    int inspiration = 0,
    int polishing = 0,
    required SubscriptionUsagePolicy policy,
  }) async {
    await reconcileUsageIfNeeded(policy);
    var snapshot = usageSnapshot;

    int applyLimit(int current, int delta, int limit) {
      if (delta == 0) return current;
      if (limit == SubscriptionUsagePolicy.unlimited) {
        return current + delta;
      }
      final next = current + delta;
      if (next < 0) return 0;
      return next > limit ? limit : next;
    }

    snapshot = snapshot.copyWith(
      dailyUploadsUsed: applyLimit(
        snapshot.dailyUploadsUsed,
        uploads,
        policy.dailyUploads,
      ),
      monthlyMannequinsUsed: applyLimit(
        snapshot.monthlyMannequinsUsed,
        mannequins,
        policy.monthlyMannequins,
      ),
      monthlyPairingsUsed: applyLimit(
        snapshot.monthlyPairingsUsed,
        pairings,
        policy.monthlyPairings,
      ),
      monthlyInspirationUsed: applyLimit(
        snapshot.monthlyInspirationUsed,
        inspiration,
        policy.monthlyInspirationSearches,
      ),
      monthlyPolishingUsed: applyLimit(
        snapshot.monthlyPolishingUsed,
        polishing,
        policy.monthlyImagePolish,
      ),
    );

    return _persistUsage(snapshot);
  }

  /// Force-set the usage snapshot (e.g., from backend entitlement sync).
  Future<SubscriptionUsageSnapshot> syncUsageSnapshot(
    SubscriptionUsageSnapshot snapshot,
  ) async {
    return _persistUsage(snapshot);
  }

  /// Get all settings as a map
  Map<String, dynamic> getAllSettings() {
    return {
      'premiumPolishing': isPremiumPolishingEnabled,
      'autoSave': isAutoSaveEnabled,
      'notifications': areNotificationsEnabled,
      'subscription': subscriptionSnapshot.toJson(),
      'usage': usageSnapshot.toJson(),
    };
  }

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    await _prefs.setBool(_premiumPolishingKey, false);
    await _prefs.setBool(_autoSaveKey, true);
    await _prefs.setBool(_notificationsKey, true);
    await _prefs.remove(_subscriptionCacheKey);
    await _prefs.remove(_usageSnapshotKey);
    _subscriptionCache = const UserSubscription();
    _usageCache = SubscriptionUsageSnapshot();
    _usageController.add(_usageCache!);
    AppLogger.info('🔄 Settings reset to defaults');
  }

  Map<String, dynamic>? _decodePrefs(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>?;
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Failed to decode JSON for $key',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<SubscriptionUsageSnapshot> _persistUsage(
    SubscriptionUsageSnapshot snapshot,
  ) async {
    _usageCache = snapshot;
    await _prefs.setString(_usageSnapshotKey, jsonEncode(snapshot.toJson()));
    _usageController.add(snapshot);
    AppLogger.debug('📈 Usage snapshot updated', data: snapshot.toJson());
    return snapshot;
  }
}
