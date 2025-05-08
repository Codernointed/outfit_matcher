import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global GetIt instance for dependency injection
final GetIt getIt = GetIt.instance;

/// Set up the service locator for dependency injection
Future<void> setupServiceLocator() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);

  // Repositories

  // Services

  // Controllers

  // Use cases
}
