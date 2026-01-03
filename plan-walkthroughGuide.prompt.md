## Plan: Friendly Home/Closet Walkthrough

Light, animated, in-product walkthrough that highlights the authenticated home tab and enhanced closet, using overlays/tooltips anchored to existing CTAs and gestures without disrupting Riverpod-driven state.

### Steps
1. Confirm entry & tab flow in lib/main.dart and lib/core/router/app_router.dart to hook walkthrough start post-auth/home load.
2. Identify home tab anchors (hero CTA, quick occasion cards, recent looks, Today’s Picks, wardrobe snapshot, View All) in lib/features/outfit_suggestions/presentation/screens/home_screen.dart for step targets.
3. Map closet anchors (search toggle, favorites, category pills, grid cards, quick actions, add item) in lib/features/wardrobe/presentation/screens/enhanced_closet_screen.dart.
4. Choose overlay pattern (coach marks with blur/dim, arrow, short copy, skip/next, dismiss) and animation timing consistent with lib/core/theme/app_theme.dart gradients/fonts.
5. Define walkthrough state model (Riverpod provider) + persistence (shared prefs/AppSettings) to show once and allow replay from settings; outline event hooks for “Next” navigation across home → closet.
6. Draft concise copy/sequence (3–5 steps per screen), noting gestures (tap/long-press) and existing bottom sheets to avoid conflicts; align with CTA wording already in UI.

### Further Considerations
1. Should start automatically on first post-onboarding login, or only on explicit “Show Tour” tap? Option A auto first-time + replay, Option B manual only.
