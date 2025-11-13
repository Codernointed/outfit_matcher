import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class StorageInfo {
  final double cacheSize; // MB
  final double documentsSize; // MB
  final double totalSize; // MB
  final Map<String, double> breakdown; // Category -> Size in MB

  StorageInfo({
    required this.cacheSize,
    required this.documentsSize,
    required this.totalSize,
    required this.breakdown,
  });

  String get formattedTotal => '${totalSize.toStringAsFixed(2)} MB';
  String get formattedCache => '${cacheSize.toStringAsFixed(2)} MB';
  String get formattedDocuments => '${documentsSize.toStringAsFixed(2)} MB';
}

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  /// Calculate total storage used by the app
  Future<StorageInfo> calculateStorage() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final docDir = await getApplicationDocumentsDirectory();

      final cacheSize = await _calculateDirectorySize(cacheDir);
      final documentsSize = await _calculateDirectorySize(docDir);

      // Breakdown by category (you can customize this based on your app structure)
      final breakdown = <String, double>{
        'Cache': cacheSize,
        'Images': await _calculateSubdirectorySize(docDir, 'images'),
        'Database': await _calculateSubdirectorySize(docDir, 'databases'),
        'Other Documents':
            documentsSize -
            await _calculateSubdirectorySize(docDir, 'images') -
            await _calculateSubdirectorySize(docDir, 'databases'),
      };

      return StorageInfo(
        cacheSize: cacheSize,
        documentsSize: documentsSize,
        totalSize: cacheSize + documentsSize,
        breakdown: breakdown,
      );
    } catch (e) {
      debugPrint('❌ Error calculating storage: $e');
      return StorageInfo(
        cacheSize: 0,
        documentsSize: 0,
        totalSize: 0,
        breakdown: {},
      );
    }
  }

  /// Clear app cache
  Future<double> clearCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final sizeBefore = await _calculateDirectorySize(cacheDir);

      if (cacheDir.existsSync()) {
        await _deleteDirectory(cacheDir);
        // Recreate the cache directory
        await cacheDir.create(recursive: true);
      }

      debugPrint('✅ Cache cleared: ${sizeBefore.toStringAsFixed(2)} MB');
      return sizeBefore;
    } catch (e) {
      debugPrint('❌ Error clearing cache: $e');
      return 0;
    }
  }

  /// Calculate size of a directory in MB
  Future<double> _calculateDirectorySize(Directory directory) async {
    try {
      if (!directory.existsSync()) return 0;

      int totalSize = 0;
      await for (var entity in directory.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) {
          try {
            totalSize += await entity.length();
          } catch (e) {
            // Skip files that can't be accessed
            debugPrint('⚠️ Could not access file: ${entity.path}');
          }
        }
      }

      // Convert bytes to MB
      return totalSize / (1024 * 1024);
    } catch (e) {
      debugPrint('❌ Error calculating directory size: $e');
      return 0;
    }
  }

  /// Calculate size of a subdirectory
  Future<double> _calculateSubdirectorySize(
    Directory parentDir,
    String subdirName,
  ) async {
    try {
      final subdir = Directory('${parentDir.path}/$subdirName');
      if (!subdir.existsSync()) return 0;
      return await _calculateDirectorySize(subdir);
    } catch (e) {
      debugPrint('❌ Error calculating subdirectory size: $e');
      return 0;
    }
  }

  /// Delete directory contents recursively
  Future<void> _deleteDirectory(Directory directory) async {
    if (!directory.existsSync()) return;

    await for (var entity in directory.list(
      recursive: false,
      followLinks: false,
    )) {
      try {
        if (entity is Directory) {
          await entity.delete(recursive: true);
        } else if (entity is File) {
          await entity.delete();
        }
      } catch (e) {
        debugPrint('⚠️ Could not delete: ${entity.path}');
      }
    }
  }

  /// Get formatted storage breakdown as a string
  String formatStorageBreakdown(StorageInfo info) {
    final buffer = StringBuffer();
    buffer.writeln('Total: ${info.formattedTotal}');
    buffer.writeln('');

    info.breakdown.forEach((category, size) {
      if (size > 0) {
        buffer.writeln('$category: ${size.toStringAsFixed(2)} MB');
      }
    });

    return buffer.toString().trim();
  }
}
