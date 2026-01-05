import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:photo_manager/photo_manager.dart';

/// Service for saving images to device gallery
class GalleryService {
  /// Save a base64 image to gallery
  static Future<bool> saveBase64ImageToGallery(
    String base64Image,
    String fileName,
  ) async {
    try {
      if (kIsWeb) {
        throw UnsupportedError('Gallery saving not supported on web');
      }

      // Decode base64 string to bytes
      final imageBytes = base64Decode(base64Image);

      return await _saveImageToGallery(imageBytes, fileName);
    } catch (e) {
      AppLogger.info('❌ Error saving base64 image to gallery: $e');
      return false;
    }
  }

  /// Save a data URL image to gallery
  static Future<bool> saveDataUrlImageToGallery(
    String dataUrl,
    String fileName,
  ) async {
    try {
      if (kIsWeb) {
        throw UnsupportedError('Gallery saving not supported on web');
      }

      // Extract base64 data from data URL
      final base64Data = _extractBase64FromDataUrl(dataUrl);
      if (base64Data == null) {
        throw FormatException('Invalid data URL format');
      }

      return await saveBase64ImageToGallery(base64Data, fileName);
    } catch (e) {
      AppLogger.info('❌ Error saving data URL image to gallery: $e');
      return false;
    }
  }

  /// Save an image from URL to gallery
  static Future<bool> saveUrlImageToGallery(
    String imageUrl,
    String fileName,
  ) async {
    try {
      if (kIsWeb) {
        throw UnsupportedError('Gallery saving not supported on web');
      }

      // Download image from URL
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw HttpException('Failed to download image: ${response.statusCode}');
      }

      return await _saveImageToGallery(response.bodyBytes, fileName);
    } catch (e) {
      AppLogger.info('❌ Error saving URL image to gallery: $e');
      return false;
    }
  }

  /// Core method to save image bytes to gallery
  static Future<bool> _saveImageToGallery(
    Uint8List imageBytes,
    String fileName,
  ) async {
    try {
      if (kIsWeb) {
        throw UnsupportedError('Gallery saving not supported on web');
      }

      // Request permissions first
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      if (!ps.isAuth) {
        AppLogger.info('❌ Gallery permission denied');
        return false;
      }

      // Ensure file has proper extension
      final fileNameWithExt =
          fileName.endsWith('.png') || fileName.endsWith('.jpg')
          ? fileName
          : '$fileName.png';

      // Save to temporary file first
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(path.join(tempDir.path, fileNameWithExt));
      await tempFile.writeAsBytes(imageBytes);

      // Save to gallery using PhotoManager
      final AssetEntity entity = await PhotoManager.editor.saveImageWithPath(
        tempFile.path,
        title: fileNameWithExt,
      );

      // Clean up temp file
      await tempFile.delete();

      AppLogger.info('✅ Image saved to gallery: ${entity.id}');
      return true;
    } catch (e) {
      AppLogger.info('❌ Error saving image to gallery: $e');
      return false;
    }
  }

  /// Extract base64 data from data URL
  static String? _extractBase64FromDataUrl(String dataUrl) {
    try {
      // Handle data:image/png;base64, format
      if (dataUrl.contains('base64,')) {
        return dataUrl.split('base64,')[1];
      }
      // Handle plain base64
      return dataUrl;
    } catch (e) {
      AppLogger.info('❌ Error extracting base64 from data URL: $e');
      return null;
    }
  }

  /// Save multiple images to gallery with progress callback
  static Future<Map<String, bool>> saveMultipleImagesToGallery(
    List<String> imageData, // Can be base64, data URLs, or regular URLs
    List<String> fileNames, {
    void Function(int, int)? onProgress,
  }) async {
    final results = <String, bool>{};

    for (int i = 0; i < imageData.length; i++) {
      final image = imageData[i];
      final fileName = fileNames[i];

      onProgress?.call(i + 1, imageData.length);

      bool success = false;

      if (image.startsWith('data:')) {
        // Data URL
        success = await saveDataUrlImageToGallery(image, fileName);
      } else if (image.startsWith('http')) {
        // Regular URL
        success = await saveUrlImageToGallery(image, fileName);
      } else {
        // Assume base64
        success = await saveBase64ImageToGallery(image, fileName);
      }

      results[fileName] = success;

      // Small delay between saves
      if (i < imageData.length - 1) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

    return results;
  }

  /// Get gallery save directory path
  static Future<String?> getGalleryDirectory() async {
    try {
      if (kIsWeb) return null;

      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        final galleryPath = path.join(
          directory.path,
          'Pictures',
          'ManikinOutfits',
        );
        final galleryDir = Directory(galleryPath);

        if (!await galleryDir.exists()) {
          await galleryDir.create(recursive: true);
        }

        return galleryPath;
      }
      return null;
    } catch (e) {
      AppLogger.info('❌ Error getting gallery directory: $e');
      return null;
    }
  }

  /// Check if gallery directory exists and is accessible
  static Future<bool> checkGalleryAccess() async {
    try {
      if (kIsWeb) return false;

      final directory = await getExternalStorageDirectory();
      if (directory == null) return false;

      final galleryPath = path.join(
        directory.path,
        'Pictures',
        'ManikinOutfits',
      );
      final galleryDir = Directory(galleryPath);

      if (!await galleryDir.exists()) {
        await galleryDir.create(recursive: true);
      }

      // Test write access by creating a test file
      final testFile = File(path.join(galleryPath, 'test.tmp'));
      await testFile.writeAsString('test');
      await testFile.delete();

      return true;
    } catch (e) {
      AppLogger.info('❌ Gallery access check failed: $e');
      return false;
    }
  }
}
