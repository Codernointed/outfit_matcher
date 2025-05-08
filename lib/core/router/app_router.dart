import 'package:flutter/material.dart';
import 'package:outfit_matcher/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:outfit_matcher/features/onboarding/presentation/screens/splash_screen.dart';
import 'package:outfit_matcher/features/wardrobe/presentation/screens/add_item_screen.dart';
import 'package:outfit_matcher/features/wardrobe/presentation/screens/home_screen.dart';
import 'package:outfit_matcher/features/wardrobe/presentation/screens/item_details_screen.dart';
import 'package:outfit_matcher/features/wardrobe/presentation/screens/main_screen.dart';
import 'package:outfit_matcher/features/outfit_suggestions/presentation/screens/outfit_suggestions_screen.dart';
import 'package:outfit_matcher/features/wardrobe/domain/entities/clothing_item.dart';

/// App navigation helper
/// Use this class for consistent navigation throughout the app
class AppRouter {
  // Route names
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String main = '/main';
  static const String home = '/main/home';
  static const String addItem = '/add-item';
  static const String itemDetails = '/item-details';
  static const String outfitSuggestions = '/outfit-suggestions';

  /// Basic routes for MaterialApp, without parameters
  /// Note: Routes requiring parameters are handled via named methods below
  static Map<String, Widget Function(BuildContext)> getBasicRoutes() {
    return {
      splash: (context) => const SplashScreen(),
      onboarding: (context) => const OnboardingScreen(),
      main: (context) => const MainScreen(),
      addItem: (context) => const AddItemScreen(),
      // Routes requiring parameters are not included here
    };
  }

  /// Navigation helper methods
  static void navigateToSplash(BuildContext context) =>
      Navigator.of(context).pushReplacementNamed(splash);

  static void navigateToOnboarding(BuildContext context) =>
      Navigator.of(context).pushReplacementNamed(onboarding);

  static void navigateToMain(BuildContext context) =>
      Navigator.of(context).pushReplacementNamed(main);

  static void navigateToAddItem(BuildContext context) =>
      Navigator.of(context).pushNamed(addItem);

  static void navigateToItemDetails(BuildContext context, String imagePath) =>
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ItemDetailsScreen(imagePath: imagePath),
        ),
      );

  static void navigateToOutfitSuggestions(
    BuildContext context,
    ClothingItem item,
  ) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => OutfitSuggestionsScreen(item: item),
    ),
  );
}
