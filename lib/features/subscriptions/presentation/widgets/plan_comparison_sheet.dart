import 'package:flutter/material.dart';
import 'package:vestiq/core/constants/app_constants.dart';

class PlanComparisonSheet extends StatelessWidget {
  const PlanComparisonSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final features = _buildFeatures();

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Compare plans',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'See exactly what upgrades when you switch to Premium.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            ...features.map((feature) => _PlanComparisonTile(feature: feature)),
          ],
        ),
      ),
    );
  }

  List<_PlanFeature> _buildFeatures() {
    return const [
      _PlanFeature(
        icon: Icons.checkroom_outlined,
        label: 'Daily wardrobe uploads',
        freeValue: '${AppConstants.freeDailyUploadLimit}',
        premiumValue: '${AppConstants.premiumDailyUploadLimit}',
      ),
      _PlanFeature(
        icon: Icons.auto_awesome,
        label: 'Mannequin renders / month',
        freeValue: '${AppConstants.freeMonthlyMannequinLimit}',
        premiumValue: '${AppConstants.premiumMonthlyMannequinLimit}',
      ),
      _PlanFeature(
        icon: Icons.psychology_alt_outlined,
        label: 'AI pairings & styling',
        freeValue: '${AppConstants.freeMonthlyPairingLimit}',
        premiumValue: 'Unlimited',
      ),
      _PlanFeature(
        icon: Icons.travel_explore_outlined,
        label: 'Inspiration lookups',
        freeValue: '${AppConstants.freeMonthlyInspirationLimit}',
        premiumValue: 'Unlimited',
      ),
      _PlanFeature(
        icon: Icons.brush_outlined,
        label: 'Couture polishing',
        freeValue: 'Locked',
        premiumValue: '${AppConstants.premiumMonthlyPolishingLimit}/month',
      ),
      _PlanFeature(
        icon: Icons.rocket_launch_outlined,
        label: 'Early access drops',
        freeValue: 'No',
        premiumValue: 'Yes',
      ),
    ];
  }
}

class _PlanComparisonTile extends StatelessWidget {
  const _PlanComparisonTile({required this.feature});

  final _PlanFeature feature;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(feature.icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _PlanValueChip(label: 'Free', value: feature.freeValue),
                    const SizedBox(width: 8),
                    _PlanValueChip(
                      label: 'Premium',
                      value: feature.premiumValue,
                      highlight: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanValueChip extends StatelessWidget {
  const _PlanValueChip({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlight
            ? theme.colorScheme.primary.withValues(alpha: 0.12)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: highlight
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanFeature {
  const _PlanFeature({
    required this.icon,
    required this.label,
    required this.freeValue,
    required this.premiumValue,
  });

  final IconData icon;
  final String label;
  final String freeValue;
  final String premiumValue;
}
