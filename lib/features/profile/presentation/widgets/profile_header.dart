import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vestiq/core/models/profile_data.dart';
import 'package:vestiq/core/services/profile_service.dart';
import 'package:vestiq/core/di/service_locator.dart';
import 'package:vestiq/core/utils/logger.dart';
import 'package:intl/intl.dart';

/// Premium profile header with avatar and editable name
class ProfileHeader extends StatefulWidget {
  final ProfileData profile;
  final VoidCallback onProfileUpdated;

  const ProfileHeader({
    super.key,
    required this.profile,
    required this.onProfileUpdated,
  });

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isEditingName = false;
  final _nameController = TextEditingController();
  final _profileService = getIt<ProfileService>();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.profile.userName;

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    HapticFeedback.mediumImpact();

    final picker = ImagePicker();
    final result = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;

    try {
      final pickedFile = await picker.pickImage(
        source: result,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        await _profileService.updateAvatarPath(pickedFile.path);
        widget.onProfileUpdated();
        AppLogger.info('📸 Avatar updated');
      }
    } catch (e) {
      AppLogger.error('❌ Error picking avatar', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update avatar')),
        );
      }
    }
  }

  Future<void> _saveName() async {
    if (_nameController.text.trim().isEmpty) return;

    await _profileService.updateUserName(_nameController.text.trim());
    setState(() => _isEditingName = false);
    widget.onProfileUpdated();
    HapticFeedback.lightImpact();
    AppLogger.info('✏️ Name updated: ${_nameController.text}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final joinedDateFormatted = DateFormat(
      'MMMM yyyy',
    ).format(widget.profile.joinedDate);

    return Column(
      children: [
        const SizedBox(height: 20),

        // Avatar
        GestureDetector(
          onTapDown: (_) => _scaleController.forward(),
          onTapUp: (_) {
            _scaleController.reverse();
            _pickAvatar();
          },
          onTapCancel: () => _scaleController.reverse(),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Avatar image
                  ClipOval(
                    child: widget.profile.avatarPath != null
                        ? Image.file(
                            File(widget.profile.avatarPath!),
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary.withValues(
                                    alpha: 0.7,
                                  ),
                                  theme.colorScheme.secondary.withValues(
                                    alpha: 0.7,
                                  ),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Icon(
                              Icons.person,
                              size: 60,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                  ),

                  // Edit badge
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Name (editable)
        if (_isEditingName)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: TextField(
              controller: _nameController,
              autofocus: true,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Enter your name',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _saveName,
                ),
              ),
              onSubmitted: (_) => _saveName(),
            ),
          )
        else
          GestureDetector(
            onTap: () {
              setState(() => _isEditingName = true);
              HapticFeedback.lightImpact();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.profile.userName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.edit,
                  size: 18,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),

        const SizedBox(height: 4),

        // Bio or joined date
        Text(
          widget.profile.userBio ?? 'Member since $joinedDateFormatted',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
