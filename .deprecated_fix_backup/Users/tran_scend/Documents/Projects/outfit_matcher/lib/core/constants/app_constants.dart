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
}
