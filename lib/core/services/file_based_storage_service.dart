import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:vestiq/core/models/wardrobe_item.dart';
import 'package:vestiq/core/utils/logger.dart';

/// Enhanced storage service using local files for large data and SharedPreferences for small data
class FileBasedStorageService {
  static FileBasedStorageService? _instance;
  static const String _dataDirectory = 'vestiq_data';
  static const String _wardrobeItemsFile = 'wardrobe_items.json';
  static const String _wardrobeLooksFile = 'wardrobe_looks.json';
  static const String _userPreferencesFile = 'user_preferences.json';
  static const String _appSettingsFile = 'app_settings.json';

  late Directory _dataDir;
  bool _initialized = false;

  // Singleton pattern
  static FileBasedStorageService get instance {
    _instance ??= FileBasedStorageService._();
    return _instance!;
  }

  FileBasedStorageService._();

  /// Initialize storage directory and ensure it exists
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      _dataDir = Directory('${appDir.path}/$_dataDirectory');

      if (!await _dataDir.exists()) {
        await _dataDir.create(recursive: true);
        AppLogger.info('📁 Created data directory: ${_dataDir.path}');
      }

      _initialized = true;
      AppLogger.info('✅ File-based storage initialized');
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to initialize file-based storage',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get file path for a given filename
  Future<String> _getFilePath(String filename) async {
    await initialize();
    return '${_dataDir.path}/$filename';
  }

  // === WARDROBE ITEMS ===

