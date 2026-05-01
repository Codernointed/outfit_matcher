import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestiq/core/utils/logger.dart';
import 'package:vestiq/core/models/clothing_analysis.dart';

/// Cache service for mannequin images to avoid redundant API calls
class MannequinCacheService {
  static const String _cacheKeyPrefix = 'mannequin_cache_';
  static const Duration _cacheExpiry = Duration(days: 7);

  final SharedPreferences _prefs;

  MannequinCacheService(this._prefs);

  /// Generate cache key from item IDs
  String _generateCacheKey(List<String> itemIds) {
    final sortedIds = List<String>.from(itemIds)..sort();
    return '$_cacheKeyPrefix${sortedIds.join('_')}';
  }

  /// Check if cached mannequins exist and are valid
  Future<List<MannequinOutfit>?> getCachedMannequins(
    List<String> itemIds,
  ) async {
    try {
      final cacheKey = _generateCacheKey(itemIds);
      final cachedJson = _prefs.getString(cacheKey);

      if (cachedJson == null) {
        AppLogger.debug('🔍 No cache found for mannequins');
        return null;
      }

      final cacheData = jsonDecode(cachedJson) as Map<String, dynamic>;
      final timestamp = DateTime.parse(cacheData['timestamp'] as String);

      // Check if cache is expired
      if (DateTime.now().difference(timestamp) > _cacheExpiry) {
        AppLogger.debug('⏰ Cache expired for mannequins');
        await _prefs.remove(cacheKey);
        return null;
      }

      final outfitsJson = cacheData['outfits'] as List<dynamic>;
      final outfits = outfitsJson
          .map((json) => MannequinOutfit.fromJson(json as Map<String, dynamic>))
          .toList();

      // Guard against caching placeholder/failed generations (empty imageUrl).
      // If cache contains no usable images, treat as miss and clear it so the
      // app regenerates instead of showing placeholders indefinitely.
      final usable = outfits
          .where(
            (o) =>
                o.imageUrl.isNotEmpty &&
                (o.imageUrl.startsWith('data:') || o.imageUrl.startsWith('http')),
          )
          .toList();
      if (usable.isEmpty) {
        AppLogger.debug('🧹 Mannequin cache contained no usable images');
        await _prefs.remove(cacheKey);
        return null;
      }

      AppLogger.info(
        '✅ Cache hit for mannequins',
        data: {'count': usable.length},
      );
      return usable;
    } catch (e) {
      AppLogger.warning('⚠️ Failed to retrieve cached mannequins', error: e);
      return null;
    }
  }

  /// Cache mannequin outfits
  Future<void> cacheMannequins(
    List<String> itemIds,
    List<MannequinOutfit> outfits,
  ) async {
    try {
      final cacheKey = _generateCacheKey(itemIds);
      final usable = outfits
          .where(
            (o) =>
                o.imageUrl.isNotEmpty &&
                (o.imageUrl.startsWith('data:') || o.imageUrl.startsWith('http')),
          )
          .toList();
      if (usable.isEmpty) return;

      final cacheData = {
        'timestamp': DateTime.now().toIso8601String(),
        'outfits': usable.map((o) => o.toJson()).toList(),
      };

      await _prefs.setString(cacheKey, jsonEncode(cacheData));
      AppLogger.info('💾 Cached mannequins', data: {'count': usable.length});
    } catch (e) {
      AppLogger.warning('⚠️ Failed to cache mannequins', error: e);
    }
  }

  /// Clear all mannequin caches
  Future<void> clearAllCaches() async {
    try {
      final keys = _prefs.getKeys().where((k) => k.startsWith(_cacheKeyPrefix));
      for (final key in keys) {
        await _prefs.remove(key);
      }
      AppLogger.info('🗑️ Cleared all mannequin caches');
    } catch (e) {
      AppLogger.warning('⚠️ Failed to clear mannequin caches', error: e);
    }
  }

  /// Clear specific cache
  Future<void> clearCache(List<String> itemIds) async {
    try {
      final cacheKey = _generateCacheKey(itemIds);
      await _prefs.remove(cacheKey);
      AppLogger.debug('🗑️ Cleared cache for specific items');
    } catch (e) {
      AppLogger.warning('⚠️ Failed to clear specific cache', error: e);
    }
  }
}
