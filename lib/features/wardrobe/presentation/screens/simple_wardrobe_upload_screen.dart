import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:outfit_matcher/core/models/wardrobe_item.dart';
import 'package:outfit_matcher/core/services/enhanced_wardrobe_storage_service.dart';
import 'package:outfit_matcher/core/services/image_processing_service.dart';
import 'package:outfit_matcher/core/utils/gemini_api_service_new.dart';
import 'package:outfit_matcher/core/utils/logger.dart';
import 'package:outfit_matcher/core/di/service_locator.dart';

/// Simple upload screen for adding items to wardrobe (no outfit generation)
class SimpleWardrobeUploadScreen extends ConsumerStatefulWidget {
  const SimpleWardrobeUploadScreen({super.key});

  @override
  ConsumerState<SimpleWardrobeUploadScreen> createState() => _SimpleWardrobeUploadScreenState();
}

class _SimpleWardrobeUploadScreenState extends ConsumerState<SimpleWardrobeUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  String _processingStatus = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add to Wardrobe'),
        backgroundColor: Colors.transparent,
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
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
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
                      color: Colors.grey[600],
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
                subtitle: 'Capture with camera',
                onTap: () => _pickImage(ImageSource.camera),
              ),
              const SizedBox(height: 16),
              _buildUploadOption(
                context,
                icon: Icons.photo_library,
                title: 'Choose from Gallery',
                subtitle: 'Select existing photo',
                onTap: () => _pickImage(ImageSource.gallery),
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
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Items will be automatically enhanced and organized in your closet',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.blue[700],
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
    BuildContext context,
    {
      required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
    }
  ) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                  child: Icon(
                    icon,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
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
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
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
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Processing Your Item',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _processingStatus,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        await _processAndSaveImage(File(image.path));
      }
    } catch (e) {
      AppLogger.error('❌ Failed to pick image', error: e);
      _showErrorSnackBar('Failed to select image. Please try again.');
    }
  }

  Future<void> _processAndSaveImage(File imageFile) async {
    setState(() {
      _isProcessing = true;
      _processingStatus = 'Analyzing your item...';
    });

    try {
      // Step 1: Analyze the clothing item
      final analysisResult = await GeminiApiService.analyzeClothingItemDetailed(imageFile);
      
      if (analysisResult == null) {
        throw Exception('Failed to analyze clothing item');
      }
      
      setState(() {
        _processingStatus = 'Enhancing image quality...';
      });

      // Step 2: Process and enhance the image
      final itemId = 'wardrobe_${DateTime.now().millisecondsSinceEpoch}';
      final imageResult = await ImageProcessingService.processUploadedImage(
        imageFile: imageFile,
        itemId: itemId,
        enablePolishing: true, // Always polish for wardrobe items
        itemType: analysisResult.itemType,
        color: analysisResult.primaryColor,
      );

      setState(() {
        _processingStatus = 'Saving to your wardrobe...';
      });

      // Step 3: Create wardrobe item and save
      final wardrobeItem = WardrobeItem.fromAnalysis(
        id: itemId,
        analysis: analysisResult,
        originalImagePath: imageResult.originalPath,
        polishedImagePath: imageResult.polishedPath,
      );

      final storage = getIt<EnhancedWardrobeStorageService>();
      await storage.saveWardrobeItem(wardrobeItem);

      AppLogger.info('✅ Wardrobe item saved successfully', data: {
        'itemId': itemId,
        'type': analysisResult.itemType,
        'hasPolished': imageResult.polishedPath != null,
      });

      // Success! Go back to closet and refresh
      if (mounted) {
        // Invalidate providers to refresh the closet screen
        ref.invalidate(wardrobeItemsProvider);
        ref.invalidate(filteredWardrobeItemsProvider);
        
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${analysisResult.itemType} added to your wardrobe!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to process wardrobe item', error: e, stackTrace: stackTrace);
      
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _processingStatus = '';
        });
        _showErrorSnackBar('Failed to process item. Please try again.');
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
