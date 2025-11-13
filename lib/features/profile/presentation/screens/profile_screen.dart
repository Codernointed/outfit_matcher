import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vestiq/core/models/profile_data.dart';
import 'package:vestiq/core/services/profile_service.dart';
import 'package:vestiq/core/services/storage_service.dart';
import 'package:vestiq/core/services/analytics_service.dart';
import 'package:vestiq/core/utils/logger.dart';
import 'package:vestiq/core/utils/reset_utils.dart';
import 'package:vestiq/core/constants/app_constants.dart';
import 'package:vestiq/core/di/service_locator.dart';
import 'package:vestiq/features/profile/presentation/providers/profile_providers.dart';
import 'package:vestiq/features/profile/presentation/widgets/profile_header.dart';
import 'package:vestiq/features/profile/presentation/widgets/stats_row.dart';
import 'package:vestiq/features/profile/presentation/widgets/favorites_carousel.dart';
import 'package:vestiq/features/profile/presentation/widgets/profile_section_tile.dart';
import 'package:vestiq/features/wardrobe/presentation/screens/enhanced_closet_screen.dart';
import 'package:vestiq/features/outfit_suggestions/presentation/screens/saved_looks_screen.dart';
import 'package:vestiq/features/auth/presentation/providers/auth_providers.dart';
import 'package:vestiq/main.dart' show appThemeModeProvider;

