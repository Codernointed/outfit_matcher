import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestiq/core/services/outfit_storage_service.dart';
import 'package:vestiq/core/services/enhanced_wardrobe_storage_service.dart';
import 'package:vestiq/core/services/app_settings_service.dart';
import 'package:vestiq/core/services/image_processing_service.dart';
import 'package:vestiq/core/services/wardrobe_pairing_service.dart';
import 'package:vestiq/core/services/mannequin_cache_service.dart';
import 'package:vestiq/core/services/compatibility_cache_service.dart';
import 'package:vestiq/core/utils/image_cache_manager.dart';
import 'package:vestiq/core/services/file_based_storage_service.dart';
import 'package:vestiq/core/services/voice_search_service.dart';
import 'package:vestiq/core/services/profile_service.dart';

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

  getIt.registerLazySingleton<AppSettingsService>(
    () => AppSettingsService(sharedPreferences),
  );

  // Wardrobe Services
  getIt.registerLazySingleton<ImageProcessingService>(
    () => ImageProcessingService(),
  );

  getIt.registerLazySingleton<CompatibilityCacheService>(
    () => CompatibilityCacheService(),
  );

  getIt.registerLazySingleton<MannequinCacheService>(
    () => MannequinCacheService(sharedPreferences),
  );

  getIt.registerLazySingleton<WardrobePairingService>(
    () => WardrobePairingService(
      compatibilityCache: getIt<CompatibilityCacheService>(),
    ),
  );

  getIt.registerLazySingleton<ImageCacheManager>(
    () => ImageCacheManager.instance,
  );

  getIt.registerLazySingleton<FileBasedStorageService>(
    () => FileBasedStorageService.instance,
  );

  getIt.registerLazySingleton<VoiceSearchService>(() => VoiceSearchService());

  getIt.registerLazySingleton<ProfileService>(
    () => ProfileService(sharedPreferences),
  );

  // Controllers

  // Use cases
}
