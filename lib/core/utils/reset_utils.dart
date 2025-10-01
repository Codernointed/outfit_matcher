import 'package:vestiq/core/constants/app_constants.dart';
import 'package:vestiq/core/di/service_locator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Utility functions for resetting app state (mainly for development/testing)
class ResetUtils {
  /// Resets the onboarding state so the welcome and onboarding screens
  /// will be shown again next time the app is launched
  static Future<void> resetOnboardingState() async {
    final prefs = getIt<SharedPreferences>();
    await prefs.setBool(AppConstants.onboardingCompletedKey, false);
  }
}
