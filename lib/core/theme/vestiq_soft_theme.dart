import 'package:flutter/material.dart';

/// ThemeExtension that exposes Vestiq's Soft Glass Hybrid design tokens to the
/// rest of the app via `Theme.of(context).extension<VestiqSoftTheme>()`.
///
/// Read DESIGN.md for the conceptual rationale behind every token here.
@immutable
class VestiqSoftTheme extends ThemeExtension<VestiqSoftTheme> {
  const VestiqSoftTheme({
    required this.canvas,
    required this.surface,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceVariant,
    required this.outline,
    required this.outlineSoft,
    required this.primary,
    required this.primarySoft,
    required this.onPrimarySoft,
    required this.primaryGlow,
    required this.success,
    required this.warning,
    required this.error,
    required this.glassFill,
    required this.glassFillStrong,
    required this.glassBorder,
    required this.glassTintWarm,
    required this.glassTintRose,
    required this.softHighlight,
    required this.softShadow,
    required this.cardSoftShadow,
    required this.glassFloatingShadow,
    required this.primaryGlowShadow,
    required this.neumorphicRaisedShadow,
    required this.neumorphicPressedShadow,
    required this.glassBlurSoft,
    required this.glassBlurMedium,
    required this.glassBlurStrong,
    required this.glassFillOpacity,
    required this.glassFillOpacityStrong,
    required this.glassBorderOpacity,
    required this.springDuration,
    required this.springCurve,
    required this.pressScale,
  });

  // Surfaces
  final Color canvas;
  final Color surface;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceVariant;
  final Color outline;
  final Color outlineSoft;

  // Brand
  final Color primary;
  final Color primarySoft;
  final Color onPrimarySoft;
  final Color primaryGlow;

  // Semantic
  final Color success;
  final Color warning;
  final Color error;

  // Glass tokens
  final Color glassFill;
  final Color glassFillStrong;
  final Color glassBorder;
  final Color glassTintWarm;
  final Color glassTintRose;

  // Neumorphic light source
  final Color softHighlight;
  final Color softShadow;

  // Composed shadow lists (drop into a [BoxDecoration.boxShadow]).
  final List<BoxShadow> cardSoftShadow;
  final List<BoxShadow> glassFloatingShadow;
  final List<BoxShadow> primaryGlowShadow;
  final List<BoxShadow> neumorphicRaisedShadow;
  final List<BoxShadow> neumorphicPressedShadow;

  // Glass blur sigmas
  final double glassBlurSoft;
  final double glassBlurMedium;
  final double glassBlurStrong;

  // Glass fill opacities (already-resolved for the active brightness).
  final double glassFillOpacity;
  final double glassFillOpacityStrong;
  final double glassBorderOpacity;

  // Motion
  final Duration springDuration;
  final Curve springCurve;
  final double pressScale;

