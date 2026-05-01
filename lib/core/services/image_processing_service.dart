import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:vestiq/core/utils/ai_orchestrator.dart';
import 'package:vestiq/core/utils/logger.dart';

/// Service for processing and enhancing clothing item images
class ImageProcessingService {
  static const String _imagesDir = 'wardrobe_images';
  static const String _originalSubdir = 'original';
  static const String _polishedSubdir = 'polished';
  static const String _thumbnailSubdir = 'thumbnails';

  /// Process uploaded image with optional polishing
  static Future<ImageProcessingResult> processUploadedImage({
    required File imageFile,
    required String itemId,
    bool enablePolishing = false,
    String? itemType,
    String? color,
  }) async {
    AppLogger.info(
      '🖼️ Processing uploaded image',
      data: {
        'itemId': itemId,
        'enablePolishing': enablePolishing,
        'itemType': itemType,
        'color': color,
      },
    );

    try {
      // Save original image
      final originalPath = await _saveOriginalImage(imageFile, itemId);
      AppLogger.info('💾 Original image saved', data: {'path': originalPath});

      // Create thumbnail
      await _createThumbnail(File(originalPath), itemId);
      AppLogger.info('🖼️ Thumbnail created');

      String? polishedPath;
      if (enablePolishing) {
        AppLogger.info('✨ Starting image polishing');
        polishedPath = await _polishImage(
          File(originalPath),
          itemId,
          itemType: itemType ?? 'clothing',
          color: color ?? 'unknown',
        );
        if (polishedPath != null) {
          AppLogger.info(
            '✅ Image polished and saved',
            data: {'path': polishedPath},
          );
        }
      }

      AppLogger.info('✨ Image polished successfully');
      AppLogger.info('✅ Image processing complete');

      return ImageProcessingResult(
        originalPath: originalPath,
        polishedPath: polishedPath,
        thumbnailPath: await _createThumbnail(File(originalPath), itemId),
        processingTime: DateTime.now(),
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Image processing failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Polish image via the AI orchestrator (races Gemini + OpenRouter).
  /// Returns the saved file path of the polished image, or null on failure.
  static Future<String?> _polishImage(
    File imageFile,
    String itemId, {
    required String itemType,
    required String color,
  }) async {
    AppLogger.info(
      '✨ Starting image polishing',
      data: {'itemId': itemId, 'itemType': itemType, 'color': color},
    );

    try {
      final polishedBase64 = await AiOrchestrator.polishImage(
        imageFile: imageFile,
        itemType: itemType,
        color: color,
      );

      if (polishedBase64 == null) {
        AppLogger.warning('⚠️ All polish providers failed');
        return null;
      }

      final polishedPath = await _savePolishedImage(polishedBase64, itemId);
      AppLogger.info(
        '✅ Image polished and saved',
        data: {'path': polishedPath},
      );
      return polishedPath;
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Image polishing failed',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Save original image to storage
  static Future<String> _saveOriginalImage(
    File imageFile,
    String itemId,
  ) async {
    final directory = await _getImagesDirectory();
    final originalDir = Directory('${directory.path}/$_originalSubdir');
    await originalDir.create(recursive: true);

    final fileName = '${itemId}_original.jpg';
    final targetPath = '${originalDir.path}/$fileName';

    await imageFile.copy(targetPath);
    return targetPath;
  }

  /// Create and save thumbnail
  static Future<String> _createThumbnail(File imageFile, String itemId) async {
    final directory = await _getImagesDirectory();
    final thumbnailDir = Directory('${directory.path}/$_thumbnailSubdir');
    await thumbnailDir.create(recursive: true);

    // For now, just copy the original as thumbnail
    // In production, you'd want to resize using image package
    final fileName = '${itemId}_thumb.jpg';
    final targetPath = '${thumbnailDir.path}/$fileName';

    await imageFile.copy(targetPath);
    return targetPath;
  }

  /// Save polished image from base64 data
  static Future<String> _savePolishedImage(
    String base64Data,
    String itemId,
  ) async {
    final directory = await _getImagesDirectory();
    final polishedDir = Directory('${directory.path}/$_polishedSubdir');
    await polishedDir.create(recursive: true);

    final fileName = '${itemId}_polished.jpg';
    final targetPath = '${polishedDir.path}/$fileName';

    // Decode and save
    final bytes = base64Decode(base64Data);
    final file = File(targetPath);
    await file.writeAsBytes(bytes);

    return targetPath;
  }

  /// Get or create images directory
  static Future<Directory> _getImagesDirectory() async {
    if (kIsWeb) {
      throw UnsupportedError('File storage not supported on web');
    }

    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${appDir.path}/$_imagesDir');

    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    return imagesDir;
  }

  /// Clean up old images (for maintenance)
  static Future<void> cleanupOldImages({int maxAgeInDays = 30}) async {
    AppLogger.info(
      '🧹 Starting image cleanup',
      data: {'maxAgeInDays': maxAgeInDays},
    );

    try {
      final directory = await _getImagesDirectory();
      final cutoffDate = DateTime.now().subtract(Duration(days: maxAgeInDays));

      int deletedCount = 0;
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await entity.delete();
            deletedCount++;
          }
        }
      }

      AppLogger.info(
        '✅ Image cleanup complete',
        data: {'deletedFiles': deletedCount},
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Image cleanup failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get storage usage statistics
  static Future<StorageStats> getStorageStats() async {
    try {
      final directory = await _getImagesDirectory();

      int totalFiles = 0;
      int totalSize = 0;
      int originalCount = 0;
      int polishedCount = 0;
      int thumbnailCount = 0;

      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          totalFiles++;
          totalSize += await entity.length();

          if (entity.path.contains(_originalSubdir)) originalCount++;
          if (entity.path.contains(_polishedSubdir)) polishedCount++;
          if (entity.path.contains(_thumbnailSubdir)) thumbnailCount++;
        }
      }

      return StorageStats(
        totalFiles: totalFiles,
        totalSizeBytes: totalSize,
        originalCount: originalCount,
        polishedCount: polishedCount,
        thumbnailCount: thumbnailCount,
      );
    } catch (e) {
      AppLogger.error('❌ Failed to get storage stats', error: e);
      return StorageStats.empty();
    }
  }
}

/// Result of image processing operation
class ImageProcessingResult {
  final String originalPath;
  final String thumbnailPath;
  final String? polishedPath;
  final DateTime processingTime;

  const ImageProcessingResult({
    required this.originalPath,
    required this.thumbnailPath,
    this.polishedPath,
    required this.processingTime,
  });

  /// Get the best available image path (polished > original)
  String get bestImagePath => polishedPath ?? originalPath;

  /// Get display image path (polished if available, otherwise original)
  String get displayImagePath => polishedPath ?? originalPath;

  Map<String, dynamic> toJson() {
    return {
      'originalPath': originalPath,
      'thumbnailPath': thumbnailPath,
      'polishedPath': polishedPath,
      'processingTime': processingTime.toIso8601String(),
    };
  }

  factory ImageProcessingResult.fromJson(Map<String, dynamic> json) {
    return ImageProcessingResult(
      originalPath: json['originalPath'] as String,
      thumbnailPath: json['thumbnailPath'] as String,
      polishedPath: json['polishedPath'] as String?,
      processingTime: DateTime.parse(json['processingTime'] as String),
    );
  }
}

/// Storage usage statistics
class StorageStats {
  final int totalFiles;
  final int totalSizeBytes;
  final int originalCount;
  final int polishedCount;
  final int thumbnailCount;

  const StorageStats({
    required this.totalFiles,
    required this.totalSizeBytes,
    required this.originalCount,
    required this.polishedCount,
    required this.thumbnailCount,
  });

  factory StorageStats.empty() {
    return const StorageStats(
      totalFiles: 0,
      totalSizeBytes: 0,
      originalCount: 0,
      polishedCount: 0,
      thumbnailCount: 0,
    );
  }

  double get totalSizeMB => totalSizeBytes / (1024 * 1024);

  Map<String, dynamic> toJson() {
    return {
      'totalFiles': totalFiles,
      'totalSizeBytes': totalSizeBytes,
      'originalCount': originalCount,
      'polishedCount': polishedCount,
      'thumbnailCount': thumbnailCount,
    };
  }
}
