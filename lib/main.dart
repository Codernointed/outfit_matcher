import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestiq/core/constants/app_constants.dart';
import 'package:vestiq/core/di/service_locator.dart';
import 'package:vestiq/core/theme/app_theme.dart';
import 'package:vestiq/core/router/app_router.dart';
import 'package:vestiq/firebase_options.dart';
import 'package:vestiq/core/utils/logger.dart';
import 'package:vestiq/features/auth/presentation/widgets/auth_wrapper.dart';
import 'package:vestiq/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:vestiq/features/outfit_suggestions/presentation/screens/home_screen.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppLogger.info('🔥 Firebase initialized successfully');
  } catch (e) {
    AppLogger.error('❌ Firebase initialization failed', error: e);
  }

  // Initialize dependency injection
  await setupServiceLocator();

  runApp(const ProviderScope(child: VestiqApp()));
}

/// The main app widget
class VestiqApp extends ConsumerWidget {
  /// Default constructor
  const VestiqApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(appThemeModeProvider);

    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.getLightTheme(),
      darkTheme: AppTheme.getDarkTheme(),
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
      // Don't include routes with '/' key when home is specified
      routes: {
        AppRouter.onboarding: (context) => const OnboardingScreen(),
        AppRouter.home: (context) => HomeScreen(),
      },
    );
  }
}

/// Global theme mode provider
final appThemeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
      return ThemeModeNotifier();
    });

/// Theme mode notifier
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light) {
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    try {
      // Import here to avoid circular dependencies
      final getIt = GetIt.I;
      if (getIt.isRegistered<SharedPreferences>()) {
        final prefs = getIt<SharedPreferences>();
        final saved = prefs.getString('theme_preference');
        if (saved != null) {
          state = ThemeMode.values.firstWhere(
            (e) => e.name == saved,
            orElse: () => ThemeMode.light,
          );
        }
      }
    } catch (_) {
      // Ignore errors on initial load
    }
  }

  void toggleTheme() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }
}
