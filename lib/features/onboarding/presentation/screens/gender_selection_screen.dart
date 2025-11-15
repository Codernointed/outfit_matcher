import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vestiq/core/models/profile_data.dart';
import 'package:vestiq/core/services/profile_service.dart';
import 'package:vestiq/core/di/service_locator.dart';
import 'package:vestiq/core/utils/logger.dart';
import 'package:vestiq/features/auth/domain/services/user_profile_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Premium gender selection screen for onboarding
class GenderSelectionScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const GenderSelectionScreen({super.key, required this.onComplete});

  @override
  ConsumerState<GenderSelectionScreen> createState() =>
      _GenderSelectionScreenState();
}

class _GenderSelectionScreenState extends ConsumerState<GenderSelectionScreen>
    with SingleTickerProviderStateMixin {
  Gender? _selectedGender;
  late AnimationController _scaleController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    AppLogger.info('🎨 Gender Selection Screen initialized');
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _selectGender(Gender gender) async {
    AppLogger.info('👤 User tapped gender: ${gender.displayName}');
    HapticFeedback.mediumImpact();

    setState(() => _selectedGender = gender);
    _scaleController.forward().then((_) => _scaleController.reverse());

    try {
      // Save to profile
      final profileService = getIt<ProfileService>();
      await profileService.updateGenderPreference(gender);
      AppLogger.info('✅ Gender preference saved: ${gender.displayName}');
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Failed to save gender preference',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _continue() async {
    if (_isProcessing) {
      AppLogger.warning('⚠️ Continue already in progress, ignoring tap');
      return;
    }

    setState(() => _isProcessing = true);
    AppLogger.info('🚀 Continue button pressed');

    try {
      final genderToSave = _selectedGender ?? Gender.female;
      AppLogger.info('💾 Saving gender: ${genderToSave.displayName}');

      // Save gender to BOTH ProfileService AND Firestore
      final profileService = getIt<ProfileService>();
      await profileService.updateGenderPreference(genderToSave);

      // Also update Firestore profile
      final userProfileService = getIt<UserProfileService>();
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        await userProfileService.updateUserProfile(currentUser.uid, {
          'gender': genderToSave.name,
        });
        AppLogger.info('✅ Gender saved to Firestore');
      }

      AppLogger.info('✅ Gender preference saved successfully');

      // Call the callback to notify AuthFlowController
      widget.onComplete();
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Error saving gender',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _skip() async {
    if (_isProcessing) {
      AppLogger.warning('⚠️ Skip already in progress, ignoring tap');
      return;
    }

    setState(() => _isProcessing = true);
    AppLogger.info('⏭️ Skip button pressed, defaulting to Female');

    try {
      // Save default gender
      final profileService = getIt<ProfileService>();
      await profileService.updateGenderPreference(Gender.female);

      // Also update Firestore profile
      final userProfileService = getIt<UserProfileService>();
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        await userProfileService.updateUserProfile(currentUser.uid, {
          'gender': Gender.female.name,
        });
        AppLogger.info('✅ Default gender saved to Firestore');
      }

      AppLogger.info('✅ Skip completed, calling callback');

      // Call the callback to notify AuthFlowController
      widget.onComplete();
    } catch (e, stackTrace) {
      AppLogger.error('❌ Error during skip', error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // Title
              Text(
                'Choose Your Style',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Subtitle
              Text(
                'This helps us generate mannequins that match your style',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Gender Cards
              Row(
                children: [
                  Expanded(
                    child: _buildGenderCard(
                      gender: Gender.male,
                      icon: Icons.man,
                      label: 'Male',
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildGenderCard(
                      gender: Gender.female,
                      icon: Icons.woman,
                      label: 'Female',
                      theme: theme,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Continue button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: (_selectedGender != null && !_isProcessing)
                      ? _continue
                      : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isProcessing
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : Text(
                          'Continue',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              // Skip button
              TextButton(
                onPressed: !_isProcessing ? _skip : null,
                child: Text(
                  'Skip for now',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderCard({
    required Gender gender,
    required IconData icon,
    required String label,
    required ThemeData theme,
  }) {
    final isSelected = _selectedGender == gender;

    return GestureDetector(
      onTap: () => _selectGender(gender),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        height: 200,
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.primary,
              ),
            ),

            const SizedBox(height: 16),

            // Label
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
            ),

            if (isSelected) ...[
              const SizedBox(height: 8),
              Icon(
                Icons.check_circle_rounded,
                color: theme.colorScheme.onPrimary,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
