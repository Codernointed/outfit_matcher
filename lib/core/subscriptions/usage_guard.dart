import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/service_locator.dart';
import '../models/user_profile.dart';
import '../services/app_settings_service.dart';
import '../../features/subscriptions/presentation/screens/subscription_overview_screen.dart';
import '../../features/subscriptions/presentation/widgets/plan_comparison_sheet.dart';

/// Guards feature usage based on subscription tier limits.
/// Shows upgrade prompts when users hit their quota.
class UsageGuard {
  final AppSettingsService _settingsService;

  UsageGuard([AppSettingsService? settingsService])
    : _settingsService = settingsService ?? getIt<AppSettingsService>();

  /// Checks if the user can generate outfit pairings based on monthly limit.
  /// Returns true if action is allowed, false if quota exceeded.
  Future<bool> checkPairingLimit(
    BuildContext context, {
    bool showUpgradePrompt = true,
  }) async {
    final subscription = _settingsService.subscriptionSnapshot;
    final usage = _settingsService.usageSnapshot;

    final policy = subscription.tier.usagePolicy;

    // Check if unlimited
    if (policy.hasUnlimitedPairings) {
      return true;
    }

    // Check if exceeded
    final exceedsLimit = usage.monthlyPairingsUsed >= policy.monthlyPairings;

    if (exceedsLimit && showUpgradePrompt && context.mounted) {
      await _showUpgradePrompt(context, 'outfit pairings', subscription.tier);
    }

    return !exceedsLimit;
  }

  /// Checks if user can upload more closet items based on daily limit.
  Future<bool> checkUploadLimit(
    BuildContext context, {
    bool showUpgradePrompt = true,
  }) async {
    final subscription = _settingsService.subscriptionSnapshot;
    final usage = _settingsService.usageSnapshot;

    final policy = subscription.tier.usagePolicy;

    // Check if unlimited
    if (policy.hasUnlimitedUploads) {
      return true;
    }

    // Check if exceeded
    final exceedsLimit = usage.dailyUploadsUsed >= policy.dailyUploads;

    if (exceedsLimit && showUpgradePrompt && context.mounted) {
      await _showUpgradePrompt(context, 'daily uploads', subscription.tier);
    }

    return !exceedsLimit;
  }

  /// Checks if user can use mannequin feature based on monthly limit.
  Future<bool> checkMannequinLimit(
    BuildContext context, {
    bool showUpgradePrompt = true,
  }) async {
    final subscription = _settingsService.subscriptionSnapshot;
    final usage = _settingsService.usageSnapshot;

    final policy = subscription.tier.usagePolicy;

    // Check if feature is available at all (free tier has 0 mannequins)
    if (policy.monthlyMannequins == 0) {
      if (showUpgradePrompt && context.mounted) {
        await _showUpgradePrompt(context, 'AI Mannequin', subscription.tier);
      }
      return false;
    }

    // Check if unlimited
    if (policy.hasUnlimitedMannequins) {
      return true;
    }

    // Check if exceeded
    final exceedsLimit =
        usage.monthlyMannequinsUsed >= policy.monthlyMannequins;

    if (exceedsLimit && showUpgradePrompt && context.mounted) {
      await _showUpgradePrompt(
        context,
        'AI Mannequin generations',
        subscription.tier,
      );
    }

    return !exceedsLimit;
  }

  /// Checks if user has access to inspiration board feature.
  Future<bool> checkInspirationLimit(
    BuildContext context, {
    bool showUpgradePrompt = true,
  }) async {
    final subscription = _settingsService.subscriptionSnapshot;
    final usage = _settingsService.usageSnapshot;

    final policy = subscription.tier.usagePolicy;

    // Check if feature is available at all
    if (policy.monthlyInspirationSearches == 0) {
      if (showUpgradePrompt && context.mounted) {
        await _showUpgradePrompt(
          context,
          'Inspiration Board',
          subscription.tier,
        );
      }
      return false;
    }

    // Check if unlimited
    if (policy.hasUnlimitedInspiration) {
      return true;
    }

    // Check if exceeded
    final exceedsLimit =
        usage.monthlyInspirationUsed >= policy.monthlyInspirationSearches;

    if (exceedsLimit && showUpgradePrompt && context.mounted) {
      await _showUpgradePrompt(
        context,
        'Inspiration searches',
        subscription.tier,
      );
    }

    return !exceedsLimit;
  }

  /// Checks if user can use image polishing feature.
  Future<bool> checkPolishingLimit(
    BuildContext context, {
    bool showUpgradePrompt = true,
  }) async {
    final subscription = _settingsService.subscriptionSnapshot;
    final usage = _settingsService.usageSnapshot;

    final policy = subscription.tier.usagePolicy;

    // Check if feature is available at all
    if (policy.monthlyImagePolish == 0) {
      if (showUpgradePrompt && context.mounted) {
        await _showUpgradePrompt(
          context,
          'Premium Image Polishing',
          subscription.tier,
        );
      }
      return false;
    }

    // Check if unlimited
    if (policy.hasUnlimitedPolishing) {
      return true;
    }

    // Check if exceeded
    final exceedsLimit =
        usage.monthlyPolishingUsed >= policy.monthlyImagePolish;

    if (exceedsLimit && showUpgradePrompt && context.mounted) {
      await _showUpgradePrompt(context, 'Image polishing', subscription.tier);
    }

    return !exceedsLimit;
  }

  Future<void> _showUpgradePrompt(
    BuildContext context,
    String featureName,
    SubscriptionTier currentTier,
  ) async {
    final nextTier = _getNextTier(currentTier);

    final shouldUpgrade = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              'You\'ve reached your ${currentTier.label} plan limit for $featureName.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (nextTier != null)
              Text(
                'Upgrade to ${nextTier.label} to unlock more!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not Now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('View Plans'),
          ),
        ],
      ),
    );

    if (shouldUpgrade == true && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SubscriptionOverviewScreen(),
        ),
      );
    }
  }

  SubscriptionTier? _getNextTier(SubscriptionTier current) {
    switch (current) {
      case SubscriptionTier.free:
        return SubscriptionTier.premium;
      case SubscriptionTier.premium:
        return SubscriptionTier.pro;
      case SubscriptionTier.pro:
        return null; // Already at highest tier
    }
  }

  /// Shows a quick comparison sheet for users to see what they're missing.
  static Future<void> showComparisonSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PlanComparisonSheet(),
    );
  }

  /// Creates a Riverpod provider for UsageGuard.
  static final provider = Provider<UsageGuard>((ref) {
    return UsageGuard();
  });
}
