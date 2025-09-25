import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:outfit_matcher/core/services/outfit_storage_service.dart';
import 'package:outfit_matcher/core/utils/permission_handler_service.dart';

/// Global GetIt instance for dependency injection
final GetIt getIt = GetIt.instance;

/// Set up the service locator for dependency injection
Future<void> setupServiceLocator() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);

  // Repositories

  // Services
  getIt.registerLazySingleton<OutfitStorageService>(
    () => OutfitStorageService(sharedPreferences),
  );
  getIt.registerLazySingleton<PermissionHandlerService>(
    () => PermissionHandlerService(),
  );

  // Controllers

  // Use cases
}
