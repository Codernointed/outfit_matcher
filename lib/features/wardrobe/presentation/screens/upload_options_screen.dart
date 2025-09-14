import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:outfit_matcher/core/di/service_locator.dart';
import 'package:outfit_matcher/core/utils/permission_handler_service.dart';
import 'package:permission_handler/permission_handler.dart';
// TODO: Import the actual image preview/processing screen once created
import 'package:outfit_matcher/features/wardrobe/presentation/screens/image_preview_screen.dart';

class UploadOptionsScreen extends ConsumerWidget {
  const UploadOptionsScreen({super.key});

  Future<void> _pickImage(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    final permissionService = getIt<PermissionHandlerService>();
    bool granted = false;
    String permissionName = '';
    String rationale = '';

    if (source == ImageSource.camera) {
      permissionName = 'Camera';
      rationale =
          'Outfit Matcher needs camera access to take photos of your clothing items.';
      granted = await permissionService.requestCameraPermission();
    } else {
      permissionName = 'Photo Library';
      rationale =
          'Outfit Matcher needs photo library access to upload your existing clothing photos.';
      granted = await permissionService.requestPhotosPermission();
    }

    if (!context.mounted) return;

    if (granted) {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);
      if (image != null && context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ImagePreviewScreen(imagePath: image.path),
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No image selected.')));
      }
    } else {
      // Check if permission was permanently denied
      final permissionStatusResult =
          source == ImageSource.camera
              ? await permissionService.getCameraPermissionStatus()
              : await permissionService.getPhotosPermissionStatus();

      if (permissionStatusResult == PermissionStatus.permanentlyDenied ||
          permissionStatusResult == PermissionStatus.denied) {
        permissionService.showPermissionDeniedDialog(
          context,
          permissionName,
          rationale,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$permissionName permission was not granted.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Add to Wardrobe',
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
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Header Section
              _buildHeaderSection(context),
              
              const SizedBox(height: 40),
              
              // Options
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPremiumOptionCard(
                      context: context,
                      icon: Icons.camera_alt_rounded,
                      title: 'Take a Photo',
                      subtitle: 'Capture your clothing item with camera',
                      onPressed: () => _pickImage(context, ref, ImageSource.camera),
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
                      onPressed: () => _pickImage(context, ref, ImageSource.gallery),
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.shade400,
                          Colors.purple.shade600,
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    _buildPremiumOptionCard(
                      context: context,
                      icon: Icons.qr_code_scanner_rounded,
                      title: 'Scan Clothing Tag',
                      subtitle: 'Coming soon - scan barcodes & tags',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Feature coming soon!'),
                            backgroundColor: theme.colorScheme.primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                      gradient: LinearGradient(
                        colors: [
                          Colors.grey.shade400,
                          Colors.grey.shade500,
                        ],
                      ),
                      isDisabled: true,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeaderSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How would you like to add your item?',
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose the best way to capture your clothing item',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
    required Gradient gradient,
    bool isDisabled = false,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      height: 100,
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
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
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
                        ),
                      ),
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
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
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
