---
version: alpha
name: Vestiq
description: Soft Glass Hybrid wardrobe assistant. Warm linen canvas, frosted glass surfaces, subtle neumorphic depth, signature petal-pink accent, and spring-physics micro-interactions.

colors:
  # Brand / signature
  primary: "#FF4D6D"
  on-primary: "#FFFFFF"
  primary-soft: "#FFE5EB"
  on-primary-soft: "#7A1A2E"
  primary-glow: "#FF8FA3"

  # Semantic
  success: "#3DA678"
  on-success: "#FFFFFF"
  warning: "#E8A33C"
  on-warning: "#3A2A0E"
  error: "#E5484D"
  on-error: "#FFFFFF"

  # Light surfaces (warm linen canvas + blush variant)
  background: "#F8F6F4"
  surface: "#FFFFFF"
  surface-container: "#FBF7F4"
  surface-container-high: "#F3EDE8"
  surface-variant: "#FAF0EE"
  on-surface: "#1F1B23"
  on-surface-variant: "#7A7480"
  outline: "#E8E1DA"
  outline-soft: "#F0EAE3"

  # Glass (light mode)
  glass-fill: "#FFFFFF"
  glass-fill-strong: "#FFFFFF"
  glass-border: "#FFFFFF"
  glass-tint-warm: "#FFE9DD"
  glass-tint-rose: "#FFE5EB"

  # Neumorphic light source (light mode)
  soft-highlight: "#FFFFFF"
  soft-shadow: "#D9D2CB"

  # Dark surfaces
  background-dark: "#0F0E12"
  surface-dark: "#1A1820"
  surface-container-dark: "#221F29"
  surface-container-high-dark: "#2B2733"
  surface-variant-dark: "#2A2530"
  on-surface-dark: "#F5F1F7"
  on-surface-variant-dark: "#B3ACBA"
  outline-dark: "#332E3A"
  outline-soft-dark: "#26222C"

  # Glass (dark mode)
  glass-fill-dark: "#FFFFFF"
  glass-border-dark: "#FFFFFF"
  glass-tint-warm-dark: "#3B2E2A"
  glass-tint-rose-dark: "#3B2A30"

  # Neumorphic light source (dark mode)
  soft-highlight-dark: "#2B2733"
  soft-shadow-dark: "#0A090C"

typography:
  headline-display:
    fontFamily: Poppins
    fontSize: 32px
    fontWeight: 700
    lineHeight: 1.1
    letterSpacing: -0.03em
  headline-lg:
    fontFamily: Poppins
    fontSize: 24px
    fontWeight: 700
    lineHeight: 1.15
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Poppins
    fontSize: 20px
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: -0.01em
  title-lg:
    fontFamily: Poppins
    fontSize: 18px
    fontWeight: 600
    lineHeight: 1.25
  title-md:
    fontFamily: Poppins
    fontSize: 16px
    fontWeight: 600
    lineHeight: 1.3
  label-lg:
    fontFamily: Poppins
    fontSize: 16px
    fontWeight: 600
    lineHeight: 1.1
    letterSpacing: 0.01em
  label-md:
    fontFamily: Poppins
    fontSize: 14px
    fontWeight: 600
    lineHeight: 1.1
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Poppins
    fontSize: 12px
    fontWeight: 500
    lineHeight: 1.1
    letterSpacing: 0.04em
  body-lg:
    fontFamily: Roboto
    fontSize: 16px
    fontWeight: 400
    lineHeight: 1.55
  body-md:
    fontFamily: Roboto
    fontSize: 14px
    fontWeight: 400
    lineHeight: 1.5
  body-sm:
    fontFamily: Roboto
    fontSize: 12px
    fontWeight: 400
    lineHeight: 1.45
  caption:
    fontFamily: Roboto
    fontSize: 11px
    fontWeight: 500
    lineHeight: 1.3
    letterSpacing: 0.04em

rounded:
  none: 0px
  xs: 8px
  sm: 12px
  md: 16px
  lg: 20px
  xl: 24px
  2xl: 28px
  pill: 999px
  full: 9999px

spacing:
  unit: 8px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  2xl: 48px
  3xl: 64px
  screen-padding: 20px
  card-padding: 20px
  card-gap: 16px
  section-gap: 28px
  tile-gap: 12px

elevation:
  flush: 0
  raised: 1
  floating: 2
  hover: 3

