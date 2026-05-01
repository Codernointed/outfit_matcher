import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:vestiq/core/theme/vestiq_soft_theme.dart';

/// Drop-in replacement for [showModalBottomSheet] that wraps the sheet in a
/// frosted glass surface with a 28px top radius and a backdrop scrim blur.
///
/// Example:
/// ```dart
/// showGlassBottomSheet<void>(
///   context: context,
///   builder: (context) => MySheetContent(),
/// );
/// ```
Future<T?> showGlassBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool isDismissible = true,
  bool enableDrag = true,
  double scrimOpacity = 0.48,
  double topRadius = 28,
  Color? backgroundColor,
  bool useSafeArea = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: scrimOpacity),
    useSafeArea: useSafeArea,
    builder: (ctx) => GlassSheetContainer(
      topRadius: topRadius,
      backgroundColor: backgroundColor,
      child: builder(ctx),
    ),
  );
}

/// The actual frosted-glass container that wraps sheet content.
///
/// Used by [showGlassBottomSheet] but also exported for cases that need to
/// provide a custom modal shell (e.g. Hero animations from a list item).
class GlassSheetContainer extends StatelessWidget {
  const GlassSheetContainer({
    super.key,
    required this.child,
    this.topRadius = 28,
    this.backgroundColor,
    this.showHandle = true,
  });

  final Widget child;
  final double topRadius;
  final Color? backgroundColor;
  final bool showHandle;

  @override
  Widget build(BuildContext context) {
    final soft = context.vestiqSoft;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fill =
        backgroundColor ??
        theme.colorScheme.surface.withValues(alpha: isDark ? 0.92 : 0.96);

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(topRadius)),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: soft.glassBlurMedium,
          sigmaY: soft.glassBlurMedium,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: fill,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(topRadius)),
            border: Border(
              top: BorderSide(
                color: soft.glassBorder
                    .withValues(alpha: soft.glassBorderOpacity),
                width: isDark ? 0.6 : 1.0,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showHandle)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: GlassDragHandle(),
                  ),
                Flexible(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 40x4 pill drag handle in [VestiqSoftTheme.outline] color.
class GlassDragHandle extends StatelessWidget {
  const GlassDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final soft = context.vestiqSoft;
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: soft.outline,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
