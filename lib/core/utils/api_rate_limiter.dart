import 'dart:async';
import 'dart:collection';
import 'package:vestiq/core/utils/logger.dart';

/// Service for managing API rate limiting and caching
class ApiRateLimiter {
  static ApiRateLimiter? _instance;

  // Rate limiting configuration
  static const int _maxRequestsPerMinute = 10;
  static const Duration _rateLimitWindow = Duration(minutes: 1);

  // Cache configuration
  static const Duration _cacheTtl = Duration(hours: 1);

  // Request tracking
  final Queue<DateTime> _requestTimes = Queue<DateTime>();

  // Response cache
  final Map<String, _CacheEntry> _cache = {};

  // Singleton pattern
  static ApiRateLimiter get instance {
    _instance ??= ApiRateLimiter._();
    return _instance!;
  }

  ApiRateLimiter._() {
    _startCacheCleanup();
  }

  /// Check if request is allowed under rate limits
  Future<bool> isRequestAllowed() async {
    final now = DateTime.now();

    // Remove old requests outside the window
    while (_requestTimes.isNotEmpty &&
        now.difference(_requestTimes.first) > _rateLimitWindow) {
      _requestTimes.removeFirst();
    }

    // Check if we're under the limit
    if (_requestTimes.length >= _maxRequestsPerMinute) {
      AppLogger.warning(
        '🚦 API rate limit reached ($_maxRequestsPerMinute requests/minute)',
      );
      return false;
    }

    // Record this request
    _requestTimes.add(now);
    AppLogger.debug('✅ API request allowed (${_requestTimes.length}/$_maxRequestsPerMinute)');
    return true;
  }

  /// Get cached response if available and valid
  String? getCachedResponse(String cacheKey) {
    final entry = _cache[cacheKey];
    if (entry == null) return null;

    if (DateTime.now().difference(entry.timestamp) > _cacheTtl) {
      _cache.remove(cacheKey);
      AppLogger.debug('🗑️ Cache expired for key: $cacheKey');
      return null;
    }

    AppLogger.debug('📦 Cache hit for key: $cacheKey');
    return entry.response;
  }

  /// Cache a response
  void cacheResponse(String cacheKey, String response) {
    _cache[cacheKey] = _CacheEntry(
      response: response,
      timestamp: DateTime.now(),
    );

    AppLogger.debug('💾 Cached response for key: $cacheKey');
  }

  /// Generate cache key for request
  String generateCacheKey({
    required String endpoint,
    required Map<String, dynamic>? requestBody,
    String? imageHash,
  }) {
    final key = StringBuffer();
    key.write(endpoint);

    if (requestBody != null) {
      // Sort keys for consistent hashing
      final sortedKeys = requestBody.keys.toList()..sort();
      for (final k in sortedKeys) {
        key.write('_$k=${requestBody[k]}');
      }
    }

    if (imageHash != null) {
      key.write('_img=$imageHash');
    }

    return key.toString().hashCode.toString();
  }

  /// Clear all cached responses
  void clearCache() {
    _cache.clear();
    AppLogger.info('🧹 API cache cleared');
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final now = DateTime.now();
    final validEntries = _cache.values.where(
      (entry) => now.difference(entry.timestamp) <= _cacheTtl,
    );

    return {
      'cached_responses': validEntries.length,
      'total_cache_size': _cache.length,
      'rate_limit_window_requests': _requestTimes.length,
      'max_requests_per_minute': _maxRequestsPerMinute,
    };
  }

  /// Periodic cleanup of expired cache entries
  void _startCacheCleanup() {
    Timer.periodic(const Duration(minutes: 5), (timer) {
      final now = DateTime.now();
      final expiredKeys = _cache.entries
          .where((entry) => now.difference(entry.value.timestamp) > _cacheTtl)
          .map((entry) => entry.key)
          .toList();

      for (final key in expiredKeys) {
        _cache.remove(key);
      }

      if (expiredKeys.isNotEmpty) {
        AppLogger.info('🧹 Cleaned up ${expiredKeys.length} expired cache entries');
      }
    });
  }

  /// Wait for rate limit reset if needed
  Future<void> waitForRateLimitReset() async {
    if (_requestTimes.isEmpty) return;

    final oldestRequest = _requestTimes.first;
    final timeSinceOldest = DateTime.now().difference(oldestRequest);
    final timeToWait = _rateLimitWindow - timeSinceOldest;

    if (timeToWait > Duration.zero) {
      AppLogger.info('⏳ Waiting ${timeToWait.inSeconds}s for rate limit reset');
      await Future.delayed(timeToWait);
    }
  }
}

/// Cache entry for API responses
class _CacheEntry {
  final String response;
  final DateTime timestamp;

  const _CacheEntry({
    required this.response,
    required this.timestamp,
  });
}