/// Premium profile screen with stats, favorites, preferences, and settings
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _profileService = getIt<ProfileService>();
  PermissionStatus _cameraPermission = PermissionStatus.denied;
  PermissionStatus _micPermission = PermissionStatus.denied;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final camera = await Permission.camera.status;
    final mic = await Permission.microphone.status;
    if (mounted) {
      setState(() {
        _cameraPermission = camera;
        _micPermission = mic;
      });
    }
  }

  void _refreshProfile() {
    ref.invalidate(profileProvider);
    ref.invalidate(profileStatsProvider);
    ref.invalidate(favoriteItemsProvider);
    ref.invalidate(favoriteLooksProvider);
  }

  Future<void> _toggleTheme() async {
    HapticFeedback.mediumImpact();
    ref.read(appThemeModeProvider.notifier).toggleTheme();
    final newMode = ref.read(appThemeModeProvider);
    await _profileService.saveThemePreference(newMode);
    AppLogger.info('🎨 Theme toggled to ${newMode.name}');
  }

  Future<void> _toggleNotifications(bool value) async {
    HapticFeedback.lightImpact();
    await _profileService.updateNotificationsEnabled(value);
    _refreshProfile();
  }

  Future<void> _updateGender(Gender gender) async {
    HapticFeedback.lightImpact();
    await _profileService.updateGenderPreference(gender);
    _refreshProfile();
  }

  Future<void> _handlePermissionTap(Permission permission) async {
    final status = await permission.status;
    if (status.isDenied) {
      final result = await permission.request();
      await _checkPermissions();
      if (mounted && result.isPermanentlyDenied) {
        _showPermissionDialog();
      }
    } else if (status.isPermanentlyDenied) {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'This permission is required for full app functionality. '
          'Please enable it in Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareWardrobe() async {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share feature coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
    AppLogger.info('📤 Share wardrobe requested');
  }

  Future<void> _shareToInstagram() async {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Instagram share coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
    AppLogger.info('📷 Instagram share requested');
  }

  Future<void> _copyProfileLink() async {
    HapticFeedback.mediumImpact();
    await Clipboard.setData(
      const ClipboardData(text: 'https://vestiq.app/profile/user'),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile link copied! (Feature coming soon)'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    AppLogger.info('🔗 Profile link copied');
  }

  Future<void> _showHelpScreen() async {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Help & Support coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showPrivacyPolicy() async {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Privacy Policy coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _clearCache() async {
    // First calculate storage
    final storageService = StorageService();
    final storageInfo = await storageService.calculateStorage();

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: Text(
          'This will clear ${storageInfo.formattedCache} of cached data.\n'
          'Your wardrobe items will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      HapticFeedback.mediumImpact();

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final clearedMB = await storageService.clearCache();

        // Track analytics
        final analytics = AnalyticsService();
        await analytics.logCacheCleared(sizeMB: clearedMB);

        if (mounted) {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Cache cleared: ${clearedMB.toStringAsFixed(2)} MB',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        AppLogger.info('✅ Cache cleared: ${clearedMB}MB');
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error clearing cache: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        AppLogger.error('❌ Cache clear error: $e');
      }
    }
  }

  Future<void> _resetOnboarding() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Onboarding'),
        content: const Text(
          'This will reset the onboarding state. '
          'The app will restart and show the welcome screen again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticFeedback.mediumImpact();
      await ResetUtils.resetOnboardingState();
      AppLogger.info('⚠️ Onboarding reset');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please restart the app to see onboarding'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      HapticFeedback.mediumImpact();

      try {
        // Track analytics
        final analytics = AnalyticsService();
        await analytics.logSignOut();

        // Sign out
        final authService = ref.read(authServiceProvider);
        await authService.signOut();

        AppLogger.info('👋 User signed out');

        // Navigation is handled by AuthWrapper
      } catch (e) {
        AppLogger.error('❌ Sign out error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        icon: const Icon(Icons.warning, color: Colors.red, size: 48),
        content: const Text(
          '⚠️ This action cannot be undone!\n\n'
          'All your data including:\n'
          '• Wardrobe items\n'
          '• Saved outfits\n'
          '• Preferences\n'
          '• Generation history\n\n'
          'will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Second confirmation
      final finalConfirmation = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Final Confirmation'),
          content: const Text(
            'Are you absolutely sure?\n\n'
            'Type DELETE below to confirm:',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Confirm Delete'),
            ),
          ],
        ),
      );

      if (finalConfirmation == true && mounted) {
        HapticFeedback.heavyImpact();

        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        try {
          // Track analytics before deletion
          final analytics = AnalyticsService();
          await analytics.logAccountDeleted();

          // Delete account
          final authService = ref.read(authServiceProvider);
          await authService.deleteAccount();

          AppLogger.info('🗑️ Account deleted');

          // Navigation is handled by AuthWrapper
        } catch (e) {
          AppLogger.error('❌ Account deletion error: $e');
          if (mounted) {
            Navigator.pop(context); // Close loading
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error deleting account: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _showStorageInfo() async {
    HapticFeedback.lightImpact();

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final storageService = StorageService();
      final storageInfo = await storageService.calculateStorage();

      if (mounted) {
        Navigator.pop(context); // Close loading

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Storage Usage'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total: ${storageInfo.formattedTotal}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  ...storageInfo.breakdown.entries.map((entry) {
                    if (entry.value > 0) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key),
                            Text(
                              '${entry.value.toStringAsFixed(2)} MB',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }).toList(),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              if (storageInfo.cacheSize > 0)
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _clearCache();
                  },
                  child: const Text('Clear Cache'),
                ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error calculating storage: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editProfile() async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    HapticFeedback.lightImpact();

    final nameController = TextEditingController(text: currentUser.displayName);
    final bioController = TextEditingController(text: currentUser.bio);

    final result = await showDialog<Map<String, String>?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bioController,
              decoration: const InputDecoration(
                labelText: 'Bio',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 150,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, {
                'displayName': nameController.text,
                'bio': bioController.text,
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      HapticFeedback.mediumImpact();

      try {
        final userProfileService = ref.read(userProfileServiceProvider);
        await userProfileService.updateUserProfile(currentUser.uid, {
          'displayName': result['displayName'],
          'bio': result['bio'],
          'updatedAt': DateTime.now(),
        });

        // Track analytics
        final analytics = AnalyticsService();
        await analytics.logProfileUpdated(
          fieldsUpdated: ['displayName', 'bio'],
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              duration: Duration(seconds: 2),
            ),
          );
        }

        _refreshProfile();
        AppLogger.info('✅ Profile updated');
      } catch (e) {
        AppLogger.error('❌ Profile update error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating profile: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(profileProvider);
    final statsAsync = ref.watch(profileStatsProvider);
    final favoriteItemsAsync = ref.watch(favoriteItemsProvider);
    final favoriteLooksAsync = ref.watch(favoriteLooksProvider);
    final themeMode = ref.watch(appThemeModeProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshProfile();
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: profileAsync.when(
          data: (profile) => _buildProfileContent(
            profile,
            statsAsync,
            favoriteItemsAsync,
            favoriteLooksAsync,
            theme,
            themeMode,
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load profile',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _refreshProfile,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(
    ProfileData profile,
    AsyncValue<ProfileStats> statsAsync,
    AsyncValue favorites,
    AsyncValue looks,
    ThemeData theme,
    ThemeMode themeMode,
  ) {
    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          floating: true,
          title: const Text('Profile'),
          centerTitle: true,
          // actions: [
          //   IconButton(
          //     icon: const Icon(Icons.more_vert),
          //     onPressed: () {
          //       HapticFeedback.lightImpact();
          //       // Future: show more options menu
          //     },
          //   ),
          // ],
        ),

        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Header
              ProfileHeader(
                profile: profile,
                onProfileUpdated: _refreshProfile,
              ),

              const SizedBox(height: 24),

              // Generations indicator (from AppUser data)
              ref
                  .watch(currentUserProvider)
                  .when(
                    data: (appUser) {
                      if (appUser == null) return const SizedBox.shrink();

                      final todayGen = appUser.todayGenerations;
                      final totalGen = appUser.totalGenerations;
                      final limit = appUser.generationsLimit;
                      final tier = appUser.subscriptionTier;

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary.withValues(alpha: 0.1),
                              theme.colorScheme.secondary.withValues(
                                alpha: 0.05,
                              ),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.auto_awesome,
                                      color: theme.colorScheme.primary,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Generations',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    tier.name.toUpperCase(),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildGenerationStat(
                                  context,
                                  theme,
                                  'Today',
                                  '$todayGen/$limit',
                                  todayGen >= limit
                                      ? Colors.red
                                      : theme.colorScheme.primary,
                                ),
                                Container(
                                  height: 40,
                                  width: 1,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.1,
                                  ),
                                ),
                                _buildGenerationStat(
                                  context,
                                  theme,
                                  'Total',
                                  totalGen.toString(),
                                  theme.colorScheme.primary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

              const SizedBox(height: 24),

              // Stats Row
              statsAsync.when(
                data: (stats) => StatsRow(
                  stats: stats,
                  onItemsTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EnhancedClosetScreen(),
                      ),
                    );
                  },
                  onLooksTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SavedLooksScreen(),
                      ),
                    );
                  },
                  onWearsTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Wear history coming soon!'),
                      ),
                    );
                  },
                ),
                loading: () => const SizedBox(height: 120),
                error: (_, __) => const SizedBox(height: 120),
              ),

              const SizedBox(height: 32),

              // Favorites Section
              favorites.when(
                data: (items) => looks.when(
                  data: (looksList) => FavoritesCarousel(
                    favoriteItems: items,
                    favoriteLooks: looksList,
                    onViewAll: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SavedLooksScreen(
                            initialFilter: 'favorites',
                          ),
                        ),
                      );
                    },
                  ),
                  loading: () => const SizedBox(height: 140),
                  error: (_, __) => const SizedBox(height: 140),
                ),
                loading: () => const SizedBox(height: 140),
                error: (_, __) => const SizedBox(height: 140),
              ),

              // Preferences Section
              const ProfileSectionHeader(title: 'Preferences'),

              ProfileSectionTile(
                icon: themeMode == ThemeMode.light
                    ? Icons.light_mode
                    : Icons.dark_mode,
                title: 'Theme',
                subtitle: themeMode == ThemeMode.light ? 'Light' : 'Dark',
                onTap: _toggleTheme,
                trailing: Switch(
                  value: themeMode == ThemeMode.dark,
                  onChanged: (_) => _toggleTheme(),
                ),
              ),

              ProfileSectionTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: profile.notificationsEnabled ? 'Enabled' : 'Disabled',
                trailing: Switch(
                  value: profile.notificationsEnabled,
                  onChanged: _toggleNotifications,
                ),
              ),

              ProfileSectionTile(
                icon: Icons.person_outline,
                title: 'Gender Preference',
                subtitle: 'For mannequin generation',
                onTap: null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildGenderChip(
                      Gender.male,
                      profile.preferredGender,
                      theme,
                    ),
                    const SizedBox(width: 8),
                    _buildGenderChip(
                      Gender.female,
                      profile.preferredGender,
                      theme,
                    ),
                  ],
                ),
              ),

              ProfileSectionTile(
                icon: Icons.camera_alt_outlined,
                title: 'Camera Access',
                subtitle: _getPermissionStatusText(_cameraPermission),
                iconColor: _getPermissionColor(_cameraPermission),
                onTap: () => _handlePermissionTap(Permission.camera),
              ),

              ProfileSectionTile(
                icon: Icons.mic_outlined,
                title: 'Microphone Access',
                subtitle: _getPermissionStatusText(_micPermission),
                iconColor: _getPermissionColor(_micPermission),
                onTap: () => _handlePermissionTap(Permission.microphone),
              ),

              // // Share & Connect Section
              // const ProfileSectionHeader(title: 'Share & Connect'),

              // ProfileSectionTile(
              //   icon: Icons.share_outlined,
              //   title: 'Share My Wardrobe',
              //   subtitle: 'Generate shareable link',
              //   onTap: _shareWardrobe,
              // ),

              // ProfileSectionTile(
              //   icon: Icons.photo_camera_outlined,
              //   title: 'Share to Instagram',
              //   subtitle: 'Export outfit image',
              //   onTap: _shareToInstagram,
              // ),

              // ProfileSectionTile(
              //   icon: Icons.link,
              //   title: 'Copy Profile Link',
              //   subtitle: 'Share your profile',
              //   onTap: _copyProfileLink,
              // ),

              // About Section
              const ProfileSectionHeader(title: 'About'),

              ProfileSectionTile(
                icon: Icons.help_outline,
                title: 'Help & Support',
                onTap: _showHelpScreen,
              ),

              ProfileSectionTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: _showPrivacyPolicy,
              ),

              ProfileSectionTile(
                icon: Icons.info_outline,
                title: 'App Version',
                subtitle: AppConstants.appVersion,
                onTap: null,
              ),

              // Account Section
              const ProfileSectionHeader(title: 'Account'),

              ProfileSectionTile(
                icon: Icons.edit,
                title: 'Edit Profile',
                subtitle: 'Update your name and bio',
                iconColor: Colors.blue,
                onTap: _editProfile,
              ),

              ProfileSectionTile(
                icon: Icons.storage,
                title: 'Storage Usage',
                subtitle: 'View app storage details',
                iconColor: Colors.purple,
                onTap: _showStorageInfo,
              ),

              ProfileSectionTile(
                icon: Icons.delete_outline,
                title: 'Clear Cache',
                subtitle: 'Free up storage space',
                iconColor: Colors.orange,
                onTap: _clearCache,
              ),

              ProfileSectionTile(
                icon: Icons.refresh,
                title: 'Reset Onboarding',
                subtitle: 'Show welcome screens again',
                iconColor: Colors.orange,
                onTap: _resetOnboarding,
              ),

              const Divider(height: 32),

              ProfileSectionTile(
                icon: Icons.logout,
                title: 'Sign Out',
                subtitle: 'Sign out of your account',
                iconColor: Colors.red,
                onTap: _signOut,
              ),

              ProfileSectionTile(
                icon: Icons.delete_forever,
                title: 'Delete Account',
                subtitle: 'Permanently delete your account',
                iconColor: Colors.red,
                onTap: _deleteAccount,
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenerationStat(
    BuildContext context,
    ThemeData theme,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  String _getPermissionStatusText(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return 'Granted';
      case PermissionStatus.denied:
        return 'Denied';
      case PermissionStatus.restricted:
        return 'Restricted';
      case PermissionStatus.limited:
        return 'Limited';
      case PermissionStatus.permanentlyDenied:
        return 'Permanently Denied';
      case PermissionStatus.provisional:
        return 'Provisional';
    }
  }

  Color _getPermissionColor(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return Colors.green;
      case PermissionStatus.denied:
      case PermissionStatus.permanentlyDenied:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Widget _buildGenderChip(
    Gender gender,
    Gender currentGender,
    ThemeData theme,
  ) {
    final isSelected = gender == currentGender;
    return GestureDetector(
      onTap: () => _updateGender(gender),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          gender.displayName,
          style: TextStyle(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
