import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:vestiq/core/theme/vestiq_soft_theme.dart';
import 'package:vestiq/core/widgets/soft_glass/animated_pressable.dart';

/// Premium floating glass nav bar -- frosted island that hovers above content.
///
/// Implements the Soft Glass Hybrid spec from DESIGN.md:
///   - 28px outer radius
///   - frosted glass fill at strong opacity, 1px luminous border
///   - active item is a `primary-soft` pill with primary-pink icon and label
///   - tap haptics + spring scale feedback via [AnimatedPressable]
class DynamicIslandNavBar extends StatelessWidget {
  const DynamicIslandNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<DynamicIslandNavItem> items;

  static const double _barHeight = 64;

  @override
  Widget build(BuildContext context) {
    final soft = context.vestiqSoft;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return RepaintBoundary(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          bottomPadding > 0 ? bottomPadding + 12 : 20,
        ),
        child: SizedBox(
          height: _barHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: soft.glassFloatingShadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: soft.glassBlurMedium,
                  sigmaY: soft.glassBlurMedium,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: soft.glassFill
                        .withValues(alpha: soft.glassFillOpacityStrong),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: soft.glassBorder
                          .withValues(alpha: soft.glassBorderOpacity),
                      width: isDark ? 0.6 : 1.0,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: List.generate(
                        items.length,
                        (index) => _NavItem(
                          item: items[index],
                          isActive: currentIndex == index,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onTap(index);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final DynamicIslandNavItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final soft = context.vestiqSoft;

    return AnimatedPressable(
      onTap: onTap,
      haptic: false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        height: 44,
        padding: EdgeInsets.symmetric(horizontal: isActive ? 16 : 12),
        decoration: BoxDecoration(
          color: isActive ? soft.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: isActive ? 1.06 : 1.0,
              child: Icon(
                isActive ? item.activeIcon : item.icon,
                size: 22,
                color: isActive
                    ? soft.primary
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.55),
              ),
            ),
            ClipRect(
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                widthFactor: isActive ? 1.0 : 0.0,
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: soft.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      letterSpacing: 0.02,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Navigation item for the dynamic island nav bar.
class DynamicIslandNavItem {
  const DynamicIslandNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}
