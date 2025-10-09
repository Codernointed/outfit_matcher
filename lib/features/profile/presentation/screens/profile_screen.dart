import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vestiq/core/models/profile_data.dart';
import 'package:vestiq/core/services/profile_service.dart';
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
import 'package:vestiq/main.dart' show appThemeModeProvider;

/// Premium profile screen with stats, favorites, preferences, and settings
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() =>
      _ProfileScreenState();
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will clear all cached images and data. '
          'Your wardrobe items will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      HapticFeedback.mediumImpact();
      // TODO: Implement cache clearing when cache services have clear methods
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cache clearing coming soon!'),
          duration: Duration(seconds: 2),
        ),
      );
      AppLogger.info('🗑️ Cache clear requested');
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
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
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
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                HapticFeedback.lightImpact();
                // Future: show more options menu
              },
            ),
          ],
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

              const SizedBox(height: 32),

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
                subtitle: profile.notificationsEnabled
                    ? 'Enabled'
                    : 'Disabled',
                trailing: Switch(
                  value: profile.notificationsEnabled,
                  onChanged: _toggleNotifications,
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

              // Share & Connect Section
              const ProfileSectionHeader(title: 'Share & Connect'),

              ProfileSectionTile(
                icon: Icons.share_outlined,
                title: 'Share My Wardrobe',
                subtitle: 'Generate shareable link',
                onTap: _shareWardrobe,
              ),

              ProfileSectionTile(
                icon: Icons.photo_camera_outlined,
                title: 'Share to Instagram',
                subtitle: 'Export outfit image',
                onTap: _shareToInstagram,
              ),

              ProfileSectionTile(
                icon: Icons.link,
                title: 'Copy Profile Link',
                subtitle: 'Share your profile',
                onTap: _copyProfileLink,
              ),

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

              ProfileSectionTile(
                icon: Icons.logout,
                title: 'Sign Out',
                subtitle: 'Coming soon',
                iconColor: Colors.red,
                enabled: false,
                onTap: null,
              ),

              const SizedBox(height: 40),
            ],
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
}

