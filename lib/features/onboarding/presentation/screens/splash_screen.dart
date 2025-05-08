import 'package:flutter/material.dart';
import 'package:outfit_matcher/core/constants/app_constants.dart';
import 'package:outfit_matcher/features/onboarding/presentation/screens/welcome_screen.dart';
import 'package:outfit_matcher/features/wardrobe/presentation/screens/main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:outfit_matcher/core/di/service_locator.dart';

/// Splash screen shown when the app starts
class SplashScreen extends StatefulWidget {
  /// Default constructor
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  /// Check if this is the first launch and navigate accordingly
  Future<void> _checkFirstLaunch() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final prefs = getIt<SharedPreferences>();
    final onboardingCompleted =
        prefs.getBool(AppConstants.onboardingCompletedKey) ?? false;

    if (onboardingCompleted) {
      // User has already completed onboarding, go to home
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else {
      // First time user, go to welcome screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Icon(Icons.checkroom, size: 100, color: Colors.white),
            const SizedBox(height: 24),

            // App name
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
