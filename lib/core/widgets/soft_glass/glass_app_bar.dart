import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:vestiq/core/theme/vestiq_soft_theme.dart';

/// Translucent app bar that blurs the content scrolling beneath it.
///
/// Drop-in replacement for [AppBar] -- has the same `title`, `leading`,
/// `actions` API but renders a frosted glass surface that lets imagery and
/// content tint through. Use on screens where content scrolls underneath
/// (home, closet, profile). For settings-style screens prefer the regular
/// solid [AppBar] from the theme.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.centerTitle = true,
    this.height = kToolbarHeight,
    this.bottomBorder = true,
  });

  final String? title;
  final Widget? titleWidget;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final double height;
  final bool bottomBorder;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final soft = context.vestiqSoft;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mediaPadding = MediaQuery.of(context).padding;

    final titleText = titleWidget ??
        (title == null
            ? null
            : Text(
                title!,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  letterSpacing: -0.01,
                ),
              ));

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: soft.glassBlurMedium,
          sigmaY: soft.glassBlurMedium,
        ),
        child: Container(
          height: height + mediaPadding.top,
          padding: EdgeInsets.only(top: mediaPadding.top),
          decoration: BoxDecoration(
            color: soft.glassFill
                .withValues(alpha: soft.glassFillOpacityStrong),
            border: bottomBorder
                ? Border(
                    bottom: BorderSide(
                      color: soft.glassBorder
                          .withValues(alpha: soft.glassBorderOpacity * 0.4),
                      width: isDark ? 0.5 : 0.8,
                    ),
                  )
                : null,
          ),
          child: SizedBox(
            height: height,
            child: NavigationToolbar(
              leading: leading,
              middle: titleText,
              trailing: actions == null
                  ? null
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions!,
                    ),
              centerMiddle: centerTitle,
            ),
          ),
        ),
      ),
    );
  }
}
