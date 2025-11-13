import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // Screen tracking
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
      debugPrint('📊 Analytics: Screen view - $screenName');
    } catch (e) {
      debugPrint('❌ Analytics error (screen view): $e');
    }
  }

  // User authentication events
  Future<void> logSignUp({required String method}) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
      debugPrint('📊 Analytics: Sign up - $method');
    } catch (e) {
      debugPrint('❌ Analytics error (sign up): $e');
    }
  }

  Future<void> logLogin({required String method}) async {
    try {
      await _analytics.logLogin(loginMethod: method);
      debugPrint('📊 Analytics: Login - $method');
    } catch (e) {
      debugPrint('❌ Analytics error (login): $e');
    }
  }

  Future<void> logSignOut() async {
    try {
      await _analytics.logEvent(name: 'sign_out');
      debugPrint('📊 Analytics: Sign out');
    } catch (e) {
      debugPrint('❌ Analytics error (sign out): $e');
    }
  }

  // User properties
  Future<void> setUserId(String userId) async {
    try {
      await _analytics.setUserId(id: userId);
      debugPrint('📊 Analytics: Set user ID - $userId');
    } catch (e) {
      debugPrint('❌ Analytics error (set user ID): $e');
    }
  }

  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
      debugPrint('📊 Analytics: Set user property - $name: $value');
    } catch (e) {
      debugPrint('❌ Analytics error (set user property): $e');
    }
  }

  // Feature usage
  Future<void> logFeatureUsage({
    required String featureName,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'feature_usage',
        parameters: {'feature_name': featureName, ...?parameters},
      );
      debugPrint('📊 Analytics: Feature usage - $featureName');
    } catch (e) {
      debugPrint('❌ Analytics error (feature usage): $e');
    }
  }

  // Outfit/Generation events
  Future<void> logOutfitGeneration({
    required String generationType,
    int? itemCount,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'outfit_generation',
        parameters: {
          'generation_type': generationType,
          if (itemCount != null) 'item_count': itemCount,
        },
      );
      debugPrint('📊 Analytics: Outfit generation - $generationType');
    } catch (e) {
      debugPrint('❌ Analytics error (outfit generation): $e');
    }
  }

  Future<void> logOutfitSaved({required String outfitType}) async {
    try {
      await _analytics.logEvent(
        name: 'outfit_saved',
        parameters: {'outfit_type': outfitType},
      );
      debugPrint('📊 Analytics: Outfit saved - $outfitType');
    } catch (e) {
      debugPrint('❌ Analytics error (outfit saved): $e');
    }
  }

  // Wardrobe events
  Future<void> logItemAdded({
    required String category,
    required String source,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'wardrobe_item_added',
        parameters: {
          'category': category,
          'source': source, // camera, gallery, etc.
        },
      );
      debugPrint('📊 Analytics: Item added - $category from $source');
    } catch (e) {
      debugPrint('❌ Analytics error (item added): $e');
    }
  }

  Future<void> logItemRemoved({required String category}) async {
    try {
      await _analytics.logEvent(
        name: 'wardrobe_item_removed',
        parameters: {'category': category},
      );
      debugPrint('📊 Analytics: Item removed - $category');
    } catch (e) {
      debugPrint('❌ Analytics error (item removed): $e');
    }
  }

  // Profile events
  Future<void> logProfileUpdated({required List<String> fieldsUpdated}) async {
    try {
      await _analytics.logEvent(
        name: 'profile_updated',
        parameters: {'fields_updated': fieldsUpdated.join(',')},
      );
      debugPrint('📊 Analytics: Profile updated - ${fieldsUpdated.join(', ')}');
    } catch (e) {
      debugPrint('❌ Analytics error (profile updated): $e');
    }
  }

  Future<void> logAccountDeleted() async {
    try {
      await _analytics.logEvent(name: 'account_deleted');
      debugPrint('📊 Analytics: Account deleted');
    } catch (e) {
      debugPrint('❌ Analytics error (account deleted): $e');
    }
  }

  // Storage/cache events
  Future<void> logCacheCleared({required double sizeMB}) async {
    try {
      await _analytics.logEvent(
        name: 'cache_cleared',
        parameters: {'size_mb': sizeMB},
      );
      debugPrint('📊 Analytics: Cache cleared - ${sizeMB}MB');
    } catch (e) {
      debugPrint('❌ Analytics error (cache cleared): $e');
    }
  }

  // Subscription events
  Future<void> logSubscriptionUpgrade({
    required String fromTier,
    required String toTier,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'subscription_upgrade',
        parameters: {'from_tier': fromTier, 'to_tier': toTier},
      );
      debugPrint('📊 Analytics: Subscription upgrade - $fromTier to $toTier');
    } catch (e) {
      debugPrint('❌ Analytics error (subscription upgrade): $e');
    }
  }

  // Social sharing
  Future<void> logShare({
    required String contentType,
    required String method,
    String itemId = '',
  }) async {
    try {
      await _analytics.logShare(
        contentType: contentType,
        itemId: itemId,
        method: method,
      );
      debugPrint('📊 Analytics: Share - $contentType via $method');
    } catch (e) {
      debugPrint('❌ Analytics error (share): $e');
    }
  }

  // Tutorial/onboarding
  Future<void> logTutorialBegin() async {
    try {
      await _analytics.logTutorialBegin();
      debugPrint('📊 Analytics: Tutorial begin');
    } catch (e) {
      debugPrint('❌ Analytics error (tutorial begin): $e');
    }
  }

  Future<void> logTutorialComplete() async {
    try {
      await _analytics.logTutorialComplete();
      debugPrint('📊 Analytics: Tutorial complete');
    } catch (e) {
      debugPrint('❌ Analytics error (tutorial complete): $e');
    }
  }

  // Custom events
  Future<void> logCustomEvent({
    required String eventName,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(name: eventName, parameters: parameters);
      debugPrint('📊 Analytics: Custom event - $eventName');
    } catch (e) {
      debugPrint('❌ Analytics error (custom event): $e');
    }
  }
}
