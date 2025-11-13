import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vestiq/features/auth/presentation/providers/auth_providers.dart';
import 'package:vestiq/features/auth/presentation/screens/login_screen.dart';
import 'package:vestiq/features/onboarding/presentation/screens/splash_screen.dart';
import 'package:vestiq/core/utils/logger.dart';

/// Wrapper widget that handles authentication routing
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          // User is not signed in - show login
          AppLogger.debug('👤 No user signed in - showing login');
          return const LoginScreen();
        } else {
          // User is signed in - show main app
          AppLogger.debug('✅ User signed in: ${user.uid}');
          // Check if user has completed onboarding
          return const SplashScreen(); // This will route to appropriate screen
        }
      },
      loading: () {
        // Show loading while checking auth state
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
      error: (error, stackTrace) {
        // Show error screen
        AppLogger.error('❌ Auth error', error: error);
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Authentication Error',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Retry by invalidating the auth state
                    ref.invalidate(authStateProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
