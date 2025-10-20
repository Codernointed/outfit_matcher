import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestiq/core/models/wardrobe_item.dart';
import 'package:vestiq/core/models/clothing_analysis.dart';
import 'package:vestiq/core/services/outfit_storage_service.dart';
import 'package:vestiq/core/services/compatibility_cache_service.dart';
import 'package:vestiq/core/utils/logger.dart';
import 'package:vestiq/core/di/service_locator.dart';

/// Enhanced storage service for wardrobe items and looks with caching and migrations
class EnhancedWardrobeStorageService {
  final SharedPreferences _prefs;
  final OutfitStorageService _legacyStorage;

  // Storage keys
  static const String _wardrobeItemsKey = OutfitStorageKeys.wardrobeItems;
  static const String _wardrobeLooksKey = OutfitStorageKeys.wardrobeLooks;
  static const String _userPreferencesKey = 'user_preferences_v2';
  static const String _storageVersionKey = 'storage_version';
  static const String _cacheTimestampKey = 'cache_timestamp';

  static const int _currentStorageVersion = 2;
  static const Duration _cacheValidDuration = Duration(hours: 24);

  // In-memory cache
  List<WardrobeItem>? _cachedItems;
  List<WardrobeLook>? _cachedLooks;
  DateTime? _lastCacheUpdate;

  /// Callbacks to notify when wardrobe changes
  final List<VoidCallback> _onChangeCallbacks = [];

  EnhancedWardrobeStorageService(this._prefs, this._legacyStorage) {
    _initializeStorage();
  }

  /// Add a callback to be notified when wardrobe changes
  void addOnChangeListener(VoidCallback callback) {
    _onChangeCallbacks.add(callback);
  }

  /// Remove a callback
  void removeOnChangeListener(VoidCallback callback) {
    _onChangeCallbacks.remove(callback);
  }

  /// Notify all listeners that data has changed
  void _notifyListeners() {
    for (final callback in _onChangeCallbacks) {
      callback();
    }
  }

  /// Initialize storage and handle migrations
  Future<void> _initializeStorage() async {
    final currentVersion = _prefs.getInt(_storageVersionKey) ?? 1;

    if (currentVersion < _currentStorageVersion) {
      AppLogger.info(
        '📦 Migrating storage from version $currentVersion to $_currentStorageVersion',
      );
      await _migrateStorage(currentVersion, _currentStorageVersion);
      await _prefs.setInt(_storageVersionKey, _currentStorageVersion);
      AppLogger.info('✅ Storage migration complete');
    }

    // Force cache refresh on initialization to ensure data is loaded
    // This fixes hot restart issues where providers reset but storage persists
    AppLogger.info('🔄 Initializing wardrobe storage service');
    _invalidateCache();
  }

  /// Handle storage migrations
  Future<void> _migrateStorage(int fromVersion, int toVersion) async {
    if (fromVersion == 1 && toVersion >= 2) {
      // Migration from legacy storage to new wardrobe format
      try {
        final legacyOutfits = await _legacyStorage.fetchAll();
        AppLogger.info(
          '📦 Found ${legacyOutfits.length} legacy outfits to migrate',
        );

        // For now, we'll focus on the new wardrobe system
        // Legacy outfits can be accessed through the legacy service when needed

        AppLogger.info(
          '📦 Migration strategy: Legacy outfits preserved, new wardrobe system initialized',
        );
      } catch (e) {
        AppLogger.warning(
          '⚠️ Legacy migration had issues, continuing with fresh storage',
          error: e,
        );
      }
    }
  }

  // === CACHE MANAGEMENT ===

