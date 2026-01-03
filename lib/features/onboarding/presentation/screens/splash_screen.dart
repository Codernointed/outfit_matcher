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
import 'package:vestiq/core/theme/app_theme.dart';

/// Premium animated splash screen with smooth transitions
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();

    // Main animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    // Pulse animation for the logo
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    _controller.forward();
    _pulseController.repeat(reverse: true);

    _navigateToNextScreen();
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(milliseconds: 2200));

    if (!mounted) return;

    try {
      final prefs = getIt<SharedPreferences>();
      final authState = ref.read(authStateProvider);

      await authState.when(
        data: (user) async {
          AppLogger.info('🔍 Auth check - User: ${user?.uid ?? "null"}');

          if (user == null) {
            final hasSeenOnboarding =
                prefs.getBool(AppConstants.onboardingCompletedKey) ?? false;

            if (hasSeenOnboarding) {
              AppLogger.info('🔄 Returning user, not signed in → Login');
              _navigateTo(const LoginScreen());
            } else {
              AppLogger.info('✨ First time user → Onboarding');
              _navigateTo(const OnboardingScreen());
            }
          } else {
            AppLogger.info('✅ User authenticated: ${user.uid}');

            final currentUserAsync = ref.read(currentUserProvider);
            await currentUserAsync.when(
              data: (appUser) async {
                if (appUser == null) {
                  AppLogger.error(
                    '❌ Auth exists but no profile found! Signing out...',
                  );
                  await ref.read(authControllerProvider.notifier).signOut();
                  if (mounted) {
                    _navigateTo(const LoginScreen());
                  }
                  return;
                }

                if (appUser.gender == null || appUser.gender?.isEmpty == true) {
                  AppLogger.info('👤 Profile incomplete → Gender selection');
                  _navigateTo(const OnboardingScreen());
                } else {
                  AppLogger.info('✅ Profile complete → Home');
                  _navigateTo(HomeScreen());
                }
              },
              loading: () async {
                AppLogger.info('⏳ Loading user profile...');
                await Future.delayed(const Duration(milliseconds: 1500));
                if (mounted) {
                  final retry = ref.read(currentUserProvider);
                  retry.whenData((retryUser) {
                    if (retryUser != null) {
                      _navigateTo(HomeScreen());
                    } else {
                      _navigateTo(const LoginScreen());
                    }
                  });
                }
              },
              error: (error, stackTrace) async {
                AppLogger.error(
                  '❌ Error loading profile, signing out',
                  error: error,
                  stackTrace: stackTrace,
                );
                await ref.read(authControllerProvider.notifier).signOut();
                if (mounted) {
                  _navigateTo(const LoginScreen());
                }
              },
            );
          }
        },
        loading: () async {
          AppLogger.info('⏳ Loading auth state...');
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            _navigateToNextScreen();
          }
        },
        error: (error, stackTrace) async {
          AppLogger.error(
            '❌ Auth error on splash',
            error: error,
            stackTrace: stackTrace,
          );
          _navigateTo(const LoginScreen());
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Unexpected error in navigation',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        _navigateTo(const LoginScreen());
      }
    }
  }

  void _navigateTo(Widget screen) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF1A1A1A),
                    const Color(0xFF0F0F0F),
                    const Color(0xFF000000),
                  ]
                : [
                    primaryColor.withValues(alpha: 0.1),
                    AppTheme.secondaryBackgroundColor,
                    Colors.white,
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated background orbs
            ...List.generate(
              3,
              (index) => _buildFloatingOrb(index, primaryColor),
            ),

            // Main content
            Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([_controller, _pulseController]),
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value * _pulseAnimation.value,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Premium logo container
                          Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  primaryColor.withValues(alpha: 0.9),
                                  primaryColor.withValues(alpha: 0.6),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.3),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                              ],
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.checkroom_rounded,
                              size: 72,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 40),

                          // App name with shimmer effect
                          ShaderMask(
                            shaderCallback: (bounds) {
                              return LinearGradient(
                                colors: [
                                  isDark ? Colors.white : Colors.black87,
                                  primaryColor,
                                  isDark ? Colors.white : Colors.black87,
                                ],
                                stops: [
                                  (_shimmerAnimation.value - 0.3).clamp(
                                    0.0,
                                    1.0,
                                  ),
                                  _shimmerAnimation.value.clamp(0.0, 1.0),
                                  (_shimmerAnimation.value + 0.3).clamp(
                                    0.0,
                                    1.0,
                                  ),
                                ],
                              ).createShader(bounds);
                            },
                            child: Text(
                              AppConstants.appName.toUpperCase(),
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : Colors.black87,
                                letterSpacing: 8,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Tagline
                          Text(
                            'Dress with Confidence',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.85)
                                  : Colors.black54,
                              letterSpacing: 2,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 60),

                          // Premium loading indicator
                          _buildPremiumLoader(primaryColor),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingOrb(int index, Color primaryColor) {
    final positions = [
      const Alignment(-0.8, -0.6),
      const Alignment(0.7, -0.3),
      const Alignment(-0.5, 0.7),
    ];
    final sizes = [120.0, 80.0, 100.0];
    final colors = [
      primaryColor.withValues(alpha: 0.1),
      primaryColor.withValues(alpha: 0.05),
      primaryColor.withValues(alpha: 0.03),
    ];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Align(
          alignment: positions[index],
          child: Transform.scale(
            scale: _fadeAnimation.value,
            child: Container(
              width: sizes[index],
              height: sizes[index],
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors[index],
                boxShadow: [
                  BoxShadow(
                    color: colors[index],
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPremiumLoader(Color primaryColor) {
    return SizedBox(
      width: 44,
      height: 44,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
        strokeWidth: 2.5,
        backgroundColor: primaryColor.withValues(alpha: 0.1),
      ),
    );
  }
}
