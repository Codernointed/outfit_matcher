import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestiq/core/services/outfit_storage_service.dart';
import 'package:vestiq/core/services/enhanced_wardrobe_storage_service.dart';
import 'package:vestiq/core/services/app_settings_service.dart';
import 'package:vestiq/core/services/image_processing_service.dart';
import 'package:vestiq/core/services/wardrobe_pairing_service.dart';
import 'package:vestiq/core/utils/image_cache_manager.dart';
import 'package:vestiq/core/utils/permission_handler_service.dart';

/// Global GetIt instance for dependency injection
final GetIt getIt = GetIt.instance;

/// Set up the service locator for dependency injection
Future<void> setupServiceLocator() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);

  // Repositories

  // Core Services
  getIt.registerLazySingleton<OutfitStorageService>(
    () => OutfitStorageService(sharedPreferences),
  );
  
  getIt.registerLazySingleton<EnhancedWardrobeStorageService>(
    () => EnhancedWardrobeStorageService(
      sharedPreferences,
      getIt<OutfitStorageService>(),
    ),
  );
  
  getIt.registerLazySingleton<PermissionHandlerService>(
    () => PermissionHandlerService(),
  );
  
  getIt.registerLazySingleton<AppSettingsService>(
    () => AppSettingsService(sharedPreferences),
  );

  // Wardrobe Services
  getIt.registerLazySingleton<ImageProcessingService>(
    () => ImageProcessingService(),
  );
  
  getIt.registerLazySingleton<WardrobePairingService>(
    () => WardrobePairingService(),
  );

  getIt.registerLazySingleton<ImageCacheManager>(
    () => ImageCacheManager.instance,
  );

  // Controllers

  // Use cases
}
