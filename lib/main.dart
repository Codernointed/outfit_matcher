import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:outfit_matcher/core/constants/app_constants.dart';
import 'package:outfit_matcher/core/di/service_locator.dart';
import 'package:outfit_matcher/core/theme/app_theme.dart';
import 'package:outfit_matcher/core/router/app_router.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize dependency injection
  await setupServiceLocator();

  runApp(const ProviderScope(child: OutfitMatcherApp()));
}

/// The main app widget
class OutfitMatcherApp extends StatelessWidget {
  /// Default constructor
  const OutfitMatcherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.getLightTheme(),
      debugShowCheckedModeBanner: false,
      initialRoute: AppRouter.splash,
      routes: AppRouter.getBasicRoutes(),
    );
  }
}