  /// Light-mode tokens.
  static VestiqSoftTheme get light {
    const canvas = Color(0xFFF8F6F4);
    const surface = Color(0xFFFFFFFF);
    const surfaceContainer = Color(0xFFFBF7F4);
    const surfaceContainerHigh = Color(0xFFF3EDE8);
    const surfaceVariant = Color(0xFFFAF0EE);
    const outline = Color(0xFFE8E1DA);
    const outlineSoft = Color(0xFFF0EAE3);

    const primary = Color(0xFFFF4D6D);
    const primarySoft = Color(0xFFFFE5EB);
    const onPrimarySoft = Color(0xFF7A1A2E);
    const primaryGlow = Color(0xFFFF8FA3);

    const success = Color(0xFF3DA678);
    const warning = Color(0xFFE8A33C);
    const error = Color(0xFFE5484D);

    const softHighlight = Color(0xFFFFFFFF);
    const softShadow = Color(0xFFD9D2CB);

    return VestiqSoftTheme(
      canvas: canvas,
      surface: surface,
      surfaceContainer: surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh,
      surfaceVariant: surfaceVariant,
      outline: outline,
      outlineSoft: outlineSoft,
      primary: primary,
      primarySoft: primarySoft,
      onPrimarySoft: onPrimarySoft,
      primaryGlow: primaryGlow,
      success: success,
      warning: warning,
      error: error,
      glassFill: Colors.white,
      glassFillStrong: Colors.white,
      glassBorder: Colors.white,
      glassTintWarm: const Color(0xFFFFE9DD),
      glassTintRose: const Color(0xFFFFE5EB),
      softHighlight: softHighlight,
      softShadow: softShadow,
      cardSoftShadow: const [
        BoxShadow(
          color: Color(0x0F1F1B23),
          blurRadius: 32,
          offset: Offset(0, 12),
        ),
        BoxShadow(
          color: Color(0x0A1F1B23),
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
      ],
      glassFloatingShadow: const [
        BoxShadow(
          color: Color(0x1A1F1B23),
          blurRadius: 50,
          offset: Offset(0, 18),
        ),
        BoxShadow(
          color: Color(0x0D1F1B23),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
      primaryGlowShadow: const [
        BoxShadow(
          color: Color(0x4DFF4D6D),
          blurRadius: 28,
          offset: Offset(0, 12),
        ),
        BoxShadow(
          color: Color(0x33FF4D6D),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
      neumorphicRaisedShadow: [
        BoxShadow(
          color: softHighlight.withValues(alpha: 0.85),
          blurRadius: 14,
          offset: const Offset(-6, -6),
        ),
        BoxShadow(
          color: softShadow.withValues(alpha: 0.55),
          blurRadius: 14,
          offset: const Offset(6, 6),
        ),
      ],
      neumorphicPressedShadow: [
        BoxShadow(
          color: softShadow.withValues(alpha: 0.55),
          blurRadius: 8,
          offset: const Offset(3, 3),
        ),
      ],
      glassBlurSoft: 14,
      glassBlurMedium: 22,
      glassBlurStrong: 32,
      glassFillOpacity: 0.55,
      glassFillOpacityStrong: 0.72,
      glassBorderOpacity: 0.65,
      springDuration: const Duration(milliseconds: 320),
      springCurve: Curves.easeOutCubic,
      pressScale: 0.96,
    );
  }

  /// Dark-mode tokens.
  static VestiqSoftTheme get dark {
    const canvas = Color(0xFF0F0E12);
    const surface = Color(0xFF1A1820);
    const surfaceContainer = Color(0xFF221F29);
    const surfaceContainerHigh = Color(0xFF2B2733);
    const surfaceVariant = Color(0xFF2A2530);
    const outline = Color(0xFF332E3A);
    const outlineSoft = Color(0xFF26222C);

    const primary = Color(0xFFFF4D6D);
    const primarySoft = Color(0xFF3B2A30);
    const onPrimarySoft = Color(0xFFFFC8D2);
    const primaryGlow = Color(0xFFFF8FA3);

    const success = Color(0xFF3DA678);
    const warning = Color(0xFFE8A33C);
    const error = Color(0xFFE5484D);

    const softHighlight = Color(0xFF2B2733);
    const softShadow = Color(0xFF0A090C);

    return VestiqSoftTheme(
      canvas: canvas,
      surface: surface,
      surfaceContainer: surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh,
      surfaceVariant: surfaceVariant,
      outline: outline,
      outlineSoft: outlineSoft,
      primary: primary,
      primarySoft: primarySoft,
      onPrimarySoft: onPrimarySoft,
      primaryGlow: primaryGlow,
      success: success,
      warning: warning,
      error: error,
      glassFill: Colors.white,
      glassFillStrong: Colors.white,
      glassBorder: Colors.white,
      glassTintWarm: const Color(0xFF3B2E2A),
      glassTintRose: const Color(0xFF3B2A30),
      softHighlight: softHighlight,
      softShadow: softShadow,
      cardSoftShadow: const [
        BoxShadow(
          color: Color(0x73000000),
          blurRadius: 40,
          offset: Offset(0, 16),
        ),
        BoxShadow(
          color: Color(0x59000000),
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
      ],
      glassFloatingShadow: const [
        BoxShadow(
          color: Color(0x99000000),
          blurRadius: 60,
          offset: Offset(0, 24),
        ),
        BoxShadow(
          color: Color(0x66000000),
          blurRadius: 10,
          offset: Offset(0, 2),
        ),
      ],
      primaryGlowShadow: const [
        BoxShadow(
          color: Color(0x66FF4D6D),
          blurRadius: 28,
          offset: Offset(0, 12),
        ),
        BoxShadow(
          color: Color(0x33FF4D6D),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
      neumorphicRaisedShadow: [
        BoxShadow(
          color: softHighlight.withValues(alpha: 0.55),
          blurRadius: 14,
          offset: const Offset(-6, -6),
        ),
        BoxShadow(
          color: softShadow.withValues(alpha: 0.85),
          blurRadius: 14,
          offset: const Offset(6, 6),
        ),
      ],
      neumorphicPressedShadow: [
        BoxShadow(
          color: softShadow.withValues(alpha: 0.85),
          blurRadius: 8,
          offset: const Offset(3, 3),
        ),
      ],
      glassBlurSoft: 14,
      glassBlurMedium: 22,
      glassBlurStrong: 32,
      glassFillOpacity: 0.18,
      glassFillOpacityStrong: 0.28,
      glassBorderOpacity: 0.10,
      springDuration: const Duration(milliseconds: 320),
      springCurve: Curves.easeOutCubic,
      pressScale: 0.96,
    );
  }

  @override
  VestiqSoftTheme copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceContainer,
    Color? surfaceContainerHigh,
    Color? surfaceVariant,
    Color? outline,
    Color? outlineSoft,
    Color? primary,
    Color? primarySoft,
    Color? onPrimarySoft,
    Color? primaryGlow,
    Color? success,
    Color? warning,
    Color? error,
    Color? glassFill,
    Color? glassFillStrong,
    Color? glassBorder,
    Color? glassTintWarm,
    Color? glassTintRose,
    Color? softHighlight,
    Color? softShadow,
    List<BoxShadow>? cardSoftShadow,
    List<BoxShadow>? glassFloatingShadow,
    List<BoxShadow>? primaryGlowShadow,
    List<BoxShadow>? neumorphicRaisedShadow,
    List<BoxShadow>? neumorphicPressedShadow,
    double? glassBlurSoft,
    double? glassBlurMedium,
    double? glassBlurStrong,
    double? glassFillOpacity,
    double? glassFillOpacityStrong,
    double? glassBorderOpacity,
    Duration? springDuration,
    Curve? springCurve,
    double? pressScale,
  }) {
    return VestiqSoftTheme(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh ?? this.surfaceContainerHigh,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      outline: outline ?? this.outline,
      outlineSoft: outlineSoft ?? this.outlineSoft,
      primary: primary ?? this.primary,
      primarySoft: primarySoft ?? this.primarySoft,
      onPrimarySoft: onPrimarySoft ?? this.onPrimarySoft,
      primaryGlow: primaryGlow ?? this.primaryGlow,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      glassFill: glassFill ?? this.glassFill,
      glassFillStrong: glassFillStrong ?? this.glassFillStrong,
      glassBorder: glassBorder ?? this.glassBorder,
      glassTintWarm: glassTintWarm ?? this.glassTintWarm,
      glassTintRose: glassTintRose ?? this.glassTintRose,
      softHighlight: softHighlight ?? this.softHighlight,
      softShadow: softShadow ?? this.softShadow,
      cardSoftShadow: cardSoftShadow ?? this.cardSoftShadow,
      glassFloatingShadow: glassFloatingShadow ?? this.glassFloatingShadow,
      primaryGlowShadow: primaryGlowShadow ?? this.primaryGlowShadow,
      neumorphicRaisedShadow:
          neumorphicRaisedShadow ?? this.neumorphicRaisedShadow,
      neumorphicPressedShadow:
          neumorphicPressedShadow ?? this.neumorphicPressedShadow,
      glassBlurSoft: glassBlurSoft ?? this.glassBlurSoft,
      glassBlurMedium: glassBlurMedium ?? this.glassBlurMedium,
      glassBlurStrong: glassBlurStrong ?? this.glassBlurStrong,
      glassFillOpacity: glassFillOpacity ?? this.glassFillOpacity,
      glassFillOpacityStrong:
          glassFillOpacityStrong ?? this.glassFillOpacityStrong,
      glassBorderOpacity: glassBorderOpacity ?? this.glassBorderOpacity,
      springDuration: springDuration ?? this.springDuration,
      springCurve: springCurve ?? this.springCurve,
      pressScale: pressScale ?? this.pressScale,
    );
  }

  @override
  VestiqSoftTheme lerp(ThemeExtension<VestiqSoftTheme>? other, double t) {
    if (other is! VestiqSoftTheme) return this;
    return VestiqSoftTheme(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceContainer:
          Color.lerp(surfaceContainer, other.surfaceContainer, t)!,
      surfaceContainerHigh:
          Color.lerp(surfaceContainerHigh, other.surfaceContainerHigh, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      outlineSoft: Color.lerp(outlineSoft, other.outlineSoft, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      onPrimarySoft: Color.lerp(onPrimarySoft, other.onPrimarySoft, t)!,
      primaryGlow: Color.lerp(primaryGlow, other.primaryGlow, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      glassFillStrong: Color.lerp(glassFillStrong, other.glassFillStrong, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      glassTintWarm: Color.lerp(glassTintWarm, other.glassTintWarm, t)!,
      glassTintRose: Color.lerp(glassTintRose, other.glassTintRose, t)!,
      softHighlight: Color.lerp(softHighlight, other.softHighlight, t)!,
      softShadow: Color.lerp(softShadow, other.softShadow, t)!,
      cardSoftShadow: t < 0.5 ? cardSoftShadow : other.cardSoftShadow,
      glassFloatingShadow:
          t < 0.5 ? glassFloatingShadow : other.glassFloatingShadow,
      primaryGlowShadow: t < 0.5 ? primaryGlowShadow : other.primaryGlowShadow,
      neumorphicRaisedShadow:
          t < 0.5 ? neumorphicRaisedShadow : other.neumorphicRaisedShadow,
      neumorphicPressedShadow:
          t < 0.5 ? neumorphicPressedShadow : other.neumorphicPressedShadow,
      glassBlurSoft: _lerpDouble(glassBlurSoft, other.glassBlurSoft, t),
      glassBlurMedium: _lerpDouble(glassBlurMedium, other.glassBlurMedium, t),
      glassBlurStrong: _lerpDouble(glassBlurStrong, other.glassBlurStrong, t),
      glassFillOpacity:
          _lerpDouble(glassFillOpacity, other.glassFillOpacity, t),
      glassFillOpacityStrong:
          _lerpDouble(glassFillOpacityStrong, other.glassFillOpacityStrong, t),
      glassBorderOpacity:
          _lerpDouble(glassBorderOpacity, other.glassBorderOpacity, t),
      springDuration: t < 0.5 ? springDuration : other.springDuration,
      springCurve: t < 0.5 ? springCurve : other.springCurve,
      pressScale: _lerpDouble(pressScale, other.pressScale, t),
    );
  }

  static double _lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

/// Convenience accessor.
extension VestiqSoftThemeAccess on BuildContext {
  VestiqSoftTheme get vestiqSoft =>
      Theme.of(this).extension<VestiqSoftTheme>() ?? VestiqSoftTheme.light;
}
