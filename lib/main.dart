import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart'; // Import Analytics
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestiq/core/constants/app_constants.dart';
import 'package:vestiq/core/di/service_locator.dart';
import 'package:vestiq/core/theme/app_theme.dart';
import 'package:vestiq/core/router/app_router.dart';
import 'package:vestiq/firebase_options.dart';
import 'package:vestiq/core/utils/logger.dart';
import 'package:vestiq/features/auth/presentation/widgets/auth_wrapper.dart';
import 'package:vestiq/features/auth/presentation/providers/auth_flow_controller.dart';
import 'package:vestiq/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:vestiq/features/outfit_suggestions/presentation/screens/home_screen.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables - IMPORTANT: Load order matters!
  // First, try to load the optional paystack file
  Map<String, String> paystackEnv = {};
  try {
    await dotenv.load(fileName: ".env.paystack");
    paystackEnv = Map<String, String>.from(dotenv.env);
    AppLogger.info('🔐 Paystack env loaded first');
  } catch (e) {
    AppLogger.warning('⚠️ Paystack env not found, continuing without it');
  }

  // Now load the main .env file, merging with paystack env
  await dotenv.load(fileName: ".env", mergeWith: paystackEnv);
  AppLogger.info('✅ Main .env loaded (${dotenv.env.keys.length} keys total)');

  // Debug: Verify API keys loaded
  final geminiKey1 = dotenv.env['GEMINI_API_KEY'];
  final geminiKey2 = dotenv.env['GEMINI_API_KEY2'];
  if (geminiKey1 != null && geminiKey1.isNotEmpty) {
    final masked =
        '${geminiKey1.substring(0, 5)}...${geminiKey1.substring(geminiKey1.length - 5)}';
    AppLogger.info('✅ GEMINI_API_KEY loaded: $masked');
  } else {
    AppLogger.error('❌ GEMINI_API_KEY not found in .env!');
  }
  if (geminiKey2 != null && geminiKey2.isNotEmpty) {
    final masked =
        '${geminiKey2.substring(0, 5)}...${geminiKey2.substring(geminiKey2.length - 5)}';
    AppLogger.info('✅ GEMINI_API_KEY2 loaded: $masked');
  } else {
    AppLogger.warning('⚠️ GEMINI_API_KEY2 not found in .env (optional)');
  }

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

  // Get SharedPreferences to override provider
  final sharedPrefs = getIt<SharedPreferences>();

  runApp(
    ProviderScope(
      overrides: [
        // Override the sharedPreferencesProvider with actual instance
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      ],
      child: const VestiqApp(),
    ),
  );
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
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      ],
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
