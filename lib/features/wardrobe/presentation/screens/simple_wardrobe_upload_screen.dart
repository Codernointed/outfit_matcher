import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vestiq/core/models/wardrobe_item.dart';
import 'package:vestiq/core/services/enhanced_wardrobe_storage_service.dart';
import 'package:vestiq/core/services/image_processing_service.dart';
import 'package:vestiq/core/services/app_settings_service.dart';
import 'package:vestiq/core/utils/gemini_api_service_new.dart';
import 'package:vestiq/core/utils/logger.dart';
import 'package:vestiq/core/di/service_locator.dart';
import 'package:vestiq/features/wardrobe/presentation/screens/enhanced_closet_screen.dart';

/// Simple upload screen for adding items to wardrobe (no outfit generation)
class SimpleWardrobeUploadScreen extends ConsumerStatefulWidget {
  const SimpleWardrobeUploadScreen({super.key});

  @override
  ConsumerState<SimpleWardrobeUploadScreen> createState() =>
      _SimpleWardrobeUploadScreenState();
}

class _SimpleWardrobeUploadScreenState
    extends ConsumerState<SimpleWardrobeUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  String _processingStatus = '';
  int _currentProgress = 0;
  int _totalToProcess = 0;

  // Upload tracking for cooldown
  static int _uploadCount = 0;
  static DateTime? _lastUploadBatch;
  static const int _maxPerBatch = 4;
  static const int _maxBeforeCooldown = 8;
  static const Duration _cooldownDuration = Duration(minutes: 2);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add to Wardrobe'),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                // color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Add to Your Closet',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload photos of your actual clothes to build your digital wardrobe',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Upload options
            if (!_isProcessing) ...[
              _buildUploadOption(
                context,
                icon: Icons.camera_alt,
                title: 'Take Photo',
                subtitle: 'Capture up to 4 items',
                onTap: () => _pickImages(ImageSource.camera),
              ),
              const SizedBox(height: 16),
              _buildUploadOption(
                context,
                icon: Icons.photo_library,
                title: 'Choose from Gallery',
                subtitle: 'Select up to 4 photos ($_uploadCount/8 uploaded)',
                onTap: () => _pickImages(ImageSource.gallery),
              ),
            ] else ...[
              // Processing state
              _buildProcessingState(theme),
            ],

            const Spacer(),

            // Info note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Items will be automatically enhanced and organized in your closet',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingState(ThemeData theme) {
    final progress = _totalToProcess > 0
        ? _currentProgress / _totalToProcess
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.2,
                  ),
                ),
                if (_totalToProcess > 1)
                  Text(
                    '$_currentProgress/$_totalToProcess',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _totalToProcess > 1
                ? 'Processing Your Items'
                : 'Processing Your Item',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _processingStatus,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          if (_totalToProcess > 1) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickImages(ImageSource source) async {
    try {
      // Check cooldown first
      if (_lastUploadBatch != null) {
        final timeSinceLastBatch = DateTime.now().difference(_lastUploadBatch!);
        if (_uploadCount >= _maxBeforeCooldown &&
            timeSinceLastBatch < _cooldownDuration) {
          final remainingSeconds =
              (_cooldownDuration - timeSinceLastBatch).inSeconds;
          final minutes = remainingSeconds ~/ 60;
          final seconds = remainingSeconds % 60;
          _showErrorSnackBar(
            'Upload limit reached. Please wait ${minutes}m ${seconds}s before uploading more items.',
          );
          return;
        } else if (timeSinceLastBatch >= _cooldownDuration) {
          // Reset counter after cooldown
          _uploadCount = 0;
          _lastUploadBatch = null;
        }
      }

      List<XFile> images = [];

      if (source == ImageSource.gallery) {
        // Gallery: Pick multiple images (max 4)
        final List<XFile> selectedImages = await _picker.pickMultiImage(
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );

        if (selectedImages.isEmpty) return;

        // Limit to 4 per batch
        if (selectedImages.length > _maxPerBatch) {
          _showErrorSnackBar(
            'You can only upload $_maxPerBatch images at once. Only first 4 will be processed.',
          );
          images = selectedImages.take(_maxPerBatch).toList();
        } else {
          images = selectedImages;
        }
      } else {
        // Camera: Take multiple photos (up to 4)
        images = await _captureMultiplePhotos();
        if (images.isEmpty) return;
      }

      // Process all images in parallel
      await _processMultipleImages(images);
    } catch (e) {
      AppLogger.error('❌ Failed to pick images', error: e);
      _showErrorSnackBar('Failed to select images. Please try again.');
    }
  }

  Future<List<XFile>> _captureMultiplePhotos() async {
    final List<XFile> capturedImages = [];

    for (int i = 0; i < _maxPerBatch; i++) {
      if (!mounted) break;
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Photo ${i + 1} of 4'),
          content: Text(
            i == 0
                ? 'Tap "Take Photo" to start capturing items'
                : 'You have $i photo(s). Take another or finish?',
          ),
          actions: [
            if (i > 0)
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Finish'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(i == 0 ? 'Take Photo' : 'Take Another'),
            ),
          ],
        ),
      );

      if (result != true) break;

      try {
        final XFile? photo = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );

        if (photo != null) {
          capturedImages.add(photo);
        } else {
          break;
        }
      } catch (e) {
        AppLogger.error('❌ Failed to capture photo', error: e);
        break;
      }
    }

    return capturedImages;
  }

  Future<void> _processMultipleImages(List<XFile> images) async {
    if (images.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _currentProgress = 0;
      _totalToProcess = images.length;
      _processingStatus =
          'Analyzing ${images.length} item${images.length > 1 ? "s" : ""}...';
    });

    try {
      final imageFiles = images.map((xfile) => File(xfile.path)).toList();

      // Process all images in parallel for speed
      AppLogger.info('📸 Processing ${images.length} images in parallel');

      final results = await Future.wait(
        imageFiles.asMap().entries.map((entry) async {
          final index = entry.key;
          final file = entry.value;

          try {
            // Step 1: Analyze
            final analysisResult =
                await GeminiApiService.analyzeClothingItemDetailed(file);

            if (analysisResult == null) {
              AppLogger.warning('⚠️ Analysis failed for image ${index + 1}');
              return null;
            }

            setState(() {
              _currentProgress = index + 1;
              _processingStatus =
                  'Analyzing $_currentProgress/$_totalToProcess...';
            });

            // Step 2: Process image
            final itemId =
                'wardrobe_${DateTime.now().millisecondsSinceEpoch}_$index';
            final settings = getIt<AppSettingsService>();
            final enablePolishing = settings.isPremiumPolishingEnabled;

            final imageResult =
                await ImageProcessingService.processUploadedImage(
                  imageFile: file,
                  itemId: itemId,
                  enablePolishing: enablePolishing,
                  itemType: analysisResult.itemType,
                  color: analysisResult.primaryColor,
                );

            // Step 3: Create wardrobe item
            final wardrobeItem = WardrobeItem.fromAnalysis(
              id: itemId,
              analysis: analysisResult,
              originalImagePath: imageResult.originalPath,
              polishedImagePath: imageResult.polishedPath,
            );

            return wardrobeItem;
          } catch (e) {
            AppLogger.error('❌ Failed to process image ${index + 1}', error: e);
            return null;
          }
        }),
      );

      // Filter out failed analyses
      final successfulItems = results.whereType<WardrobeItem>().toList();

      if (successfulItems.isEmpty) {
        throw Exception('Failed to analyze any items');
      }

      // Save all items
      setState(() {
        _processingStatus =
            'Saving ${successfulItems.length} item${successfulItems.length > 1 ? "s" : ""} to wardrobe...';
      });

      final storage = getIt<EnhancedWardrobeStorageService>();
      for (final item in successfulItems) {
        await storage.saveWardrobeItem(item);
      }

      // Update upload tracking
      _uploadCount += successfulItems.length;
      _lastUploadBatch = DateTime.now();

      AppLogger.info(
        '✅ Successfully saved ${successfulItems.length} items (Total: $_uploadCount/8)',
      );

      // Show cooldown warning if approaching limit
      if (_uploadCount >= _maxBeforeCooldown) {
        AppLogger.info('⚠️ Upload limit reached. Starting 2-minute cooldown.');
      }

      // Success! Go back to closet and refresh
      if (mounted) {
        // Force refresh all wardrobe providers
        ref.invalidate(wardrobeStorageProvider);
        ref.invalidate(wardrobeItemsProvider);
        ref.invalidate(filteredWardrobeItemsProvider);

        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${successfulItems.length} item${successfulItems.length > 1 ? "s" : ""} added to your wardrobe! '
              '($_uploadCount/8 uploads${_uploadCount >= _maxBeforeCooldown ? " - 2min cooldown active" : ""})',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to process wardrobe items',
        error: e,
        stackTrace: stackTrace,
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _processingStatus = '';
        });
        _showErrorSnackBar('Failed to process items. Please try again.');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