glass:
  blur-sigma-soft: 14
  blur-sigma-medium: 22
  blur-sigma-strong: 32
  fill-opacity-light: 0.55
  fill-opacity-light-strong: 0.72
  fill-opacity-dark: 0.18
  fill-opacity-dark-strong: 0.28
  border-opacity-light: 0.65
  border-opacity-dark: 0.10
  highlight-opacity: 0.85
  tint-opacity: 0.45

shadows:
  card-soft-light: "0px 12px 32px rgba(31, 27, 35, 0.06), 0px 2px 6px rgba(31, 27, 35, 0.04)"
  card-soft-dark: "0px 16px 40px rgba(0, 0, 0, 0.45), 0px 2px 6px rgba(0, 0, 0, 0.35)"
  glass-floating-light: "0px 18px 50px rgba(31, 27, 35, 0.10), 0px 2px 8px rgba(31, 27, 35, 0.05)"
  glass-floating-dark: "0px 24px 60px rgba(0, 0, 0, 0.60), 0px 2px 10px rgba(0, 0, 0, 0.40)"
  primary-glow: "0px 12px 28px rgba(255, 77, 109, 0.30), 0px 4px 10px rgba(255, 77, 109, 0.20)"
  neumorphic-raised-light: "-6px -6px 14px rgba(255, 255, 255, 0.85), 6px 6px 14px rgba(217, 210, 203, 0.55)"
  neumorphic-pressed-light: "inset -3px -3px 8px rgba(255, 255, 255, 0.85), inset 3px 3px 8px rgba(217, 210, 203, 0.55)"
  neumorphic-raised-dark: "-6px -6px 14px rgba(43, 39, 51, 0.55), 6px 6px 14px rgba(10, 9, 12, 0.85)"
  neumorphic-pressed-dark: "inset -3px -3px 8px rgba(43, 39, 51, 0.55), inset 3px 3px 8px rgba(10, 9, 12, 0.85)"

motion:
  duration-instant: "0ms"
  duration-fast: "120ms"
  duration-standard: "200ms"
  duration-medium: "320ms"
  duration-slow: "480ms"
  duration-page: "600ms"
  duration-ambient: "1500ms"
  easing-standard: "easeOutCubic"
  easing-emphasized: "cubicBezier(0.2, 0.8, 0.2, 1)"
  easing-spring-soft: "spring(stiffness: 280, damping: 22)"
  easing-spring-snappy: "spring(stiffness: 380, damping: 24)"
  easing-spring-bouncy: "spring(stiffness: 220, damping: 16)"
  press-scale: 0.96
  hover-lift: 1.02

