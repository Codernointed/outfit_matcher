import 'package:flutter/material.dart';

import 'package:vestiq/core/theme/vestiq_soft_theme.dart';
import 'package:vestiq/core/widgets/soft_glass/animated_pressable.dart';
import 'package:vestiq/core/widgets/soft_glass/glass_card.dart';

/// Soft Glass Hybrid button.
///
/// Variants:
///   - [SoftButtonVariant.primary]: solid Petal Pink fill with primary glow
///   - [SoftButtonVariant.soft]: cream `surfaceContainer` fill, no shadow
///   - [SoftButtonVariant.glass]: frosted glass fill with luminous border
///   - [SoftButtonVariant.outline]: transparent fill with primary stroke
class SoftButton extends StatelessWidget {
  const SoftButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = SoftButtonVariant.primary,
    this.fullWidth = true,
    this.height = 56,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
    this.loading = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final SoftButtonVariant variant;
  final bool fullWidth;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final soft = context.vestiqSoft;
    final theme = Theme.of(context);
    final isDisabled = onPressed == null || loading;

    Color textColor;
    Widget surface;

    final labelStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      fontFamily: 'Poppins',
      letterSpacing: 0.01,
      color: Colors.white,
    );

    Widget buildContent(Color fg) {
      final children = <Widget>[];
      if (loading) {
        children.add(
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          ),
        );
      } else {
        if (icon != null) {
          children.add(Icon(icon, size: 20, color: fg));
          children.add(const SizedBox(width: 10));
        }
        children.add(
          Text(
            label,
            style: labelStyle.copyWith(color: fg),
          ),
        );
      }
      return Center(
        child: Padding(
          padding: padding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      );
    }

    switch (variant) {
      case SoftButtonVariant.primary:
        textColor = Colors.white;
        surface = DecoratedBox(
          decoration: BoxDecoration(
            color: isDisabled
                ? soft.primary.withValues(alpha: 0.5)
                : soft.primary,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: isDisabled ? const [] : soft.primaryGlowShadow,
          ),
          child: SizedBox(
            height: height,
            width: fullWidth ? double.infinity : null,
            child: buildContent(textColor),
          ),
        );
        break;

      case SoftButtonVariant.soft:
        textColor = theme.colorScheme.onSurface;
        surface = DecoratedBox(
          decoration: BoxDecoration(
            color: soft.surfaceContainer,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: soft.cardSoftShadow,
          ),
          child: SizedBox(
            height: height,
            width: fullWidth ? double.infinity : null,
            child: buildContent(textColor),
          ),
        );
        break;

      case SoftButtonVariant.glass:
        textColor = theme.colorScheme.onSurface;
        surface = GlassCard(
          borderRadius: borderRadius,
          padding: EdgeInsets.zero,
          shadow: GlassShadow.soft,
          strong: true,
          child: SizedBox(
            height: height,
            width: fullWidth ? double.infinity : null,
            child: buildContent(textColor),
          ),
        );
        break;

      case SoftButtonVariant.outline:
        textColor = soft.primary;
        surface = DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: soft.primary, width: 1.5),
          ),
          child: SizedBox(
            height: height,
            width: fullWidth ? double.infinity : null,
            child: buildContent(textColor),
          ),
        );
        break;
    }

    return AnimatedPressable(
      onTap: isDisabled ? null : onPressed,
      child: surface,
    );
  }
}

enum SoftButtonVariant { primary, soft, glass, outline }
