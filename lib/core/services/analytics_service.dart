import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:vestiq/core/utils/logger.dart';
import 'package:vestiq/core/models/wardrobe_item.dart';

/// Centralized service for tracking user activity and business intelligence.
/// Designed for high performance (all calls are async/unawaited).
class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Singleton pattern
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  /// Log a custom event with standardized parameters
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      if (kDebugMode) {
        AppLogger.debug('📊 [ANALYTICS] Logging event: $name');
      }

      // Fire and forget - don't await to block UI thread
      _analytics.logEvent(name: name, parameters: parameters).ignore();
    } catch (e) {
      // Never crash the app due to analytics failure
      AppLogger.warning('⚠️ Analytics log failed: $e');
    }
  }

  // ===========================================================================
  // 1. AUTH & ONBOARDING
  // ===========================================================================

  Future<void> logLogin({required String method}) {
    return logEvent(name: 'login', parameters: {'method': method});
  }

  Future<void> logSignUp({required String method}) {
    return logEvent(name: 'sign_up', parameters: {'method': method});
  }

  Future<void> logSignOut() {
    return logEvent(name: 'sign_out');
  }

  Future<void> logAccountDeleted() {
    return logEvent(name: 'account_deleted');
  }

  Future<void> updateUserProperties({
    required int itemsCount,
    required bool isPremium,
  }) async {
    try {
      // Set user properties for audience segmentation
      _analytics
          .setUserProperty(
            name: 'items_in_closet',
            value: itemsCount.toString(),
          )
          .ignore();
      _analytics
          .setUserProperty(name: 'is_premium', value: isPremium.toString())
          .ignore();
    } catch (_) {}
  }

  // ===========================================================================
  // 2. WARDROBE ENGAGEMENT (High Value Signals)
  // ===========================================================================

  Future<void> logItemAdded({
    required WardrobeItem item,
    required String source, // 'camera', 'gallery'
    required int processingTimeMs,
  }) {
    final analysis = item.analysis;
    return logEvent(
      name: 'item_added',
      parameters: {
        'source': source,
        'item_type': analysis.itemType,
        'color': analysis.primaryColor,
        // Rich Metadata for Personalization
        'fit': analysis.fit ?? 'unknown',
        'style': analysis.style,
        'material': analysis.material ?? 'unknown',
        'pattern': analysis.patternType,
        // Performance metric
        'processing_time_ms': processingTimeMs,
      },
    );
  }

  Future<void> logItemDeleted({
    required String itemType,
    required int daysSinceCreation,
  }) {
    return logEvent(
      name: 'item_deleted',
      parameters: {'item_type': itemType, 'lifespan_days': daysSinceCreation},
    );
  }

  Future<void> logItemViewed({required WardrobeItem item}) {
    return logEvent(
      name: 'item_viewed',
      parameters: {
        'item_type': item.analysis.itemType,
        'color': item.analysis.primaryColor,
        'style': item.analysis.style,
        'fit': item.analysis.fit ?? 'unknown',
      },
    );
  }

  // ===========================================================================
  // 3. OUTFIT PLANNING (Core Value)
  // ===========================================================================

  Future<void> logOutfitGenerationStarted({
    required String mode, // 'surprise_me', 'pair_this'
    required String occasion,
  }) {
    return logEvent(
      name: 'outfit_generation_started',
      parameters: {'mode': mode, 'occasion': occasion},
    );
  }

  Future<void> logOutfitGenerated({
    required int itemsCount,
    required String occasion,
    required int latencyMs,
  }) {
    return logEvent(
      name: 'outfit_generated',
      parameters: {
        'items_count': itemsCount,
        'occasion': occasion,
        'latency_ms': latencyMs,
      },
    );
  }

  Future<void> logOutfitSaved({
    required String occasion,
    required int itemsCount,
  }) {
    return logEvent(
      name: 'outfit_saved',
      parameters: {'occasion': occasion, 'items_count': itemsCount},
    );
  }

  // ===========================================================================
  // 4. UI INTERACTIONS & SETTINGS
  // ===========================================================================

  Future<void> logFeatureUsed({required String featureName}) {
    return logEvent(name: 'feature_used', parameters: {'feature': featureName});
  }

  Future<void> logCacheCleared({required double sizeMB}) {
    return logEvent(name: 'cache_cleared', parameters: {'size_mb': sizeMB});
  }

  Future<void> logProfileUpdated({List<String>? fieldsUpdated}) {
    return logEvent(
      name: 'profile_updated',
      parameters: {
        if (fieldsUpdated != null) 'fields': fieldsUpdated.join(','),
      },
    );
  }
}