components:
  app:
    backgroundColor: "{colors.background}"
    textColor: "{colors.on-surface}"
    typography: "{typography.body-md}"

  appbar:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface}"
    typography: "{typography.title-md}"
    rounded: "{rounded.none}"

  appbar-glass:
    backgroundColor: "{colors.glass-fill}"
    textColor: "{colors.on-surface}"
    typography: "{typography.title-md}"
    rounded: "{rounded.none}"

  divider:
    backgroundColor: "{colors.outline-soft}"
    height: 1px

  card-glass:
    backgroundColor: "{colors.glass-fill}"
    textColor: "{colors.on-surface}"
    rounded: "{rounded.lg}"
    padding: "{spacing.card-padding}"
    elevation: "{elevation.floating}"

  card-soft:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface}"
    rounded: "{rounded.lg}"
    padding: "{spacing.card-padding}"
    elevation: "{elevation.raised}"

  card-soft-recessed:
    backgroundColor: "{colors.surface-container}"
    textColor: "{colors.on-surface}"
    rounded: "{rounded.lg}"
    padding: "{spacing.card-padding}"
    elevation: "{elevation.flush}"

  hero-tile:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface}"
    rounded: "{rounded.xl}"
    padding: "{spacing.lg}"
    elevation: "{elevation.floating}"

  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    typography: "{typography.label-lg}"
    rounded: "{rounded.md}"
    height: 56px
    padding: "0 24px"
  button-primary-pressed:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"

  button-soft:
    backgroundColor: "{colors.surface-container}"
    textColor: "{colors.on-surface}"
    typography: "{typography.label-lg}"
    rounded: "{rounded.md}"
    height: 56px
    padding: "0 24px"

  button-glass:
    backgroundColor: "{colors.glass-fill}"
    textColor: "{colors.on-surface}"
    typography: "{typography.label-lg}"
    rounded: "{rounded.md}"
    height: 56px
    padding: "0 24px"

  button-text:
    backgroundColor: "{colors.background}"
    textColor: "{colors.primary}"
    typography: "{typography.label-md}"
    rounded: "{rounded.sm}"
    padding: "{spacing.sm}"

  chip:
    backgroundColor: "{colors.surface-container}"
    textColor: "{colors.on-surface}"
    typography: "{typography.label-md}"
    rounded: "{rounded.pill}"
    padding: "8px 14px"
    height: 36px
  chip-selected:
    backgroundColor: "{colors.primary-soft}"
    textColor: "{colors.on-primary-soft}"
    typography: "{typography.label-md}"
    rounded: "{rounded.pill}"

  badge-count:
    backgroundColor: "{colors.primary-soft}"
    textColor: "{colors.on-primary-soft}"
    typography: "{typography.caption}"
    rounded: "{rounded.pill}"
    padding: "2px 8px"

  input-field:
    backgroundColor: "{colors.surface-container}"
    textColor: "{colors.on-surface}"
    typography: "{typography.body-md}"
    rounded: "{rounded.md}"
    padding: "{spacing.md}"
    height: 56px

  sheet-glass:
    backgroundColor: "{colors.glass-fill}"
    textColor: "{colors.on-surface}"
    rounded: "{rounded.2xl}"
    padding: "{spacing.lg}"
    elevation: "{elevation.hover}"

  bottom-nav-glass:
    backgroundColor: "{colors.glass-fill}"
    textColor: "{colors.on-surface}"
    rounded: "{rounded.2xl}"
    padding: "8px"
    height: 64px
    elevation: "{elevation.hover}"
  bottom-nav-item-active:
    backgroundColor: "{colors.primary-soft}"
    textColor: "{colors.primary}"
    rounded: "{rounded.pill}"

  fab-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    rounded: "{rounded.pill}"
    size: 56px
    elevation: "{elevation.hover}"

  drag-handle:
    backgroundColor: "{colors.outline}"
    rounded: "{rounded.pill}"
    width: 40px
    height: 4px
---

## Overview

Vestiq is **Soft Glass Hybrid** -- a calm, warm, fashion-forward surface language that blends three modern design ideas:

1. **Glassmorphism 2.0** -- frosted, translucent panels with variable blur and a 1px luminous border, used for floating elements (sheets, nav, app bar, hero overlays).
2. **Subtle neumorphism** -- soft dual-shadow surfaces that look gently extruded from or pressed into the canvas, used **sparingly** for tactile controls (buttons, toggles, chips, input wells).
3. **Tactile micro-interactions** -- spring-physics press feedback, scale "squish," and ambient shimmer that make every tap feel alive.

The brand voice is **premium stylist + caring wingman**: warm, confident, supportive, never clinical. Screens should feel like opening a beautifully lit boutique mirror -- bright, calm, with subtle depth that draws the eye toward the next styling decision.

Avoid: harsh drop shadows, pure-white-on-pure-white flat panels, sharp 8px corners, neon saturation, and over-blurred glass that competes with photography.

## Colors

The palette is anchored on a **warm linen canvas** (`#F8F6F4`) -- not pure white -- so that white surfaces, glass cards, and clothing photography naturally pop. Color usage is restrained: most screens are neutral, with a single petal-pink accent for the primary action and a small set of semantic colors for feedback.

- **Primary -- Petal Pink (`#FF4D6D`)**: the signature CTA and brand mark color. Used for the dominant action per screen, key highlights, focus rings, and the active nav indicator. Pair with **Petal Pink Soft (`#FFE5EB`)** for badges, chips, and selected states so the accent breathes instead of shouts.
- **Primary Glow (`#FF8FA3`)**: a lighter rose used inside colored glow shadows and gradient washes behind hero CTAs.
- **Background -- Warm Linen (`#F8F6F4`)**: the default canvas. Soft, slightly warm, removes the clinical feel of stark white.
- **Surface -- Pure White (`#FFFFFF`)**: cards, sheets, photographic frames. Always paired with a soft shadow so it lifts off the canvas.
- **Surface Container -- Cream (`#FBF7F4`)** and **Surface Container High -- Sand (`#F3EDE8`)**: tonal layers used for chips, recessed input wells, and grouping without borders.
- **Surface Variant -- Blush (`#FAF0EE`)**: the warmest tonal layer; used for secondary panels and brand-leaning sections.
- **On-surface -- Plum Ink (`#1F1B23`)**: primary text. Slightly violet-warm so it harmonizes with blush accents instead of feeling like cold black.
- **On-surface Variant -- Mist (`#7A7480`)**: secondary text, helper copy, placeholders.
- **Outline / Outline Soft (`#E8E1DA` / `#F0EAE3`)**: hairline dividers and chip strokes. Almost invisible by design.
- **Glass tints**: warm and rose tints layered behind frosted panels add subtle color depth without hurting legibility.
- **Semantic colors** (`success`, `warning`, `error`) are slightly desaturated so they feel like part of the system rather than browser-default alerts.

