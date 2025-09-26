import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:outfit_matcher/core/models/wardrobe_item.dart';
import 'package:outfit_matcher/core/models/clothing_analysis.dart';
import 'package:outfit_matcher/core/services/outfit_storage_service.dart';
import 'package:outfit_matcher/core/utils/logger.dart';

/// Enhanced storage service for wardrobe items and looks with caching and migrations
class EnhancedWardrobeStorageService {
  final SharedPreferences _prefs;
  final OutfitStorageService _legacyStorage;
  
  // Storage keys
  static const String _wardrobeItemsKey = 'wardrobe_items_v2';
  static const String _wardrobeLooksKey = 'wardrobe_looks_v2';
  static const String _userPreferencesKey = 'user_preferences_v2';
  static const String _storageVersionKey = 'storage_version';
  static const String _cacheTimestampKey = 'cache_timestamp';
  
  static const int _currentStorageVersion = 2;
  static const Duration _cacheValidDuration = Duration(hours: 24);

  // In-memory cache
  List<WardrobeItem>? _cachedItems;
  List<WardrobeLook>? _cachedLooks;
  DateTime? _lastCacheUpdate;

  EnhancedWardrobeStorageService(this._prefs, this._legacyStorage) {
    _initializeStorage();
  }

  /// Initialize storage and handle migrations
  Future<void> _initializeStorage() async {
    final currentVersion = _prefs.getInt(_storageVersionKey) ?? 1;
    
    if (currentVersion < _currentStorageVersion) {
      AppLogger.info('📦 Migrating storage from version $currentVersion to $_currentStorageVersion');
      await _migrateStorage(currentVersion, _currentStorageVersion);
      await _prefs.setInt(_storageVersionKey, _currentStorageVersion);
      AppLogger.info('✅ Storage migration complete');
    }
  }

  /// Handle storage migrations
  Future<void> _migrateStorage(int fromVersion, int toVersion) async {
    if (fromVersion == 1 && toVersion >= 2) {
      // Migration from legacy storage to new wardrobe format
      try {
        final legacyOutfits = await _legacyStorage.fetchAll();
        AppLogger.info('📦 Found ${legacyOutfits.length} legacy outfits to migrate');
        
        // For now, we'll focus on the new wardrobe system
        // Legacy outfits can be accessed through the legacy service when needed
        
        AppLogger.info('📦 Migration strategy: Legacy outfits preserved, new wardrobe system initialized');
      } catch (e) {
        AppLogger.warning('⚠️ Legacy migration had issues, continuing with fresh storage', error: e);
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
    await _prefs.setString(_cacheTimestampKey, _lastCacheUpdate!.toIso8601String());
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
      
      AppLogger.info('💾 Wardrobe item saved', data: {
        'id': item.id,
        'type': item.analysis.itemType,
        'color': item.analysis.primaryColor,
      });
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to save wardrobe item', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get all wardrobe items (with caching)
  Future<List<WardrobeItem>> getWardrobeItems() async {
    // Return cached items if valid
    if (_isCacheValid() && _cachedItems != null) {
      AppLogger.debug('📦 Returning cached wardrobe items (${_cachedItems!.length} items)');
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
      final items = itemsJson.map((json) => WardrobeItem.fromJson(json)).toList();
      
      // Update cache
      _cachedItems = items;
      await _updateCacheTimestamp();
      
      AppLogger.debug('📦 Loaded ${items.length} wardrobe items from storage');
      return List.from(items);
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to load wardrobe items', error: e, stackTrace: stackTrace);
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
             item.analysis.subcategory?.toLowerCase().contains(queryLower) == true ||
             item.userNotes?.toLowerCase().contains(queryLower) == true ||
             item.tags.any((tag) => tag.toLowerCase().contains(queryLower)) ||
             item.occasions.any((occasion) => occasion.toLowerCase().contains(queryLower));
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
        if (!item.analysis.primaryColor.toLowerCase().contains(color.toLowerCase())) {
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
        final hasMatchingTag = tags.any((tag) => 
          item.tags.any((itemTag) => itemTag.toLowerCase().contains(tag.toLowerCase()))
        );
        if (!hasMatchingTag) return false;
      }
      
      return true;
    }).toList();
  }

  /// Update wardrobe item
  Future<void> updateWardrobeItem(WardrobeItem item) async {
    await saveWardrobeItem(item);
  }

  /// Delete wardrobe item
  Future<void> deleteWardrobeItem(String itemId) async {
    try {
      final items = await getWardrobeItems();
      items.removeWhere((i) => i.id == itemId);
      
      await _saveWardrobeItems(items);
      _invalidateCache();
      
      AppLogger.info('🗑️ Wardrobe item deleted', data: {'id': itemId});
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to delete wardrobe item', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Save list of wardrobe items
  Future<void> _saveWardrobeItems(List<WardrobeItem> items) async {
    final itemsJson = items.map((i) => i.toJson()).toList();
    await _prefs.setString(_wardrobeItemsKey, jsonEncode(itemsJson));
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
      
      AppLogger.info('💾 Wardrobe look saved', data: {'id': look.id, 'title': look.title});
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to save wardrobe look', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get all wardrobe looks (with caching)
  Future<List<WardrobeLook>> getWardrobeLooks() async {
    // Return cached looks if valid
    if (_isCacheValid() && _cachedLooks != null) {
      AppLogger.debug('📦 Returning cached wardrobe looks (${_cachedLooks!.length} looks)');
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
      final looks = looksJson.map((json) => WardrobeLook.fromJson(json)).toList();
      
      // Update cache
      _cachedLooks = looks;
      await _updateCacheTimestamp();
      
      AppLogger.debug('📦 Loaded ${looks.length} wardrobe looks from storage');
      return List.from(looks);
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to load wardrobe looks', error: e, stackTrace: stackTrace);
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
      AppLogger.error('❌ Failed to delete wardrobe look', error: e, stackTrace: stackTrace);
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
      AppLogger.error('❌ Failed to save user preferences', error: e, stackTrace: stackTrace);
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
      'wardrobeItems': (await getWardrobeItems()).map((i) => i.toJson()).toList(),
      'wardrobeLooks': (await getWardrobeLooks()).map((l) => l.toJson()).toList(),
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
