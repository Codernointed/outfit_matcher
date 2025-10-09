import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vestiq/core/models/profile_data.dart';

/// Premium stats row with three animated cards
class StatsRow extends StatelessWidget {
  final ProfileStats stats;
  final VoidCallback onItemsTap;
  final VoidCallback onLooksTap;
  final VoidCallback onWearsTap;

  const StatsRow({
    super.key,
    required this.stats,
    required this.onItemsTap,
    required this.onLooksTap,
    required this.onWearsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatCard(
            context,
            icon: Icons.checkroom,
            value: stats.itemsCount,
            label: 'Items',
            onTap: onItemsTap,
            delay: 0,
          ),
          _buildStatCard(
            context,
            icon: Icons.favorite_border,
            value: stats.looksCount,
            label: 'Looks',
            onTap: onLooksTap,
            delay: 100,
          ),
          _buildStatCard(
            context,
            icon: Icons.auto_awesome,
            value: stats.totalWears,
            label: 'Wears',
            onTap: onWearsTap,
            delay: 200,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required int value,
    required String label,
    required VoidCallback onTap,
    required int delay,
  }) {
    final theme = Theme.of(context);

    return Expanded(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 400 + delay),
        curve: Curves.easeOutCubic,
        builder: (context, animValue, child) {
          return Opacity(
            opacity: animValue,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - animValue)),
              child: child,
            ),
          );
        },
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.surface,
                  theme.colorScheme.primary.withValues(alpha: 0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 28),
                const SizedBox(height: 8),
                Text(
                  value.toString(),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
