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
      appBar: AppBar(title: const Text('Add New Item'), elevation: 1),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildOptionButton(
              context: context,
              icon: Icons.camera_alt_outlined,
              label: 'Take a Photo',
              onPressed: () => _pickImage(context, ref, ImageSource.camera),
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 20),
            _buildOptionButton(
              context: context,
              icon: Icons.photo_library_outlined,
              label: 'Choose from Gallery',
              onPressed: () => _pickImage(context, ref, ImageSource.gallery),
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(height: 20),
            _buildOptionButton(
              context: context,
              icon: Icons.qr_code_scanner_outlined,
              label: 'Scan Clothing Tag (Soon)',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature coming soon!')),
                );
              },
              color: Colors.grey[600]!,
              isDimmed: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
    bool isDimmed = false,
  }) {
    return ElevatedButton.icon(
      icon: Icon(
        icon,
        size: 28,
        color: isDimmed ? Colors.white.withOpacity(0.7) : Colors.white,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isDimmed ? Colors.white.withOpacity(0.7) : Colors.white,
        ),
      ),
      onPressed: isDimmed ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDimmed ? color.withOpacity(0.5) : color,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: isDimmed ? 0 : 2,
      ),
    );
  }
}
