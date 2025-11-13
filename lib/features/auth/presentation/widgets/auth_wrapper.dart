import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vestiq/core/utils/logger.dart';
import 'package:vestiq/features/auth/domain/models/auth_flow_state.dart';
import 'package:vestiq/features/auth/presentation/providers/auth_flow_controller.dart';
import 'package:vestiq/features/auth/presentation/screens/login_screen.dart';
import 'package:vestiq/features/onboarding/presentation/screens/profile_creation_screen.dart';
import 'package:vestiq/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:vestiq/features/onboarding/presentation/screens/splash_screen.dart';
import 'package:vestiq/features/outfit_suggestions/presentation/screens/home_screen.dart';

/// Clean authentication wrapper - single source of routing based on AuthFlowState
///
/// This widget ONLY reads state and shows the correct screen.
/// It does NOT handle any navigation logic - that's in AuthFlowController.
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the auth flow state - THIS is the single source of truth
    final authFlowState = ref.watch(authFlowControllerProvider);

    AppLogger.info('🎯 [AuthWrapper] State: ${authFlowState.runtimeType}');

    // Declarative routing based on state
    return switch (authFlowState) {
      AuthFlowInitial() => const SplashScreen(),

      AuthFlowNeedsOnboarding() => const OnboardingScreen(),

      AuthFlowUnauthenticated() => const LoginScreen(),

      AuthFlowNeedsProfile() => ProfileCreationScreen(
        onComplete: () {
          // After profile created, refresh auth state
          ref.read(authFlowControllerProvider.notifier).onProfileUpdated();
        },
      ),

      AuthFlowAuthenticated() => HomeScreen(),

      AuthFlowError(:final message) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Authentication Error'),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ref.read(authFlowControllerProvider.notifier).refresh();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    };
  }
}
