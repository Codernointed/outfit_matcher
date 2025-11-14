import 'package:vestiq/core/models/wardrobe_item.dart';
import 'package:vestiq/core/utils/logger.dart';

/// Cache service for compatibility scores to avoid redundant calculations
class CompatibilityCacheService {
  // In-memory cache for compatibility scores
  final Map<String, double> _compatibilityCache = {};

  /// Generate cache key for two items
  String _generateCacheKey(String itemId1, String itemId2) {
    // Sort IDs to ensure consistent keys regardless of order
    final ids = [itemId1, itemId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  /// Get cached compatibility score
  double? getCachedScore(String itemId1, String itemId2) {
    final key = _generateCacheKey(itemId1, itemId2);
    return _compatibilityCache[key];
  }

  /// Cache compatibility score
  void cacheScore(String itemId1, String itemId2, double score) {
    final key = _generateCacheKey(itemId1, itemId2);
    _compatibilityCache[key] = score;
  }

  /// Pre-compute compatibility matrix for all items
  Future<void> precomputeCompatibilityMatrix(List<WardrobeItem> items) async {
    final startTime = DateTime.now();
    int computedCount = 0;

    AppLogger.info(
      '🔄 Pre-computing compatibility matrix',
      data: {'items': items.length},
    );

    for (int i = 0; i < items.length; i++) {
      for (int j = i + 1; j < items.length; j++) {
        final key = _generateCacheKey(items[i].id, items[j].id);

        // Only compute if not already cached
        if (!_compatibilityCache.containsKey(key)) {
          final score = items[i].getCompatibilityScore(items[j]);
          _compatibilityCache[key] = score;
          computedCount++;
        }
      }
    }

    final duration = DateTime.now().difference(startTime);
    AppLogger.performance(
      'Compatibility matrix computation',
      duration,
      result: 'success',
    );
    AppLogger.info(
      '✅ Compatibility matrix computed',
      data: {
        'computed': computedCount,
        'cached_total': _compatibilityCache.length,
        'duration_ms': duration.inMilliseconds,
      },
    );
  }

  /// Get compatibility score with caching
  double getCompatibilityScore(WardrobeItem item1, WardrobeItem item2) {
    final cached = getCachedScore(item1.id, item2.id);
    if (cached != null) {
      return cached;
    }

    // Compute and cache
    final score = item1.getCompatibilityScore(item2);
    cacheScore(item1.id, item2.id, score);
    return score;
  }

  /// Clear all cached scores
  void clearCache() {
    _compatibilityCache.clear();
    AppLogger.debug('🗑️ Cleared compatibility cache');
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cached_pairs': _compatibilityCache.length,
      'memory_estimate_kb':
          (_compatibilityCache.length * 16) / 1024, // Rough estimate
    };
  }
}
