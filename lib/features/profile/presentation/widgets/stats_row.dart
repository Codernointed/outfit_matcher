import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vestiq/core/models/profile_data.dart';
import 'package:vestiq/core/theme/vestiq_soft_theme.dart';
import 'package:vestiq/core/widgets/soft_glass/animated_pressable.dart';

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
    final soft = context.vestiqSoft;

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
        child: AnimatedPressable(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: soft.cardSoftShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: soft.primarySoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: soft.primary, size: 22),
                ),
                const SizedBox(height: 12),
                Text(
                  value.toString(),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.01 * 20,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
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