Dark mode mirrors the structure with deeper plum-ink surfaces (`#0F0E12` canvas, `#1A1820` surface). Glass on dark uses a higher-opacity white fill (28%) and a thinner border (10%) to keep frosted panels legible against low-light photography.

## Typography

Two families, used together by design.

- **Poppins** for headings, titles, button labels, chip labels -- confident editorial voice. Bold weights drive hierarchy; tight negative letter-spacing on display sizes makes them feel typographically modern.
- **Roboto** for body and helper copy -- highly legible at small sizes, with generous line-height (1.5-1.55) so wardrobe descriptions and AI suggestions read like a stylist's note instead of a database row.

Hierarchy levels:

- `headline-display` (32px): used once per screen on hero moments only.
- `headline-lg` / `headline-md` (24px / 20px): screen titles and section heroes.
- `title-lg` / `title-md` (18px / 16px): card titles, list section headers.
- `label-lg` / `label-md` / `label-sm`: button labels, chip labels, metadata. Slight positive letter-spacing (0.01-0.04em) makes them feel intentional and "uppercase-adjacent" without shouting.
- `body-lg` / `body-md` / `body-sm`: paragraphs, helper copy, item descriptions.
- `caption`: timestamps, count badges, footnotes.

Never use more than two type families on a single screen. Never use more than two Poppins weights on a single screen.

## Layout

The layout system is a **calm 8px rhythm** with optical alignment. Visual balance trumps strict mathematical grid snapping.

- **Screen padding**: 20px horizontal -- slightly more generous than Material's 16px to feel airy and premium.
- **Section gap**: 28px between distinct content groupings (e.g., "Today's Look" vs "Your Closet").
- **Card gap**: 16px between cards inside a group.
- **Tile gap**: 12px inside dense grids (closet item grid, mood tiles).
- **Touch targets**: minimum 48x48 logical pixels; primary buttons are 56px tall and full-width for unmistakable affordance.
- **Bento moments**: at least one screen per major flow (home, closet, profile) should feature a Bento-style modular row -- one hero tile (full-width or 2x1) flanked by smaller stat or shortcut tiles. This breaks up linear scrolling and gives the UI editorial rhythm.

## Elevation & Depth

Depth is **never** achieved with hard drop shadows. Three layers stack from canvas to overlay:

1. **Canvas (Layer 0)**: warm linen background. No shadow, no border.
2. **Surface (Layer 1)**: white cards lifted with `card-soft-light` -- a very large, very soft ambient shadow plus a tiny contact shadow. This creates the "premium photo book" feel.
3. **Floating (Layer 2)**: glass panels (sheets, nav, app bar). These use `BackdropFilter` blur (sigma 14-22), a translucent fill (55-72% white in light mode), and a 1px luminous white border at 65% opacity to simulate light catching the glass edge.

Neumorphic depth (raised + pressed) is reserved for **interactive controls**:

- Buttons, toggles, and chips can use `neumorphic-raised-*` shadow tokens to look extruded from the surface they sit on.
- On press, the same control transitions to `neumorphic-pressed-*` (inset shadow) plus a 0.96x scale-down for visual haptics.

Shadow rules:

- One light source per screen, top-left.
- Never stack more than one elevation level on a single element.
- Glass effects are expensive; cap at 3-5 frosted surfaces per screen and never inside scrolling lists.

## Shapes

Corners are **consistently soft**. The shape language reads as friendly and tactile across the entire app.

