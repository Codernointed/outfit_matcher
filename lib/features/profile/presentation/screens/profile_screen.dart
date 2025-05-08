import 'package:flutter/material.dart';
import 'package:outfit_matcher/core/constants/app_constants.dart';
import 'package:outfit_matcher/core/utils/reset_utils.dart';
import 'package:outfit_matcher/features/onboarding/presentation/screens/welcome_screen.dart';

/// Profile screen for user settings and information
class ProfileScreen extends StatelessWidget {
  /// Default constructor
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        children: [
          // User profile section
          const _ProfileHeader(),

          const Divider(),

          // Settings section
          _SettingsSection(),

          const Divider(),

          // Developer options (for testing purposes)
          _DeveloperSection(),
        ],
      ),
    );
  }
}

/// User profile header with avatar and name
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultSpacing),
      child: Column(
        children: [
          // Avatar
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, size: 60, color: Colors.white),
          ),
          const SizedBox(height: AppConstants.defaultSpacing),

          // Name
          Text('User Name', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),

          // Email
          Text(
            'user@example.com',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/// Settings section with user preferences
class _SettingsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppConstants.defaultSpacing),
          child: Text(
            'Settings',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),

        // Settings list items
        ListTile(
          leading: const Icon(Icons.notifications_outlined),
          title: const Text('Notifications'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Navigate to notifications settings
          },
        ),

        ListTile(
          leading: const Icon(Icons.language_outlined),
          title: const Text('Language'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Navigate to language settings
          },
        ),

        ListTile(
          leading: const Icon(Icons.help_outline),
          title: const Text('Help & Support'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // Navigate to help screen
          },
        ),
      ],
    );
  }
}

/// Developer options for testing purposes
class _DeveloperSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppConstants.defaultSpacing),
          child: Text(
            'Developer Options',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),

        // Reset onboarding state
        ListTile(
          leading: const Icon(Icons.refresh, color: Colors.red),
          title: const Text('Reset Onboarding'),
          subtitle: const Text('See welcome and onboarding screens again'),
          onTap: () async {
            // Show confirmation dialog
            final shouldReset = await showDialog<bool>(
              context: context,
              builder:
                  (ctx) => AlertDialog(
                    title: const Text('Reset Onboarding'),
                    content: const Text(
                      'This will reset the onboarding state. You will see the welcome and onboarding screens next time you launch the app.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
            );

            // If user confirmed, reset the onboarding state
            if (shouldReset == true) {
              await ResetUtils.resetOnboardingState();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Onboarding reset. Restart the app to see the welcome screen.',
                    ),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            }
          },
        ),

        // Preview welcome screen directly
        ListTile(
          leading: const Icon(Icons.visibility, color: Colors.blue),
          title: const Text('Preview Welcome Screen'),
          subtitle: const Text('View the welcome screen without resetting'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const WelcomeScreen()),
            );
          },
        ),
      ],
    );
  }
}