  /// Save wardrobe items to file
  Future<void> saveWardrobeItems(List<WardrobeItem> items) async {
    try {
      final filePath = await _getFilePath(_wardrobeItemsFile);
      final file = File(filePath);

      // Ensure directory exists
      await _dataDir.create(recursive: true);

      final itemsJson = items.map((item) => item.toJson()).toList();
      final jsonString = jsonEncode(itemsJson);

      await file.writeAsString(jsonString, flush: true);

      AppLogger.info('💾 Saved ${items.length} wardrobe items to file');
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to save wardrobe items',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Load wardrobe items from file
  Future<List<WardrobeItem>> loadWardrobeItems() async {
    try {
      final filePath = await _getFilePath(_wardrobeItemsFile);
      final file = File(filePath);

      if (!await file.exists()) {
        AppLogger.debug(
          '📄 Wardrobe items file does not exist, returning empty list',
        );
        return [];
      }

      final jsonString = await file.readAsString();
      final itemsJson = jsonDecode(jsonString) as List<dynamic>;

      final items = itemsJson
          .map((json) => WardrobeItem.fromJson(json as Map<String, dynamic>))
          .toList();

      AppLogger.info('📂 Loaded ${items.length} wardrobe items from file');
      return items;
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to load wardrobe items',
        error: e,
        stackTrace: stackTrace,
      );
      // Return empty list on error to prevent crashes
      return [];
    }
  }

  // === WARDROBE LOOKS ===

  /// Save wardrobe looks to file
  Future<void> saveWardrobeLooks(List<WardrobeLook> looks) async {
    try {
      final filePath = await _getFilePath(_wardrobeLooksFile);
      final file = File(filePath);

      await _dataDir.create(recursive: true);

      final looksJson = looks.map((look) => look.toJson()).toList();
      final jsonString = jsonEncode(looksJson);

      await file.writeAsString(jsonString, flush: true);

      AppLogger.info('💾 Saved ${looks.length} wardrobe looks to file');
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to save wardrobe looks',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Load wardrobe looks from file
  Future<List<WardrobeLook>> loadWardrobeLooks() async {
    try {
      final filePath = await _getFilePath(_wardrobeLooksFile);
      final file = File(filePath);

      if (!await file.exists()) {
        AppLogger.debug(
          '📄 Wardrobe looks file does not exist, returning empty list',
        );
        return [];
      }

      final jsonString = await file.readAsString();
      final looksJson = jsonDecode(jsonString) as List<dynamic>;

      final looks = looksJson
          .map((json) => WardrobeLook.fromJson(json as Map<String, dynamic>))
          .toList();

      AppLogger.info('📂 Loaded ${looks.length} wardrobe looks from file');
      return looks;
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to load wardrobe looks',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  // === USER PREFERENCES ===

  /// Save user preferences to file
  Future<void> saveUserPreferences(Map<String, dynamic> preferences) async {
    try {
      final filePath = await _getFilePath(_userPreferencesFile);
      final file = File(filePath);

      await _dataDir.create(recursive: true);

      final jsonString = jsonEncode(preferences);
      await file.writeAsString(jsonString, flush: true);

      AppLogger.info('💾 Saved user preferences to file');
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to save user preferences',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Load user preferences from file
  Future<Map<String, dynamic>> loadUserPreferences() async {
    try {
      final filePath = await _getFilePath(_userPreferencesFile);
      final file = File(filePath);

      if (!await file.exists()) {
        AppLogger.debug(
          '📄 User preferences file does not exist, returning empty map',
        );
        return {};
      }

      final jsonString = await file.readAsString();
      final preferences = jsonDecode(jsonString) as Map<String, dynamic>;

      AppLogger.info('📂 Loaded user preferences from file');
      return preferences;
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to load user preferences',
        error: e,
        stackTrace: stackTrace,
      );
      return {};
    }
  }

  // === APP SETTINGS ===

  /// Save app settings to file
  Future<void> saveAppSettings(Map<String, dynamic> settings) async {
    try {
      final filePath = await _getFilePath(_appSettingsFile);
      final file = File(filePath);

      await _dataDir.create(recursive: true);

      final jsonString = jsonEncode(settings);
      await file.writeAsString(jsonString, flush: true);

      AppLogger.info('💾 Saved app settings to file');
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to save app settings',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Load app settings from file
  Future<Map<String, dynamic>> loadAppSettings() async {
    try {
      final filePath = await _getFilePath(_appSettingsFile);
      final file = File(filePath);

      if (!await file.exists()) {
        AppLogger.debug(
          '📄 App settings file does not exist, returning empty map',
        );
        return {};
      }

      final jsonString = await file.readAsString();
      final settings = jsonDecode(jsonString) as Map<String, dynamic>;

      AppLogger.info('📂 Loaded app settings from file');
      return settings;
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to load app settings',
        error: e,
        stackTrace: stackTrace,
      );
      return {};
    }
  }

  // === MIGRATION UTILITIES ===

  /// Migrate data from SharedPreferences to file-based storage
  Future<void> migrateFromSharedPreferences({
    required List<WardrobeItem> wardrobeItems,
    required List<WardrobeLook> wardrobeLooks,
    required Map<String, dynamic> userPreferences,
    required Map<String, dynamic> appSettings,
  }) async {
    try {
      AppLogger.info(
        '🚚 Starting migration from SharedPreferences to file storage',
      );

      await initialize();

      // Save all data to files
      if (wardrobeItems.isNotEmpty) {
        await saveWardrobeItems(wardrobeItems);
      }

      if (wardrobeLooks.isNotEmpty) {
        await saveWardrobeLooks(wardrobeLooks);
      }

      if (userPreferences.isNotEmpty) {
        await saveUserPreferences(userPreferences);
      }

      if (appSettings.isNotEmpty) {
        await saveAppSettings(appSettings);
      }

      AppLogger.info('✅ Migration completed successfully');
    } catch (e, stackTrace) {
      AppLogger.error('❌ Migration failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // === UTILITY METHODS ===

  /// Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final wardrobeItems = await loadWardrobeItems();
      final wardrobeLooks = await loadWardrobeLooks();
      final userPreferences = await loadUserPreferences();
      final appSettings = await loadAppSettings();

      // Calculate file sizes
      final itemsFilePath = await _getFilePath(_wardrobeItemsFile);
      final looksFilePath = await _getFilePath(_wardrobeLooksFile);
      final prefsFilePath = await _getFilePath(_userPreferencesFile);
      final settingsFilePath = await _getFilePath(_appSettingsFile);

      final itemsFile = File(itemsFilePath);
      final looksFile = File(looksFilePath);
      final prefsFile = File(prefsFilePath);
      final settingsFile = File(settingsFilePath);

      return {
        'wardrobeItems': wardrobeItems.length,
        'wardrobeLooks': wardrobeLooks.length,
        'userPreferences': userPreferences.length,
        'appSettings': appSettings.length,
        'itemsFileSize': await itemsFile.exists()
            ? await itemsFile.length()
            : 0,
        'looksFileSize': await looksFile.exists()
            ? await looksFile.length()
            : 0,
        'prefsFileSize': await prefsFile.exists()
            ? await prefsFile.length()
            : 0,
        'settingsFileSize': await settingsFile.exists()
            ? await settingsFile.length()
            : 0,
        'storagePath': _dataDir.path,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to get storage stats',
        error: e,
        stackTrace: stackTrace,
      );
      return {};
    }
  }

  /// Clear all data
  Future<void> clearAllData() async {
    try {
      await initialize();

      final files = [
        _wardrobeItemsFile,
        _wardrobeLooksFile,
        _userPreferencesFile,
        _appSettingsFile,
      ];

      for (final filename in files) {
        final filePath = await _getFilePath(filename);
        final file = File(filePath);

        if (await file.exists()) {
          await file.delete();
          AppLogger.debug('🗑️ Deleted file: $filename');
        }
      }

      AppLogger.info('🧹 All data cleared');
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to clear all data',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Export data for backup
  Future<Map<String, dynamic>> exportData() async {
    try {
      return {
        'wardrobeItems': (await loadWardrobeItems())
            .map((i) => i.toJson())
            .toList(),
        'wardrobeLooks': (await loadWardrobeLooks())
            .map((l) => l.toJson())
            .toList(),
        'userPreferences': await loadUserPreferences(),
        'appSettings': await loadAppSettings(),
        'exportedAt': DateTime.now().toIso8601String(),
        'version': '2.0', // File-based storage version
      };
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to export data',
        error: e,
        stackTrace: stackTrace,
      );
      return {};
    }
  }

  /// Import data from backup
  Future<void> importData(Map<String, dynamic> data) async {
    try {
      await initialize();

      // Import wardrobe items
      if (data['wardrobeItems'] != null) {
        final items = (data['wardrobeItems'] as List<dynamic>)
            .map((json) => WardrobeItem.fromJson(json as Map<String, dynamic>))
            .toList();
        await saveWardrobeItems(items);
      }

      // Import wardrobe looks
      if (data['wardrobeLooks'] != null) {
        final looks = (data['wardrobeLooks'] as List<dynamic>)
            .map((json) => WardrobeLook.fromJson(json as Map<String, dynamic>))
            .toList();
        await saveWardrobeLooks(looks);
      }

      // Import user preferences
      if (data['userPreferences'] != null) {
        await saveUserPreferences(
          data['userPreferences'] as Map<String, dynamic>,
        );
      }

      // Import app settings
      if (data['appSettings'] != null) {
        await saveAppSettings(data['appSettings'] as Map<String, dynamic>);
      }

      AppLogger.info('📥 Data import completed');
    } catch (e, stackTrace) {
      AppLogger.error('❌ Data import failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
