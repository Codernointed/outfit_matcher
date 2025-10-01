import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vestiq/core/constants/app_constants.dart';
import 'package:vestiq/core/di/service_locator.dart';
import 'package:vestiq/core/theme/app_theme.dart';
import 'package:vestiq/core/router/app_router.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize dependency injection
  await setupServiceLocator();

  runApp(const ProviderScope(child: VestiqApp()));
}

/// The main app widget
class VestiqApp extends StatelessWidget {
  /// Default constructor
  const VestiqApp({super.key});

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
