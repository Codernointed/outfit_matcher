import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vestiq/core/di/service_locator.dart';
import 'package:vestiq/core/models/profile_data.dart';
import 'package:vestiq/core/services/profile_service.dart';
import 'package:vestiq/core/utils/logger.dart';
import 'package:vestiq/features/auth/domain/models/app_user.dart' as app_user;
import 'package:vestiq/features/auth/domain/services/user_profile_service.dart';

/// Beautiful multi-step profile creation flow for new users
/// Step 1: Name
/// Step 2: Gender preference (small, friendly UI)
/// Step 3: Style preferences (optional, quick chip selection)
/// Step 4: Full body photo for mannequin (optional)
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

  static const int _totalPages = 5;

  int _currentPage = 0;
  Gender? _selectedGender;
  String? _selectedBodyType;
  File? _mannequinPhoto;
  bool _isProcessing = false;

  // Style preferences
  final Set<String> _selectedStyles = {};
  final Set<String> _selectedOccasions = {};
  final Set<String> _selectedColors = {};

  // Available style options
  static const List<String> _styleOptions = [
    'Casual',
    'Formal',
    'Streetwear',
    'Minimalist',
    'Bohemian',
    'Sporty',
    'Vintage',
    'Classic',
    'Trendy',
    'Elegant',
  ];

  static const List<String> _occasionOptions = [
    'Work',
    'Weekend',
    'Date Night',
    'Workout',
    'Party',
    'Travel',
    'Business',
    'Lounge',
  ];

  static const List<String> _colorOptions = [
    'Black',
    'White',
    'Navy',
    'Beige',
    'Red',
    'Green',
    'Blue',
    'Pink',
    'Yellow',
    'Gray',
  ];

  static const Map<Gender, List<String>> _bodyTypeOptions = {
    Gender.female: [
      'Hourglass',
      'Pear',
      'Apple',
      'Rectangle',
      'Inverted Triangle',
    ],
    Gender.male: [
      'Inverted Triangle',
      'Trapezoid',
      'Rectangle',
      'Oval',
      'Triangle',
    ],
  };

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
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
        AppLogger.info('Mannequin photo selected');
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

      AppLogger.info('💾 Starting profile save for ${currentUser.uid}');

      final userProfileService = getIt<UserProfileService>();
      final profileService = getIt<ProfileService>();

      final username = _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : 'Fashion Enthusiast';
      final genderStr = _selectedGender?.name ?? Gender.female.name;

      AppLogger.info('👤 Profile data: username=$username, gender=$genderStr');

      if (_mannequinPhoto != null) {
        AppLogger.info(
          '📸 Mannequin photo ready for upload: ${_mannequinPhoto!.path}',
        );
      }

      // Style & Color preferences to save
      final stylesList = _selectedStyles.toList();
      final occasionsList = _selectedOccasions.toList();
      final colorsList = _selectedColors.toList();

      AppLogger.info(
        '🎨 Preferences: styles=$stylesList, occasions=$occasionsList, colors=$colorsList',
      );

      final existing = await userProfileService.getUserProfile(currentUser.uid);
      if (existing == null) {
        AppLogger.info(
          '🆕 No existing profile found. Creating new user profile document...',
        );
        await userProfileService.createUserProfile(
          uid: currentUser.uid,
          email: currentUser.email ?? 'unknown@example.com',
          username: username,
          displayName: username,
          phoneNumber: currentUser.phoneNumber,
          gender: genderStr,
          authProvider: _determineAuthProvider(currentUser),
        );
        AppLogger.info('✅ Base user profile document created');
      }

      // Update with advanced profile fields
      await userProfileService.updateUserProfile(currentUser.uid, {
        'username': username,
        'displayName': username,
        'gender': genderStr,
        'bodyType': _selectedBodyType,
        'preferredStyles': stylesList,
        'preferredOccasions': occasionsList,
        'preferredColors': colorsList,
      });
      AppLogger.info('✅ Profile fields updated in Firestore');

      AppLogger.info('💾 Saving gender to local profile service...');
      await profileService.updateGenderPreference(
        _selectedGender ?? Gender.female,
      );
      AppLogger.info('✅ Gender saved to local storage');

      AppLogger.info('🎉 Profile created successfully - calling onComplete');
      widget.onComplete();
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Error saving profile',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  bool _canContinue() {
    switch (_currentPage) {
      case 0:
        return _nameController.text.trim().isNotEmpty;
      case 1:
        return _selectedGender != null;
      case 2:
        return _selectedBodyType != null;
      case 3:
        return true; // Style preferences are optional
      case 4:
        return true; // Photo is optional
      default:
        return false;
    }
  }

  Widget _buildPhotoTips(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tips_and_updates_outlined,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Pro Tips for Best Results',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTipRow(
            'Stand in good lighting',
            Icons.wb_sunny_outlined,
            theme,
          ),
          const SizedBox(height: 8),
          _buildTipRow(
            'Wear form-fitting clothes',
            Icons.checkroom_outlined,
            theme,
          ),
          const SizedBox(height: 8),
          _buildTipRow(
            'Keep the background simple',
            Icons.wallpaper_outlined,
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildTipRow(String text, IconData icon, ThemeData theme) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  app_user.AuthProvider _determineAuthProvider(User user) {
    for (final info in user.providerData) {
      if (info.providerId == 'google.com') {
        return app_user.AuthProvider.google;
      } else if (info.providerId == 'apple.com') {
        return app_user.AuthProvider.apple;
      }
    }
    return app_user.AuthProvider.email;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      onPressed: _isProcessing ? null : _previousPage,
                    ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_totalPages, (index) {
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
                  if (_currentPage > 0) const SizedBox(width: 48),
                ],
              ),
            ),

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
                  _buildBodyTypePage(theme),
                  _buildStylePreferencesPage(theme),
                  _buildPhotoPage(theme),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: FilledButton(
                onPressed: _isProcessing || !_canContinue()
                    ? null
                    : () {
                        if (_currentPage == _totalPages - 1) {
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
                        _currentPage == _totalPages - 1
                            ? 'Complete Profile'
                            : 'Continue',
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
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 60),
          Center(child: Text('👋', style: const TextStyle(fontSize: 64))),
          const SizedBox(height: 32),
          Text(
            'Let\'s get you started!',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: primaryColor,
              letterSpacing: -0.5,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'What shall we call you?',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
              fontWeight: FontWeight.w400,
              fontFamily: 'Roboto',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          TextFormField(
            controller: _nameController,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'e.g. Fashionista',
              hintStyle: TextStyle(
                color: isDark ? Colors.white30 : Colors.grey.shade400,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(
                Icons.person_outline_rounded,
                color: primaryColor.withValues(alpha: 0.8),
              ),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.grey.shade200,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
            ),
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

  Widget _buildStylePreferencesPage(ThemeData theme) {
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Center(child: Text('🎨', style: const TextStyle(fontSize: 56))),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'What\'s your style?',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: primaryColor,
                letterSpacing: -0.5,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Select what describes you best (optional)',
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
                fontWeight: FontWeight.w400,
                fontFamily: 'Roboto',
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),

          // Style preferences
          Text(
            'Style Vibes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _styleOptions.map((style) {
              final isSelected = _selectedStyles.contains(style);
              return FilterChip(
                label: Text(style),
                selected: isSelected,
                onSelected: (selected) {
                  HapticFeedback.lightImpact();
                  setState(() {
                    if (selected) {
                      _selectedStyles.add(style);
                    } else {
                      _selectedStyles.remove(style);
                    }
                  });
                },
                selectedColor: primaryColor.withValues(alpha: 0.2),
                checkmarkColor: primaryColor,
                labelStyle: TextStyle(
                  color: isSelected
                      ? primaryColor
                      : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? primaryColor : Colors.transparent,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 28),

          // Occasion preferences
          Text(
            'Occasions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _occasionOptions.map((occasion) {
              final isSelected = _selectedOccasions.contains(occasion);
              return FilterChip(
                label: Text(occasion),
                selected: isSelected,
                onSelected: (selected) {
                  HapticFeedback.lightImpact();
                  setState(() {
                    if (selected) {
                      _selectedOccasions.add(occasion);
                    } else {
                      _selectedOccasions.remove(occasion);
                    }
                  });
                },
                selectedColor: primaryColor.withValues(alpha: 0.2),
                checkmarkColor: primaryColor,
                labelStyle: TextStyle(
                  color: isSelected
                      ? primaryColor
                      : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? primaryColor : Colors.transparent,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 28),

          // Color preferences
          Text(
            'Color Palette',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _colorOptions.map((color) {
              final isSelected = _selectedColors.contains(color);
              return FilterChip(
                label: Text(color),
                selected: isSelected,
                onSelected: (selected) {
                  HapticFeedback.lightImpact();
                  setState(() {
                    if (selected) {
                      _selectedColors.add(color);
                    } else {
                      _selectedColors.remove(color);
                    }
                  });
                },
                selectedColor: primaryColor.withValues(alpha: 0.2),
                checkmarkColor: primaryColor,
                labelStyle: TextStyle(
                  color: isSelected
                      ? primaryColor
                      : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? primaryColor : Colors.transparent,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Info tip
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: primaryColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This helps our AI suggest outfits that match your taste.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBodyTypePage(ThemeData theme) {
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final options = _bodyTypeOptions[_selectedGender ?? Gender.female]!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Center(
            child: Text(
              _selectedGender == Gender.male ? '🤵' : '👗',
              style: const TextStyle(fontSize: 56),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Your Body Shape',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: primaryColor,
                letterSpacing: -0.5,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Select the shape that best describes you',
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
                fontWeight: FontWeight.w400,
                fontFamily: 'Roboto',
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: options.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = _selectedBodyType == option;

              return InkWell(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  setState(() => _selectedBodyType = option);
                },
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor.withValues(alpha: 0.1)
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.shade50),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? primaryColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primaryColor
                              : theme.colorScheme.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.accessibility_new_rounded,
                          size: 20,
                          color: isSelected
                              ? Colors.white
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.4,
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        option,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? primaryColor
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      if (isSelected)
                        Icon(Icons.check_circle, color: primaryColor),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPhotoPage(ThemeData theme) {
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: constraints.maxHeight,
                maxWidth: 560,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    const Text('📸', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 16),
                    Text(
                      'One last thing...',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: primaryColor,
                        letterSpacing: -0.5,
                        fontFamily: 'Poppins',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add a full-body photo to personalize your mannequin.',
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Roboto',
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    GestureDetector(
                      onTap: _pickMannequinPhoto,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 280,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _mannequinPhoto != null
                              ? Colors.black
                              : (isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.grey.shade50),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: _mannequinPhoto != null
                                ? primaryColor
                                : (isDark
                                      ? Colors.white24
                                      : Colors.grey.shade300),
                            width: _mannequinPhoto != null ? 2.5 : 1.5,
                          ),
                          boxShadow: _mannequinPhoto != null
                              ? [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ]
                              : [],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: _mannequinPhoto != null
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.file(
                                      _mannequinPhoto!,
                                      fit: BoxFit.cover,
                                    ),
                                    Container(
                                      alignment: Alignment.bottomCenter,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withValues(alpha: 0.7),
                                          ],
                                        ),
                                      ),
                                      padding: const EdgeInsets.only(
                                        bottom: 16,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          Icon(
                                            Icons.camera_alt_outlined,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Change Photo',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withValues(
                                          alpha: 0.1,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.cloud_upload_outlined,
                                        size: 48,
                                        color: primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Upload a Photo',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: theme.colorScheme.onSurface,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Help AI visualize you',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark
                                            ? Colors.white60
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                    _buildPhotoTips(theme),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
