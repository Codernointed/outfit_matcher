import 'package:flutter/material.dart';
import 'package:vestiq/features/subscriptions/presentation/screens/subscription_overview_screen.dart';

/// Shows a subtle, Tinder-style modal when users hit their free tier limits.
/// This is much better UX than constantly showing upgrade prompts on the homepage.
class LimitReachedModal {
  /// Show when user hits their daily upload limit
  static void showUploadLimitReached(
    BuildContext context, {
    required int limit,
  }) {
    _showLimitModal(
      context,
      icon: Icons.cloud_upload_outlined,
      title: "You're on a roll! 🔥",
      message:
          "You've uploaded $limit items today. That's the max for your current plan.",
      subMessage: 'Upgrade to Premium for double the uploads.',
      primaryAction: 'See Premium Plans',
      secondaryAction: 'Maybe Later',
    );
  }

  /// Show when user hits their monthly mannequin generation limit
  static void showMannequinLimitReached(
    BuildContext context, {
    required int limit,
  }) {
    _showLimitModal(
      context,
      icon: Icons.person_outline,
      title: 'Style limit reached ✨',
      message: "You've generated $limit mannequin looks this month.",
      subMessage: 'Premium members get 2x more generations.',
      primaryAction: 'Unlock More Looks',
      secondaryAction: 'Continue Later',
    );
  }

  /// Show when user hits their monthly pairing limit
  static void showPairingLimitReached(
    BuildContext context, {
    required int limit,
  }) {
    _showLimitModal(
      context,
      icon: Icons.auto_awesome,
      title: 'Pairings exhausted 👗',
      message: "You've created $limit outfit pairings this month.",
      subMessage: 'Go Premium for unlimited AI pairings.',
      primaryAction: 'Go Unlimited',
      secondaryAction: 'Not Now',
    );
  }

  /// Show when user hits their monthly inspiration search limit
  static void showInspirationLimitReached(
    BuildContext context, {
    required int limit,
  }) {
    _showLimitModal(
      context,
      icon: Icons.explore_outlined,
      title: 'Inspiration quota reached 💡',
      message: "You've searched for inspiration $limit times this month.",
      subMessage: 'Premium unlocks unlimited inspiration searches.',
      primaryAction: 'See Premium',
      secondaryAction: 'Maybe Later',
    );
  }

  /// Generic limit reached modal
  static void _showLimitModal(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    required String subMessage,
    required String primaryAction,
    required String secondaryAction,
  }) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Icon with gradient background
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withValues(alpha: 0.15),
                    primaryColor.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: primaryColor),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Sub message (premium pitch)
            Text(
              subMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // Primary CTA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionOverviewScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.workspace_premium, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      primaryAction,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Secondary action
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                secondaryAction,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
