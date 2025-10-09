import 'dart:async';
import 'dart:io';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:vestiq/core/utils/logger.dart';

/// Service for managing image cache and preventing memory leaks
class ImageCacheManager {
  static ImageCacheManager? _instance;
  static const int _maxCacheSize = 50; // Maximum number of cached images
  static const Duration _cacheCleanupInterval = Duration(minutes: 10);

  final Queue<String> _cacheOrder = Queue<String>();
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, ImageProvider> _cachedImages = {};

  // Singleton pattern
  static ImageCacheManager get instance {
    _instance ??= ImageCacheManager._();
    return _instance!;
  }

  ImageCacheManager._() {
    _startPeriodicCleanup();
  }

  /// Get an image provider with automatic caching
  Future<ImageProvider?> getImageProvider(String imagePath) async {
    try {
      // Check if we have a cached version
      if (_cachedImages.containsKey(imagePath)) {
        _updateCacheOrder(imagePath);
        return _cachedImages[imagePath];
      }

      // Check if file exists with timeout
      final file = File(imagePath);
      if (!await file.exists()) {
        AppLogger.warning('❌ Image file does not exist: $imagePath');
        return null;
      }

      // Create new image provider with timeout for loading
      final provider = FileImage(file);

      // Preload the image to catch any issues early with timeout
      await _preloadImage(provider).timeout(const Duration(seconds: 10));

      // Add to cache
      _addToCache(imagePath, provider);

      AppLogger.debug('✅ Image cached: $imagePath');
      return provider;
    } catch (e) {
      AppLogger.error('❌ Error getting image provider', error: e);
      return null;
    }
  }

  /// Preload image to catch issues early and ensure it's valid
  Future<void> _preloadImage(ImageProvider provider) async {
    final ImageStream stream = provider.resolve(ImageConfiguration.empty);
    final Completer<void> completer = Completer<void>();

    stream.addListener(
      ImageStreamListener(
        (ImageInfo image, bool synchronousCall) {
          completer.complete();
        },
        onError: (Object exception, StackTrace? stackTrace) {
          completer.completeError(exception, stackTrace);
        },
      ),
    );

    return completer.future;
  }

  /// Add image to cache with LRU eviction
  void _addToCache(String imagePath, ImageProvider provider) {
    // Remove from cache if already exists (shouldn't happen)
    if (_cachedImages.containsKey(imagePath)) {
      _cachedImages.remove(imagePath);
      _cacheOrder.remove(imagePath);
      _cacheTimestamps.remove(imagePath);
    }

    // Check if we need to evict old entries
    if (_cachedImages.length >= _maxCacheSize) {
      _evictOldest();
    }

    // Add new entry
    _cachedImages[imagePath] = provider;
    _cacheOrder.add(imagePath);
    _cacheTimestamps[imagePath] = DateTime.now();

    AppLogger.debug(
      '📸 Added to cache: $imagePath (cache size: ${_cachedImages.length})',
    );
  }

  /// Update cache order for LRU
  void _updateCacheOrder(String imagePath) {
    if (_cacheOrder.contains(imagePath)) {
      _cacheOrder.remove(imagePath);
      _cacheOrder.add(imagePath);
      _cacheTimestamps[imagePath] = DateTime.now();
    }
  }

  /// Remove oldest cached image
  void _evictOldest() {
    if (_cacheOrder.isEmpty) return;

    final oldestPath = _cacheOrder.removeFirst();
    final provider = _cachedImages.remove(oldestPath);
    _cacheTimestamps.remove(oldestPath);

    // Dispose of the provider to free memory
    if (provider != null) {
      provider.evict();
    }

    AppLogger.debug('🗑️ Evicted from cache: $oldestPath');
  }

  /// Manually remove specific image from cache
  void removeFromCache(String imagePath) {
    if (_cachedImages.containsKey(imagePath)) {
      final provider = _cachedImages.remove(imagePath);
      _cacheOrder.remove(imagePath);
      _cacheTimestamps.remove(imagePath);

      provider?.evict();

      AppLogger.debug('🗑️ Manually removed from cache: $imagePath');
    }
  }

  /// Clear all cached images
  void clearCache() {
    for (final provider in _cachedImages.values) {
      provider.evict();
    }

    _cachedImages.clear();
    _cacheOrder.clear();
    _cacheTimestamps.clear();

    AppLogger.info('🧹 Cache cleared completely');
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cached_images': _cachedImages.length,
      'max_cache_size': _maxCacheSize,
      'oldest_timestamp': _cacheTimestamps.values.isNotEmpty
          ? _cacheTimestamps.values.reduce((a, b) => a.isBefore(b) ? a : b)
          : null,
      'newest_timestamp': _cacheTimestamps.values.isNotEmpty
          ? _cacheTimestamps.values.reduce((a, b) => a.isAfter(b) ? a : b)
          : null,
    };
  }

  /// Periodic cleanup to remove stale cached images
  void _startPeriodicCleanup() {
    // Run cleanup every 10 minutes
    Future.doWhile(() async {
      await Future.delayed(_cacheCleanupInterval);
      _cleanupStaleImages();
      return true; // Continue the loop
    });
  }

  /// Remove images that haven't been accessed recently
  void _cleanupStaleImages() {
    final now = DateTime.now();
    final staleThreshold = Duration(minutes: 30);

    final staleKeys = _cacheTimestamps.entries
        .where((entry) => now.difference(entry.value) > staleThreshold)
        .map((entry) => entry.key)
        .toList();

    for (final key in staleKeys) {
      removeFromCache(key);
    }

    if (staleKeys.isNotEmpty) {
      AppLogger.info('🧹 Cleaned up ${staleKeys.length} stale cached images');
    }
  }

  /// Clean up resources when app is disposed
  void dispose() {
    clearCache();
    AppLogger.info('🗑️ ImageCacheManager disposed');
  }
}
