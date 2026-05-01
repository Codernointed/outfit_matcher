/// Class that provides application constants
class AppConstants {
  /// Private constructor to prevent instantiation
  const AppConstants._();

  /// App name
  static const String appName = 'Vestiq';

  /// App version
  static const String appVersion = '1.0.0';

  // ---------------------------------------------------------------------------
  // Spacing scale -- 8px rhythm with optical alignment
  // ---------------------------------------------------------------------------

  /// Default horizontal padding for screens (slightly airy for premium feel)
  static const double horizontalPadding = 20.0;

  /// Default vertical padding for screens
  static const double verticalPadding = 20.0;

  /// Default spacing between widgets
  static const double defaultSpacing = 16.0;

  /// Small spacing between widgets
  static const double smallSpacing = 8.0;

  /// Large spacing between widgets
  static const double largeSpacing = 24.0;

  /// Section gap between distinct content groups
  static const double sectionGap = 28.0;

  /// Tile gap inside dense grids
  static const double tileGap = 12.0;

  // ---------------------------------------------------------------------------
  // Border radius scale -- consistently soft / Soft Glass Hybrid
  // ---------------------------------------------------------------------------

  /// Inline chip / dense tag radius (8px). Reserved for tiny inline elements.
  static const double tinyBorderRadius = 8.0;

  /// Small radius (12px). Inline chips and small badges.
  static const double smallBorderRadius = 12.0;

  /// Default radius (16px). Buttons, inputs, small cards.
  static const double defaultBorderRadius = 16.0;

  /// Medium-large radius (20px). Cards, hero tiles.
  static const double largeBorderRadius = 20.0;

  /// Hero radius (24px). Photographic frames, large cards.
  static const double heroBorderRadius = 24.0;

  /// Sheet / nav radius (28px). Floating chrome only.
  static const double sheetBorderRadius = 28.0;

  // ---------------------------------------------------------------------------
  // Glass tokens (Glassmorphism 2.0)
  // ---------------------------------------------------------------------------

  /// Soft frosted blur for content cards (let imagery show through).
  static const double glassBlurSoft = 14.0;

  /// Default frosted blur for sheets, nav, app bars.
  static const double glassBlurMedium = 22.0;

  /// Strong frosted blur for full-screen modals.
  static const double glassBlurStrong = 32.0;

  /// Default glass fill opacity in light mode.
  static const double glassFillOpacityLight = 0.55;

  /// Stronger glass fill opacity in light mode.
  static const double glassFillOpacityLightStrong = 0.72;

  /// Default glass fill opacity in dark mode.
  static const double glassFillOpacityDark = 0.18;

  /// Stronger glass fill opacity in dark mode.
  static const double glassFillOpacityDarkStrong = 0.28;

  /// Luminous border opacity in light mode.
  static const double glassBorderOpacityLight = 0.65;

  /// Luminous border opacity in dark mode.
  static const double glassBorderOpacityDark = 0.10;

  // ---------------------------------------------------------------------------
  // Neumorphic tokens (used sparingly for tactile controls)
  // ---------------------------------------------------------------------------

  /// Small neumorphic depth (chips, small buttons).
  static const double softDepthSmall = 4.0;

  /// Medium neumorphic depth (buttons, toggles).
  static const double softDepthMedium = 6.0;

  /// Large neumorphic depth (cards, panels).
  static const double softDepthLarge = 10.0;

  // ---------------------------------------------------------------------------
  // Motion tokens
  // ---------------------------------------------------------------------------

  /// Press scale-down factor for visual haptics.
  static const double pressScale = 0.96;

  /// Hover-lift scale factor for cards.
  static const double hoverLiftScale = 1.02;

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
