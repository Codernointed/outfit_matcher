import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vestiq/core/utils/logger.dart';
import 'package:vestiq/features/wardrobe/presentation/screens/item_details_screen.dart';

class UploadOptionsScreen extends ConsumerStatefulWidget {
  const UploadOptionsScreen({super.key});

  @override
  ConsumerState<UploadOptionsScreen> createState() => _UploadOptionsScreenState();
}

class _UploadOptionsScreenState extends ConsumerState<UploadOptionsScreen> {
  bool _isLoading = false;
  final List<String> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _selectedImages.isEmpty ? 'Add to Generate Your Outfit' : '${_selectedImages.length} Selected',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () {
            if (_selectedImages.isNotEmpty) {
              setState(() => _selectedImages.clear());
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        actions: _selectedImages.isNotEmpty
            ? [
                TextButton(
                  onPressed: _navigateToItemDetails,
                  child: Text(
                    'Next',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ]
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeaderSection(context),
              
              const SizedBox(height: 16),
              
              // Selected Images Preview
              if (_selectedImages.isNotEmpty) ..._buildSelectedImagesPreview(theme),
              
              // Options
              Expanded(
                child: Column(
                  mainAxisAlignment: _selectedImages.isEmpty 
                      ? MainAxisAlignment.center 
                      : MainAxisAlignment.start,
                  children: [
                    _buildPremiumOptionCard(
                      context: context,
                      icon: Icons.camera_alt_rounded,
                      title: 'Take a Photo',
                      subtitle: 'Capture your clothing item with camera',
                      onPressed: _isLoading ? null : () => _pickImage(ImageSource.camera),
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withOpacity(0.8),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    _buildPremiumOptionCard(
                      context: context,
                      icon: Icons.photo_library_rounded,
                      title: 'Choose from Gallery',
                      subtitle: 'Select from your existing photos',
                      onPressed: _isLoading ? null : () => _pickImage(ImageSource.gallery),
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.shade400,
                          Colors.purple.shade600,
                        ],
                      ),
                    ),
                    
                    if (_selectedImages.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildNextButton(theme),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isLoading) return;
    
    AppLogger.info('📸 Starting image picker', data: {
      'source': source.toString(),
      'current_images': _selectedImages.length,
    });
    
    setState(() => _isLoading = true);
    
    try {
      List<XFile> images = [];
      
      if (source == ImageSource.camera) {
        AppLogger.debug('📷 Opening camera');
        // For camera, use single image picker with better error handling
        final XFile? image = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 85,
          preferredCameraDevice: CameraDevice.rear,
        );
        
        if (image != null) {
          AppLogger.info('✅ Camera image captured', data: {'path': image.path});
          images = [image];
        } else {
          AppLogger.info('📷 Camera capture cancelled by user');
        }
      } else {
        AppLogger.debug('🖼️ Opening gallery');
        // For gallery, allow multiple selection with better error handling
        try {
          images = await _picker.pickMultiImage(
            maxWidth: 1200,
            maxHeight: 1200,
            imageQuality: 85,
          );
          AppLogger.info('✅ Gallery images selected', data: {'count': images.length});
        } catch (galleryError) {
          AppLogger.warning('Gallery selection error, trying single image picker', error: galleryError);
          // Fallback to single image picker if multi-image fails
          final XFile? singleImage = await _picker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 1200,
            maxHeight: 1200,
            imageQuality: 85,
          );
          if (singleImage != null) {
            images = [singleImage];
            AppLogger.info('✅ Single gallery image selected as fallback');
          }
        }
      }

      if (images.isNotEmpty && mounted) {
        final imagePaths = images.map((e) => e.path).toList();
        AppLogger.info('📱 Adding images to selection', data: {
          'new_images': imagePaths.length,
          'total_after': _selectedImages.length + imagePaths.length,
        });
        
        setState(() {
          _selectedImages.addAll(imagePaths);
        });
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${images.length} image(s) added successfully'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else if (images.isEmpty) {
        AppLogger.info('📷 No images selected (user likely cancelled)');
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ Error in image picker', error: e, stackTrace: stackTrace);
      
      // Handle specific error types
      if (e.toString().contains('camera_access_denied') || 
          e.toString().contains('photo_access_denied')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera/Photo access denied. Please enable permissions in settings.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } else if (e.toString().contains('User cancelled') || 
                 e.toString().contains('cancelled')) {
        AppLogger.info('📷 Image picker cancelled by user');
        // User canceled - no error message needed
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accessing ${source == ImageSource.camera ? 'camera' : 'gallery'}: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        AppLogger.debug('📸 Image picker operation completed');
      }
    }
  }

  void _navigateToItemDetails() {
    if (_selectedImages.isEmpty) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ItemDetailsScreen(
          imagePaths: _selectedImages,
        ),
      ),
    );
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  
  Widget _buildHeaderSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _selectedImages.isEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add New Item',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start by taking a photo or choosing from your gallery',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            )
          : Text(
              'Add details for your items',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
    );
  }

  List<Widget> _buildSelectedImagesPreview(ThemeData theme) {
    return [
      SizedBox(
        height: 120,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _selectedImages.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(right: 12.0, bottom: 16.0),
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(_selectedImages[index]),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.error),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Tap on an image to remove it',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      const SizedBox(height: 16),
    ];
  }

  Widget _buildNextButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _navigateToItemDetails,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: const Text(
          'Continue to Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onPressed,
    required Gradient gradient,
    bool isDisabled = false,
  }) {
    final theme = Theme.of(context);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: _selectedImages.isNotEmpty ? 80 : 100,
      margin: _selectedImages.isNotEmpty 
          ? const EdgeInsets.only(bottom: 12) 
          : null,
      decoration: BoxDecoration(
        gradient: isDisabled ? null : gradient,
        color: isDisabled ? Colors.grey.shade200 : null,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDisabled ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isDisabled ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _selectedImages.isNotEmpty ? 48 : 60,
                  height: _selectedImages.isNotEmpty ? 48 : 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: _selectedImages.isNotEmpty ? 24 : 28,
                    color: isDisabled 
                        ? Colors.grey.shade600 
                        : Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: isDisabled 
                              ? Colors.grey.shade600 
                              : Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: _selectedImages.isNotEmpty ? 15 : 16,
                        ),
                      ),
                      if (_selectedImages.isEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDisabled 
                                ? Colors.grey.shade500 
                                : Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  _selectedImages.isEmpty 
                      ? Icons.arrow_forward_ios_rounded 
                      : Icons.add_rounded,
                  size: 16,
                  color: isDisabled 
                      ? Colors.grey.shade500 
                      : Colors.white.withOpacity(0.8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