  /// Check if cache is valid
  bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!) < _cacheValidDuration;
  }

  /// Invalidate cache
  void _invalidateCache() {
    _cachedItems = null;
    _cachedLooks = null;
    _lastCacheUpdate = null;
  }

  /// Update cache timestamp
  Future<void> _updateCacheTimestamp() async {
    _lastCacheUpdate = DateTime.now();
    await _prefs.setString(
      _cacheTimestampKey,
      _lastCacheUpdate!.toIso8601String(),
    );
  }

  /// Ensure data is loaded and cached (useful for app initialization)
  Future<void> ensureDataLoaded() async {
    try {
      AppLogger.info('🔍 Ensuring wardrobe data is loaded...');

      // Force refresh cache to load from storage
      _invalidateCache();

      // Load wardrobe items
      final items = await getWardrobeItems();
      AppLogger.info('📦 Loaded ${items.length} wardrobe items from storage');

      // Pre-compute compatibility matrix if we have enough items
      if (items.length >= 2) {
        try {
          final compatibilityCache = getIt<CompatibilityCacheService>();
          await compatibilityCache.precomputeCompatibilityMatrix(items);
        } catch (e) {
          AppLogger.warning(
            '⚠️ Failed to precompute compatibility matrix',
            error: e,
          );
        }
      }

      // Load wardrobe looks
      final looks = await getWardrobeLooks();
      AppLogger.info('📦 Loaded ${looks.length} wardrobe looks from storage');

      // Update cache timestamp
      await _updateCacheTimestamp();

      AppLogger.info('✅ Wardrobe data loading complete');
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to ensure data is loaded',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // === WARDROBE ITEMS ===

  /// Save a wardrobe item
  Future<void> saveWardrobeItem(WardrobeItem item) async {
    try {
      final items = await getWardrobeItems();
      items.removeWhere((i) => i.id == item.id); // Remove if exists
      items.add(item);

      await _saveWardrobeItems(items);
      _invalidateCache(); // Invalidate cache after modification
      _notifyListeners(); // Notify listeners after save

      AppLogger.info(
        '💾 Wardrobe item saved',
        data: {
          'id': item.id,
          'type': item.analysis.itemType,
          'color': item.analysis.primaryColor,
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to save wardrobe item',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get all wardrobe items (with caching)
  Future<List<WardrobeItem>> getWardrobeItems() async {
    // Return cached items if valid
    if (_isCacheValid() && _cachedItems != null) {
      AppLogger.debug(
        '📦 Returning cached wardrobe items (${_cachedItems!.length} items)',
      );
      return List.from(_cachedItems!);
    }

    try {
      final itemsString = _prefs.getString(_wardrobeItemsKey);
      if (itemsString == null) {
        _cachedItems = [];
        await _updateCacheTimestamp();
        return [];
      }

      final itemsJson = jsonDecode(itemsString) as List;
      final items = itemsJson
          .map((json) => WardrobeItem.fromJson(json))
          .toList();

      // Update cache
      _cachedItems = items;
      await _updateCacheTimestamp();

      AppLogger.debug('📦 Loaded ${items.length} wardrobe items from storage');
      return List.from(items);
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to load wardrobe items',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Get wardrobe items by category
  Future<List<WardrobeItem>> getWardrobeItemsByCategory(String category) async {
    final items = await getWardrobeItems();

    if (category.toLowerCase() == 'all') return items;

    return items.where((item) {
      final itemType = item.analysis.itemType.toLowerCase();
      final categoryLower = category.toLowerCase();

      // Handle plural categories
      if (categoryLower.endsWith('s')) {
        final singular = categoryLower.substring(0, categoryLower.length - 1);
        return itemType.contains(singular) || itemType.contains(categoryLower);
      }

      return itemType.contains(categoryLower);
    }).toList();
  }

  /// Search wardrobe items
  Future<List<WardrobeItem>> searchWardrobeItems(String query) async {
    final items = await getWardrobeItems();
    final queryLower = query.toLowerCase();

    return items.where((item) {
      return item.analysis.itemType.toLowerCase().contains(queryLower) ||
          item.analysis.primaryColor.toLowerCase().contains(queryLower) ||
          item.analysis.subcategory?.toLowerCase().contains(queryLower) ==
              true ||
          item.userNotes?.toLowerCase().contains(queryLower) == true ||
          item.tags.any((tag) => tag.toLowerCase().contains(queryLower)) ||
          item.occasions.any(
            (occasion) => occasion.toLowerCase().contains(queryLower),
          );
    }).toList();
  }

  /// Get wardrobe items by multiple filters
  Future<List<WardrobeItem>> getFilteredWardrobeItems({
    String? category,
    String? color,
    String? occasion,
    String? season,
    bool? isFavorite,
    List<String>? tags,
    String? mood,
    String? weather,
    String? colorPreference,
    String? gender,
  }) async {
    final items = await getWardrobeItems();

    return items.where((item) {
      // Category filter
      if (category != null && category.toLowerCase() != 'all') {
        final itemType = item.analysis.itemType.toLowerCase();
        final categoryLower = category.toLowerCase();
        if (!itemType.contains(categoryLower)) return false;
      }

      // Color filter
      if (color != null) {
        if (!item.analysis.primaryColor.toLowerCase().contains(
          color.toLowerCase(),
        )) {
          return false;
        }
      }

      // Occasion filter
      if (occasion != null) {
        if (!item.matchesOccasion(occasion)) return false;
      }

      // Season filter
      if (season != null) {
        if (!item.matchesSeason(season)) return false;
      }

      // Favorite filter
      if (isFavorite != null) {
        if (item.isFavorite != isFavorite) return false;
      }

      // Tags filter
      if (tags != null && tags.isNotEmpty) {
        final hasMatchingTag = tags.any(
          (tag) => item.tags.any(
            (itemTag) => itemTag.toLowerCase().contains(tag.toLowerCase()),
          ),
        );
        if (!hasMatchingTag) return false;
      }

      // Mood filter (check style descriptors and stylePersonality)
      if (mood != null) {
        final styleDescriptors = item.analysis.styleDescriptors ?? [];
        final stylePersonality = item.analysis.stylePersonality ?? '';
        final moodLower = mood.toLowerCase();
        if (!styleDescriptors.any(
              (desc) => desc.toLowerCase().contains(moodLower),
            ) &&
            !stylePersonality.toLowerCase().contains(moodLower)) {
          return false;
        }
      }

      // Weather filter (check seasons and material)
      if (weather != null) {
        final weatherLower = weather.toLowerCase();
        final seasons = item.analysis.seasons ?? [];
        final material = item.analysis.material ?? '';

        if (weatherLower.contains('cold') || weatherLower.contains('cool')) {
          if (!seasons.any(
            (s) =>
                s.toLowerCase().contains('winter') ||
                s.toLowerCase().contains('fall'),
          )) {
            return false;
          }
        } else if (weatherLower.contains('hot') ||
            weatherLower.contains('warm')) {
          if (!seasons.any(
            (s) =>
                s.toLowerCase().contains('summer') ||
                s.toLowerCase().contains('spring'),
          )) {
            return false;
          }
        }
      }

      // Color preference filter (check color family and complementary colors)
      if (colorPreference != null) {
        final colorFamily = item.analysis.colorFamily ?? '';
        final complementaryColors = item.analysis.complementaryColors ?? [];
        final colorPrefLower = colorPreference.toLowerCase();

        if (!colorFamily.toLowerCase().contains(colorPrefLower) &&
            !complementaryColors.any(
              (c) => c.toLowerCase().contains(colorPrefLower),
            )) {
          return false;
        }
      }

      // Gender filter (check if item fits the preferred gender)
      if (gender != null) {
        final formality = item.analysis.formality ?? '';
        final style = item.analysis.style ?? '';

        // For now, use formality and style as proxies for gender appropriateness
        // This could be enhanced with better gender detection in the future
        if (gender == 'female' && formality.toLowerCase().contains('formal')) {
          // Formal items are generally more unisex
        } else if (gender == 'male' &&
            (style.toLowerCase().contains('feminine') ||
                formality.toLowerCase().contains('elegant'))) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Update wardrobe item
  Future<void> updateWardrobeItem(WardrobeItem item) async {
    await saveWardrobeItem(item);
  }

  /// Delete wardrobe item with proper image cleanup
  Future<void> deleteWardrobeItem(String itemId) async {
    try {
      final items = await getWardrobeItems();
      final itemToDelete = items.where((i) => i.id == itemId).firstOrNull;

      if (itemToDelete != null) {
        // Clean up the actual files if they exist
        await _cleanupImageFiles(itemToDelete);
      }

      items.removeWhere((i) => i.id == itemId);

      await _saveWardrobeItems(items);
      _invalidateCache();
      _notifyListeners(); // Notify listeners after delete

      AppLogger.info(
        '🗑️ Wardrobe item deleted with image cleanup',
        data: {'id': itemId},
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to delete wardrobe item',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Save list of wardrobe items
  Future<void> _saveWardrobeItems(List<WardrobeItem> items) async {
    final itemsJson = items.map((i) => i.toJson()).toList();
    await _prefs.setString(_wardrobeItemsKey, jsonEncode(itemsJson));
  }

  /// Clean up actual image files from storage
  Future<void> _cleanupImageFiles(WardrobeItem item) async {
    try {
      // Delete original image file
      final originalFile = File(item.originalImagePath);
      if (await originalFile.exists()) {
        await originalFile.delete();
        AppLogger.debug(
          '🗑️ Deleted original image file: ${item.originalImagePath}',
        );
      }

      // Delete polished image file if exists
      if (item.polishedImagePath != null) {
        final polishedFile = File(item.polishedImagePath!);
        if (await polishedFile.exists()) {
          await polishedFile.delete();
          AppLogger.debug(
            '🗑️ Deleted polished image file: ${item.polishedImagePath}',
          );
        }
      }
    } catch (e) {
      AppLogger.warning(
        '⚠️ Failed to cleanup image files for item ${item.id}',
        error: e,
      );
      // Don't throw - cleanup failure shouldn't prevent item deletion
    }
  }

  /// Batch upload multiple wardrobe items
  Future<int> batchUploadWardrobeItems(List<File> imageFiles) async {
    AppLogger.info('🚀 Starting batch upload of ${imageFiles.length} items');

    int successCount = 0;
    int processedCount = 0;

    try {
      for (final imageFile in imageFiles) {
        try {
          // Process each image (this would typically involve AI analysis)
          // For now, we'll create a basic wardrobe item
          final wardrobeItem = await _createWardrobeItemFromFile(imageFile);

          if (wardrobeItem != null) {
            await saveWardrobeItem(wardrobeItem);
            successCount++;
          }

          processedCount++;

          AppLogger.debug(
            '📦 Processed item $processedCount/${imageFiles.length}',
          );
        } catch (e, stackTrace) {
          AppLogger.warning(
            '⚠️ Failed to process item ${processedCount + 1}',
            error: e,
            stackTrace: stackTrace,
          );
          processedCount++;
        }
      }

      AppLogger.info(
        '✅ Batch upload completed: $successCount/$processedCount items uploaded',
      );
      return successCount;
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Batch upload failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Create a wardrobe item from an image file (placeholder implementation)
  Future<WardrobeItem?> _createWardrobeItemFromFile(File imageFile) async {
    try {
      // For now, create a basic wardrobe item with placeholder analysis
      // In a real implementation, this would call the AI analysis service
      final analysis = ClothingAnalysis(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        itemType: 'Unknown', // Would be determined by AI
        primaryColor: 'Unknown', // Would be determined by AI
        patternType: 'solid',
        style: 'casual',
        seasons: ['All Seasons'],
        confidence: 0.8,
        tags: [],
        rawAttributes: const {},
      );

      final wardrobeItem = WardrobeItem(
        id: 'batch_${DateTime.now().millisecondsSinceEpoch}',
        analysis: analysis,
        originalImagePath: imageFile.path,
        createdAt: DateTime.now(),
      );

      AppLogger.debug('✅ Created wardrobe item from file: ${imageFile.path}');
      return wardrobeItem;
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to create wardrobe item from file',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  // === WARDROBE LOOKS ===

  /// Save a wardrobe look
  Future<void> saveWardrobeLook(WardrobeLook look) async {
    try {
      final looks = await getWardrobeLooks();
      looks.removeWhere((l) => l.id == look.id); // Remove if exists
      looks.add(look);

      final looksJson = looks.map((l) => l.toJson()).toList();
      await _prefs.setString(_wardrobeLooksKey, jsonEncode(looksJson));
      _invalidateCache();

      AppLogger.info(
        '💾 Wardrobe look saved',
        data: {'id': look.id, 'title': look.title},
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to save wardrobe look',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get all wardrobe looks (with caching)
  Future<List<WardrobeLook>> getWardrobeLooks() async {
    // Return cached looks if valid
    if (_isCacheValid() && _cachedLooks != null) {
      AppLogger.debug(
        '📦 Returning cached wardrobe looks (${_cachedLooks!.length} looks)',
      );
      return List.from(_cachedLooks!);
    }

    try {
      final looksString = _prefs.getString(_wardrobeLooksKey);
      if (looksString == null) {
        _cachedLooks = [];
        await _updateCacheTimestamp();
        return [];
      }

      final looksJson = jsonDecode(looksString) as List;
      final looks = looksJson
          .map((json) => WardrobeLook.fromJson(json))
          .toList();

      // Update cache
      _cachedLooks = looks;
      await _updateCacheTimestamp();

      AppLogger.debug('📦 Loaded ${looks.length} wardrobe looks from storage');
      return List.from(looks);
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to load wardrobe looks',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Delete wardrobe look
  Future<void> deleteWardrobeLook(String lookId) async {
    try {
      final looks = await getWardrobeLooks();
      looks.removeWhere((l) => l.id == lookId);

      final looksJson = looks.map((l) => l.toJson()).toList();
      await _prefs.setString(_wardrobeLooksKey, jsonEncode(looksJson));
      _invalidateCache();

      AppLogger.info('🗑️ Wardrobe look deleted', data: {'id': lookId});
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to delete wardrobe look',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // === USER PREFERENCES ===

  /// Save user preferences
  Future<void> saveUserPreferences(Map<String, dynamic> preferences) async {
    try {
      await _prefs.setString(_userPreferencesKey, jsonEncode(preferences));
      AppLogger.info('💾 User preferences saved');
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to save user preferences',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get user preferences
  Future<Map<String, dynamic>> getUserPreferences() async {
    try {
      final prefsString = _prefs.getString(_userPreferencesKey);
      if (prefsString == null) return {};

      return Map<String, dynamic>.from(jsonDecode(prefsString));
    } catch (e) {
      AppLogger.error('❌ Failed to load user preferences', error: e);
      return {};
    }
  }

  // === UTILITY METHODS ===

  /// Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    final wardrobeItems = await getWardrobeItems();
    final wardrobeLooks = await getWardrobeLooks();
    final legacyOutfits = await _legacyStorage.fetchAll();

    return {
      'wardrobeItems': wardrobeItems.length,
      'wardrobeLooks': wardrobeLooks.length,
      'legacyOutfits': legacyOutfits.length,
      'storageVersion': _prefs.getInt(_storageVersionKey) ?? 1,
      'cacheValid': _isCacheValid(),
      'lastCacheUpdate': _lastCacheUpdate?.toIso8601String(),
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  /// Clear all data (except legacy)
  Future<void> clearAllData() async {
    await _prefs.remove(_wardrobeItemsKey);
    await _prefs.remove(_wardrobeLooksKey);
    await _prefs.remove(_userPreferencesKey);
    await _prefs.remove(_cacheTimestampKey);

    _invalidateCache();
    AppLogger.info('🗑️ All wardrobe storage data cleared');
  }

  /// Force cache refresh
  Future<void> refreshCache() async {
    _invalidateCache();
    await getWardrobeItems(); // This will reload and cache
    await getWardrobeLooks(); // This will reload and cache
    AppLogger.info('🔄 Cache refreshed');
  }

  /// Export data for backup
  Future<Map<String, dynamic>> exportData() async {
    return {
      'wardrobeItems': (await getWardrobeItems())
          .map((i) => i.toJson())
          .toList(),
      'wardrobeLooks': (await getWardrobeLooks())
          .map((l) => l.toJson())
          .toList(),
      'userPreferences': await getUserPreferences(),
      'exportedAt': DateTime.now().toIso8601String(),
      'version': _currentStorageVersion,
    };
  }

  /// Import data from backup
  Future<void> importData(Map<String, dynamic> data) async {
    try {
      // Import wardrobe items
      if (data['wardrobeItems'] != null) {
        final items = (data['wardrobeItems'] as List)
            .map((json) => WardrobeItem.fromJson(json))
            .toList();
        await _saveWardrobeItems(items);
      }

      // Import wardrobe looks
      if (data['wardrobeLooks'] != null) {
        final looks = (data['wardrobeLooks'] as List)
            .map((json) => WardrobeLook.fromJson(json))
            .toList();
        final looksJson = looks.map((l) => l.toJson()).toList();
        await _prefs.setString(_wardrobeLooksKey, jsonEncode(looksJson));
      }

      // Import user preferences
      if (data['userPreferences'] != null) {
        await saveUserPreferences(data['userPreferences']);
      }

      _invalidateCache();
      AppLogger.info('📥 Data import complete');
    } catch (e, stackTrace) {
      AppLogger.error('❌ Data import failed', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
