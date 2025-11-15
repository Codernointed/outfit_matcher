/// Class that provides application constants
class AppConstants {
  /// Private constructor to prevent instantiation
  const AppConstants._();

  /// App name
  static const String appName = 'Vestiq';

  /// App version
  static const String appVersion = '1.0.0';

  /// Default horizontal padding for screens
  static const double horizontalPadding = 16.0;

  /// Default vertical padding for screens
  static const double verticalPadding = 16.0;

  /// Default spacing between widgets
  static const double defaultSpacing = 16.0;

  /// Small spacing between widgets
  static const double smallSpacing = 8.0;

  /// Large spacing between widgets
  static const double largeSpacing = 24.0;

  /// Default corner radius for widgets
  static const double defaultBorderRadius = 12.0;

  /// Small corner radius for widgets
  static const double smallBorderRadius = 8.0;

  /// Large corner radius for widgets
  static const double largeBorderRadius = 16.0;

  /// Storage key for onboarding completion
  static const String onboardingCompletedKey = 'onboarding_completed';

  /// Storage key for user wardrobe items
  static const String wardrobeItemsKey = 'wardrobe_items';

  /// Storage key for outfit suggestions
  static const String outfitSuggestionsKey = 'outfit_suggestions';

  // ---------------------------------------------------------------------------
  // Subscription + Paystack configuration
  // ---------------------------------------------------------------------------

  /// Environment key for Paystack public key (safe to bundle client-side)
  static const String envPaystackPublicKey = 'PAYSTACK_PUBLIC_KEY';

  /// Environment key for Paystack secret key (only used server-side — kept for parity)
  static const String envPaystackSecretKey = 'PAYSTACK_SECRET_KEY';

  /// Environment key for the Paystack premium monthly plan code
  static const String envPaystackPlanPremium = 'PAYSTACK_PLAN_PREMIUM';

  /// Environment key for the Paystack pro plan code (future use)
  static const String envPaystackPlanPro = 'PAYSTACK_PLAN_PRO';

  /// Environment key for backend initialize endpoint
  static const String envSubscriptionInitializeUrl =
      'SUBSCRIPTIONS_INITIALIZE_URL';

  /// Environment key for backend verify endpoint
  static const String envSubscriptionVerifyUrl = 'SUBSCRIPTIONS_VERIFY_URL';

  /// Environment key for backend entitlement snapshot endpoint
  static const String envSubscriptionEntitlementUrl =
      'SUBSCRIPTIONS_ENTITLEMENT_URL';

  /// Human-readable label for the Free tier
  static const String subscriptionFreeLabel = 'Free';

  /// Human-readable label for the Premium tier
  static const String subscriptionPremiumLabel = 'Premium';

  /// Human-readable label for the Pro tier
  static const String subscriptionProLabel = 'Pro';

  /// Free tier daily upload limit
  static const int freeDailyUploadLimit = 8;

  /// Premium tier daily upload limit
  static const int premiumDailyUploadLimit = 16;

  /// Free tier monthly mannequin allowance
  static const int freeMonthlyMannequinLimit = 240;

  /// Premium tier monthly mannequin allowance
  static const int premiumMonthlyMannequinLimit = 540;

  /// Free tier monthly pairing allowance
  static const int freeMonthlyPairingLimit = 50;

  /// Free tier monthly inspiration search allowance
  static const int freeMonthlyInspirationLimit = 100;

  /// Premium tier monthly polishing allowance
  static const int premiumMonthlyPolishingLimit = 500;
}
