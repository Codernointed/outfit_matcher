import 'package:flutter/material.dart';

class SubscriptionUpgradeCard extends StatelessWidget {
  const SubscriptionUpgradeCard({
    super.key,
    required this.onTap,
    this.compact = false,
  });

  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final perks = compact
        ? const ['Double uploads', 'Unlimited pairings']
        : const [
            '16 uploads per day (2x free)',
            'Unlimited AI pairings & inspo',
            'Couture image polishing',
          ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium, color: theme.colorScheme.onPrimary),
              const SizedBox(width: 8),
              Text(
                'Premium unlocks more',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...perks.map(
            (perk) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 18, color: theme.colorScheme.onPrimary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      perk,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.onPrimary,
                foregroundColor: theme.colorScheme.primary,
              ),
              onPressed: onTap,
              child: const Text('See Premium plans'),
            ),
          ),
        ],
      ),
    );
  }
}
