import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vestiq/core/constants/app_constants.dart';
import 'package:vestiq/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:vestiq/features/auth/presentation/screens/login_screen.dart';
import 'package:vestiq/features/outfit_suggestions/presentation/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestiq/core/di/service_locator.dart';
import 'package:vestiq/features/auth/presentation/providers/auth_providers.dart';
import 'package:vestiq/core/utils/logger.dart';

/// Animated splash screen shown when the app starts
/// Routes to appropriate screen based on user state
class SplashScreen extends ConsumerStatefulWidget {
  /// Default constructor
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Setup animations
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Navigate after splash
    _navigateToNextScreen();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Determine next screen based on user state
  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final prefs = getIt<SharedPreferences>();
    final hasSeenOnboarding = prefs.getBool(AppConstants.onboardingCompletedKey) ?? false;
    
    // Check auth state
    final authState = ref.read(authStateProvider);
    
    authState.when(
      data: (user) {
        if (user == null) {
          // Not signed in
          if (hasSeenOnboarding) {
            // Has seen onboarding before → Go to login
            AppLogger.info('🔄 Returning user, not signed in → Login');
            _navigateTo(const LoginScreen());
          } else {
            // First time user → Show onboarding
            AppLogger.info('✨ First time user → Onboarding');
            _navigateTo(const OnboardingScreen());
          }
        } else {
          // User is signed in → Check if profile is complete
          ref.read(currentUserProvider).when(
            data: (appUser) {
              if (appUser?.gender == null || appUser?.gender?.isEmpty == true) {
                // Signed in but no gender selected → Go to gender selection
                AppLogger.info('👤 User signed in, profile incomplete → Gender selection');
                _navigateTo(const OnboardingScreen(skipToGender: true));
              } else {
                // Fully set up → Go to home
                AppLogger.info('✅ User signed in, profile complete → Home');
                _navigateTo(HomeScreen());
              }
            },
            loading: () {
              // Wait a bit more
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  _navigateTo(HomeScreen());
                }
              });
            },
            error: (_, __) {
              // Error loading profile → Go to home anyway
              _navigateTo(HomeScreen());
            },
          );
        }
      },
      loading: () {
        // Still loading auth state, wait
        Future.delayed(const Duration(milliseconds: 500), _navigateToNextScreen);
      },
      error: (error, _) {
        // Error with auth → Show login
        AppLogger.error('❌ Auth error on splash', error: error);
        _navigateTo(const LoginScreen());
      },
    );
  }

  void _navigateTo(Widget screen) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const rosePink = Color(0xFFF4C2C2);
    const primaryColor = Color(0xFF2D3250);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [rosePink, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated dress icon with confidence
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.checkroom,
                          size: 80,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // App name with style
                      Text(
                        AppConstants.appName,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          fontFamily: 'Poppins',
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Tagline
                      Text(
                        'Dress with Confidence',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: primaryColor.withOpacity(0.7),
                          fontFamily: 'Poppins',
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Loading indicator
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
                          strokeWidth: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
