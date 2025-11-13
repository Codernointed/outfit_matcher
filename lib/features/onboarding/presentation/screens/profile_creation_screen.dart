import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vestiq/core/models/profile_data.dart';
import 'package:vestiq/core/services/profile_service.dart';
import 'package:vestiq/core/di/service_locator.dart';
import 'package:vestiq/core/utils/logger.dart';
import 'package:vestiq/features/auth/domain/services/user_profile_service.dart';
import 'package:vestiq/features/auth/domain/models/app_user.dart' as app_user;
import 'package:firebase_auth/firebase_auth.dart';

/// Beautiful multi-step profile creation flow for new users
/// Step 1: Name
/// Step 2: Gender preference (small, friendly UI)
/// Step 3: Full body photo for mannequin
class ProfileCreationScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const ProfileCreationScreen({super.key, required this.onComplete});

  @override
  ConsumerState<ProfileCreationScreen> createState() =>
      _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends ConsumerState<ProfileCreationScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();

  int _currentPage = 0;
  Gender? _selectedGender;
  File? _mannequinPhoto;
  bool _isProcessing = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _pickMannequinPhoto() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _mannequinPhoto = File(image.path));
        AppLogger.info('📸 Mannequin photo selected');
      }
    } catch (e) {
      AppLogger.error('❌ Error picking photo', error: e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to pick photo')));
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      final userProfileService = getIt<UserProfileService>();
      final profileService = getIt<ProfileService>();

      // Prepare profile data
      final Map<String, dynamic> profileData = {
        'username': _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : 'Fashion Enthusiast',
        'gender': _selectedGender?.name ?? Gender.female.name,
      };

      // TODO: Upload mannequin photo to Firebase Storage
      // For now, just save the data
      if (_mannequinPhoto != null) {
        AppLogger.info(
          '📸 Mannequin photo ready for upload: ${_mannequinPhoto!.path}',
        );
        // profileData['mannequinPhotoUrl'] = uploadedUrl;
      }

      // Create or update Firestore user profile
      final existing = await userProfileService.getUserProfile(currentUser.uid);
      if (existing == null) {
        AppLogger.info(
          '🆕 No existing profile found. Creating new user profile document...',
        );
        await userProfileService.createUserProfile(
          uid: currentUser.uid,
          email: currentUser.email ?? 'unknown@example.com',
          username: profileData['username'] as String,
          displayName: profileData['username'] as String,
          phoneNumber: currentUser.phoneNumber,
          gender: profileData['gender'] as String?,
          authProvider:
              app_user.AuthProvider.email, // TODO: derive from providerData
        );
        AppLogger.info('✅ Base user profile document created');
      } else {
        AppLogger.info(
          'ℹ️ Existing profile found. Updating user profile document...',
        );
        await userProfileService.updateUserProfile(
          currentUser.uid,
          profileData,
        );
      }

      // Save gender to local ProfileService
      await profileService.updateGenderPreference(
        _selectedGender ?? Gender.female,
      );

      AppLogger.info('✅ Profile created successfully');

      // Notify completion
      widget.onComplete();
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Error saving profile',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save profile: $e')));
      }
    }
  }

  bool _canContinue() {
    switch (_currentPage) {
      case 0: // Name page
        return _nameController.text.trim().isNotEmpty;
      case 1: // Gender page
        return _selectedGender != null;
      case 2: // Photo page
        return true; // Photo is optional
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with progress
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _isProcessing ? null : _previousPage,
                    ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index <= _currentPage
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surfaceContainerHighest,
                          ),
                        );
                      }),
                    ),
                  ),
                  // Spacer for symmetry
                  if (_currentPage > 0) const SizedBox(width: 48),
                ],
              ),
            ),

            // PageView
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                children: [
                  _buildNamePage(theme),
                  _buildGenderPage(theme),
                  _buildPhotoPage(theme),
                ],
              ),
            ),

            // Bottom button
            Padding(
              padding: const EdgeInsets.all(24),
              child: FilledButton(
                onPressed: _isProcessing || !_canContinue()
                    ? null
                    : () {
                        if (_currentPage == 2) {
                          _saveProfile();
                        } else {
                          _nextPage();
                        }
                      },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _currentPage == 2 ? 'Complete Profile' : 'Continue',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNamePage(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text('👋', style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 24),
          Text(
            'Let\'s get you started!',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'What shall we call you?',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 40),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Your Name',
              hintText: 'Enter your name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              filled: true,
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderPage(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Text('✨', style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 24),
          Text(
            'Choose your style',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'This helps us create mannequins that match you',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          // Simple, small gender selector
          Row(
            children: [
              Expanded(
                child: _buildGenderOption(
                  gender: Gender.male,
                  icon: Icons.man,
                  label: 'Male',
                  theme: theme,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGenderOption(
                  gender: Gender.female,
                  icon: Icons.woman,
                  label: 'Female',
                  theme: theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderOption({
    required Gender gender,
    required IconData icon,
    required String label,
    required ThemeData theme,
  }) {
    final isSelected = _selectedGender == gender;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        setState(() => _selectedGender = gender);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPage(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Text('📸', style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 24),
          Text(
            'One more thing!',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Upload a full-body photo for your personalized mannequin',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          // Photo picker
          GestureDetector(
            onTap: _pickMannequinPhoto,
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: _mannequinPhoto != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.file(_mannequinPhoto!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 64,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tap to upload photo',
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '(Optional - you can skip this)',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
