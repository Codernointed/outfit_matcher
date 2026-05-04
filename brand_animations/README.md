# Vestiq Brand Animations

Six SVG animations for splash screens, loaders, and brand moments. Open `preview.html` in any browser to see them all running.

## Files

| File | Use |
|---|---|
| `vestiq_splash_full.svg` | Hero splash — full wordmark + fabric Q reveal (~3.2s) |
| `vestiq_fabric_loop.svg` | Loader / spinner — fabric Q swaying forever |
| `vestiq_monogram_morph.svg` | VQ monogram drawing in (icon launch sting) |
| `vestiq_breathing.svg` | Idle ambient — Q with halo pulse, infinite loop |
| `vestiq_outfit_morph.svg` | Story animation — fabric → dress → blouse cross-fade |
| `vestiq_sparkle_burst.svg` | Premium splash — sparkles burst then logo reveals |

## Brand colors used

- Coral pink `#FF6B93`
- Hot pink `#FC4FCB`
- Burgundy `#3A0D23`
- Soft pink `#FFF0F5`
- Ink `#1A1A2C`

## Production paths

The SVGs use CSS keyframe animations and SMIL. They render correctly in any modern browser, and the `flutter_svg` package can render them statically — but Flutter does not execute embedded SVG animations.

For animated playback in the Flutter app, pick one:

1. **Rive (recommended)** — Rebuild the 1–2 animations you ship in [rive.app](https://rive.app). It's Flutter-native, GPU-accelerated, and the files are tiny. Use the SVGs here as visual reference for your designer.
2. **Lottie** — Open the SVG in After Effects (SVG Importer or Overlord plugin), animate, export with Bodymovin to `.json`, render with the `lottie` package.
3. **Hand-coded Flutter** — For simple animations (the breathing icon, the fabric loop), this is fast: an `AnimatedBuilder` over a `flutter_svg` static render. Best for the loader.

## Splash screen pattern (Flutter)

Native launch screens show before Flutter boots, so you need two layers:

1. **Native splash** (`flutter_native_splash` package) → use a static PNG export of the logo. Shown instantly on cold start.
2. **Animated splash widget** → plays once Flutter is up. Use the Rive/Lottie version of `vestiq_splash_full` or `vestiq_sparkle_burst`.

This avoids the white-flash gap users see when only the Flutter widget is used.

## Notes

- All SVGs use Google Fonts (Poppins, Dancing Script). They load fine in browsers; in Flutter you'll bundle the fonts via `pubspec.yaml` instead.
- The fabric Q path is hand-drawn and consistent across all six files — if you tighten it in one, propagate the change.
- Outfit morph uses cross-fade rather than true SVG path morphing for reliability across renderers.
