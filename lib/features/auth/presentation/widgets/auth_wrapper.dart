import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vestiq/features/onboarding/presentation/screens/splash_screen.dart';

/// Wrapper widget that handles authentication routing
/// Always shows SplashScreen first which handles all routing logic
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Always show splash screen - it handles all routing logic
    return const SplashScreen();
  }
}