- **Buttons, inputs, small cards**: 16px (`rounded.md`) -- the default for interactive surfaces.
- **Cards, hero tiles**: 20-24px (`rounded.lg` / `rounded.xl`) -- generous, photographic.
- **Sheets, nav bar, modals**: 28px (`rounded.2xl`) -- the most generous radius, reserved for floating chrome.
- **Chips, badges, FABs, drag handles, pill indicators**: 999px (`rounded.pill`).

Never mix sharp corners with rounded ones in the same view. Never use `rounded.xs` (8px) for cards or buttons -- it's reserved for dense data chips and inline tags only.

## Components

### Glass cards (`card-glass`)
The primary container for floating content. Uses a `ClipRRect` + `BackdropFilter(blur)` + semi-transparent fill + 1px luminous border. Configurable blur sigma (14 soft, 22 medium, 32 strong). Use medium blur by default; soft blur for content cards that should let imagery show through.

### Soft cards (`card-soft`, `card-soft-recessed`)
For non-floating content. White surface with `card-soft-light` shadow for raised cards; cream surface with no shadow for recessed/grouped cards.

### Buttons
- `button-primary`: solid Petal Pink fill, white label, soft pink glow shadow (`primary-glow`). Spring-physics press: scale to 0.96, 200ms, easing `spring-snappy`.
- `button-soft`: cream fill, on-surface label. Used for secondary actions sitting next to a primary button.
- `button-glass`: frosted glass fill with luminous border. Used over photography or busy backgrounds.
- `button-text`: pink label only, minimal padding. For tertiary inline actions.

All buttons use `AnimatedPressable` wrapper for tactile feedback.

### Chips
Pill-shaped (`rounded.pill`), 36px tall. Selected state uses `primary-soft` fill with `on-primary-soft` text -- no harsh primary fill on chips, ever.

### Input fields
**Soft recessed wells**: cream `surface-container` fill, no border by default, 16px radius. On focus: a 2px Petal Pink ring with a subtle glow. On error: error-color ring. Never use outlined inputs.

### Bottom sheets (`sheet-glass`)
Always frosted glass. Top corners 28px. A 40x4px pill drag handle in `outline` color sits 8px from the top edge. The sheet floats above a 30-50% black scrim with backdrop blur of sigma 14.

### Bottom navigation (`bottom-nav-glass`)
Floating glass island, 64px tall, 28px radius, 16px outer margin so it doesn't touch screen edges. Active item uses `bottom-nav-item-active` -- a `primary-soft` pill with the icon and label in primary pink. Inactive items use `on-surface-variant`. Selected state animates with a 320ms `easing-emphasized` spring.

### App bar
Two variants:
- `appbar` (default): solid surface, no elevation. Used on settings-style screens.
- `appbar-glass`: frosted glass, used on screens where content scrolls beneath (home, closet, profile).

### FAB
Pill-shaped, 56px, primary color, with primary glow shadow. Floats 24px above the bottom nav.

### Badge / count
`primary-soft` pill background, on-primary-soft text, caption typography. Never red, never solid primary.

### Drag handle
A 40x4px pill in `outline` color, centered 8px below the top of any sheet.

## Do's and Don'ts

- **Do** use the warm linen canvas as the default background. Pure white is for cards and floating chrome only.
- **Do** keep glass effects on overlays, sheets, nav, and hero cards -- never inside scrolling lists.
- **Do** apply `AnimatedPressable` to every interactive element for visual haptics.
- **Do** use one Petal Pink primary action per screen. Use Petal Pink Soft for everything else that needs accent.
- **Do** stick to one light source (top-left) for all neumorphic shadows on a screen.
- **Do** use Bento-style modular rows once per major screen for editorial rhythm.

- **Don't** use `BorderRadius.circular(8)` on cards, buttons, or sheets -- it reads as 2020-era Material.
- **Don't** stack hard drop shadows. One ambient soft shadow plus an optional 1px luminous border is the maximum.
- **Don't** mix neumorphic and glassmorphic styles on the same atomic element. A glass card can contain neumorphic buttons inside it -- that's fine. But a single button shouldn't be both glass and neumorphic.
- **Don't** animate `BackdropFilter.sigmaX/sigmaY` -- it's expensive. Animate scale, opacity, and color instead.
- **Don't** introduce additional saturated brand colors without a system-wide rationale.
- **Don't** use Material's default `elevation` integers -- depth comes from the custom shadow tokens above.
