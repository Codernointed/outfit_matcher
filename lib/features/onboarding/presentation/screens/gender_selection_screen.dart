import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vestiq/core/models/profile_data.dart';
import 'package:vestiq/core/services/profile_service.dart';
import 'package:vestiq/core/di/service_locator.dart';
import 'package:vestiq/core/utils/logger.dart';
import 'package:vestiq/features/outfit_suggestions/presentation/screens/home_screen.dart';
import 'package:vestiq/core/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  void _continue() {
    if (_isProcessing) {
      AppLogger.warning('⚠️ Continue already in progress, ignoring tap');
      return;
    }

    setState(() => _isProcessing = true);
    AppLogger.info('🚀 Continue button pressed');

    try {
      if (_selectedGender == null) {
        AppLogger.info('⚠️ No gender selected, defaulting to Female');
        // Save default gender synchronously
        final profileService = getIt<ProfileService>();
        profileService.updateGenderPreference(Gender.female);
      } else {
        AppLogger.info(
          '✅ Gender already selected: ${_selectedGender!.displayName}',
        );
      }

      AppLogger.info('🎯 Navigating directly to home screen');
      _navigateToHome();
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Error during continue process',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _skip() {
    if (_isProcessing) {
      AppLogger.warning('⚠️ Skip already in progress, ignoring tap');
      return;
    }

    setState(() => _isProcessing = true);
    AppLogger.info('⏭️ Skip button pressed');

    try {
      AppLogger.info('⚠️ Skipping gender selection, defaulting to Female');
      // Save default gender synchronously
      final profileService = getIt<ProfileService>();
      profileService.updateGenderPreference(Gender.female);

      AppLogger.info('🎯 Navigating directly to home screen');
      _navigateToHome();
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Error during skip process',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _navigateToHome() async {
    try {
      // Save that onboarding has been completed
      final prefs = getIt<SharedPreferences>();
      await prefs.setBool(AppConstants.onboardingCompletedKey, true);
      AppLogger.info('✅ Onboarding completion flag saved');

      if (!mounted) {
        AppLogger.warning('⚠️ Widget not mounted, aborting navigation');
        return;
      }

      AppLogger.info('🏠 Navigating to Home Screen');
      // Navigate directly to home screen
      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => HomeScreen()),
        (route) => false,
      );
      AppLogger.info('✅ Successfully navigated to Home Screen');
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ Error navigating to home',
        error: e,
        stackTrace: stackTrace,
      );
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
