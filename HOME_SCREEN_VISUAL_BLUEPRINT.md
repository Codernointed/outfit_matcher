# 🎨 Home Screen Visual Blueprint
## Premium, Elegant UX Design Specification

---
## Home Screen Vision

Lets complete the home screen, pages subapages, beacuse over here @home_screen.dart only add item to wardrobe is working. In this section, I will be talking about the Quick Outfit Ideas, Recent Generations, Today's Picks, see all, View All, Your Wardrobe, and everything in the home screen. I want to make them work, so let's plan on what things should be where, how should they be, what are they, let's plan, let's brainstorm how everything is going to look like before we start. So, really good, deep, really detailed, really full of best UI modding, very premium, very elegant UX view of a perfect features of the home screen.the search and brightness too

@README.md @plan.md @this-app-rules.md 
### Structure Overview
the what would you linke to wear is enough,  dont add anything yet there
- **Quick Outfit Ideas**
  - Four cards (Casual, Work, Date, Party already exist) → tapping opens filtered pairing sheet
  - Badge for current trending or “new suggestions available”
  - Long‑press opens “Customize mood” modal (tone, palette, confidence){make it work nd perfect)

- **Recent Generations**
  - Horizontal carousel of saved looks (mannequin or collage fallback)
  - Each card: look name, items summary, tight/loose badge, favorite toggle, share icon(exist) just align well, and prevent overflow and more
  - CTA “View All” ⇒ full looks library with filters (occasion, score, saved vs generated)
  - Empty state: friendly prompt with “Generate your first look” CTA

- **Today’s Picks**
  - Horizontal cards with auto-curated outfits for current day
  - Two tabs: `For Today`, `For Tonight`(make it perfect)
  - Each card shows match score, weather badge, quick actions (Wear, Save, Swap item)
  - Pull-to-refresh rerolls suggestions; uses wardrobe data + context

- **Your Wardrobe**
  - Vertical grid snippet (2 rows) showing polished thumbnails
  - Tap “View All” opens `EnhancedClosetScreen`
  - Each tile includes category chip, wear count, quick actions (Pair, Surprise, Delete)
  - Footer CTA “Upload more” when collection is small

- **Search & Brightness Strip**
  - Search bar (placeholder: “Search wardrobe, outfits, inspirations…”)
  - Voice input mic icon
  - Filters shortcut (occasion, season, color)
  - Brightness/Sun icon toggles between light/premium dusk theme (with toast feedback)

### UX & Visual Treatment
- **Premium Look**
  - Soft gradients, glassmorphism overlays, rounded 20px cards, subtle shadows
  - Motion: hero fades in, cards slide, micro haptics on interactions
  - Typography: title weights 600, body 400, accent color from theme palette

- **Interaction Details**
  - Cards respond with parallax on scroll
  - Quick Outfit cards cycle with horizontal swipe + indicator
  - Long-press on saved look opens action sheet (View, Save copy, Edit notes, Delete)
  - Swipe down anywhere to refresh entire dashboard (animated progress arc)

- **States & Feedback**
  - Skeletons for loading (shimmer placeholders)
  - Offline mode shows cached data + banner
  - Empty states with illustrations, contextual prompts
  - Error snackbars with retry buttons and AppLogger logs

### Data & Integration
- **Data Sources**
  - `OutfitStorageService` for saved looks
  - `EnhancedWardrobeStorageService` for items
  - `WardrobePairingService` for “Today’s Picks”
  - Search uses combined index (items + looks + inspiration)

- **Search Scope**
  - Items (by type, color, tags)
  - Saved outfits (by title, occasion)
  - Inspiration (Phase 2 linking to visual search)
  - Autocomplete suggestions (recent, top terms)

- **Context Awareness**
  - Weather API to adjust Today’s Picks
  - Calendar integration for upcoming events badge
  - Wear history to rotate underused items

### Navigation Hooks
- Quick Outfit Ideas → opens interactive pairing sheet in corresponding mode
- Recent Generations → detail screen with mannequin preview + notes
- Today’s Picks → same pairing sheet with preselected outfit (editable)
- Wardrobe tiles → `showWardrobeItemPreview`
- Search results → deep links into item/ look / inspiration screens

### Analytics & Personalization
- Track impressions & taps per section
- Log which suggestions are saved/worn
- Feed into style profile to improve future picks
- A/B testing: different card layouts, CTA wording

### Technical Plan
- Create `HomeViewModel` (Riverpod) aggregating:
  - `quickIdeasProvider`, `recentLooksProvider`, `todaysPicksProvider`, `wardrobeSnapshotProvider`
- Implement `HomeLoadingState`, `HomeReadyState`, `HomeErrorState`
- Build modular widgets: `QuickIdeasRow`, `RecentLooksCarousel`, `TodaysPicksList`, `WardrobeGrid`
- Search implementation:
  - Text controller, debounced query stream
  - Results screen with tabs (Items, Looks, Inspiration)
  - Voice input via `speech_to_text` (optional phase)

### Action Items
1. Finalize visual specs (spacing, colors, icons)
2. Define providers & caching window
3. Implement search bar + filters + voice trigger
4. Build each section widget with empty/loading states
5. Wire navigation to existing screens/flows
6. Add analytics instrumentation (AppLogger + Firebase)
7. QA on small/large wardrobes, empty states, offline
8. Iterate on theme toggle animation

I approve, let do it

## Home Screen Upgrade — Implementation Blueprint  

We’ll deliver the vision in six modular workstreams so each section is premium, resilient, and fully connected to the wardrobe/pairing stack. Below is the build plan before any code moves.

---

### 1. Home State Architecture (`home-setup`)  
**Goal:** Centralize all data so UI stays responsive, cached, and ready for offline.

| Provider | Responsibility | Data Source | Refresh Policy |
|----------|----------------|-------------|----------------|
| `quickIdeasProvider` | Available modes + “new/trending” badge state | static list + `WardrobePairingService` feedback | Manual (when cues change) |
| `recentLooksProvider` | Latest saved outfits with images, metadata | `OutfitStorageService.fetchAll()` | Refresh on save/delete + pull-to-refresh |
| `todaysPicksProvider` | Two sets: Today (tight), Tonight (looser) | `WardrobePairingService.generatePairings()` | Generated on load; reroll on pull-down |
| `wardrobeSnapshotProvider` | 4–6 polished wardrobe items | `EnhancedWardrobeStorageService.getWardrobeItems()` | Refresh on upload/edit |
| `homeThemeProvider` | Light / dusk toggle state | local storage (app settings) | Persist across sessions |
| `homeSearchHistoryProvider` | Last 6 search terms | local storage | Updated per search |

**State classes**

```dart
sealed class HomeState { const HomeState(); }
class HomeLoading extends HomeState {}
class HomeReady extends HomeState {
  final QuickIdeasState quickIdeas;
  final RecentLooksState recentLooks;
  final TodaysPicksState todaysPicks;
  final WardrobeSnapshotState wardrobe;
  final ThemeMode themeMode;
  const HomeReady({required this.quickIdeas, ...});
}
class HomeError extends HomeState {
  final String message;
  final VoidCallback? retry;
}
```

Each sub-state carries:
- `items` (data)
- `isLoading`
- `errorMessage`
- Optional analytics context (e.g. impressions logged already)

**HomeViewModel responsibilities**
- Combine provider values into `HomeState`
- Expose commands: `refresh()`, `rerollToday()`, `toggleTheme()`, `runSearch(query)`, `logSectionView(sectionId)`

---

### 2. Quick Outfit Ideas (`home-quick-ideas`)  
**UI spec**
- 4 cards (Casual, Work, Date, Party)
- Soft gradient backgrounds, icon w/ subtle animation
- Badge in top-right: e.g. “New ✨” when new suggestions available (based on `quickIdeasProvider` flag)

**Interactions**
- **Tap:** open pairing sheet pre-filtered with `PairingMode.surpriseMe` + `occasion`
- **Long-press:** open `Customize mood` modal

**Customize Mood modal**
- Sliders / toggles:
  - Tone (Relaxed ↔ Polished)
  - Palette (Neutral, Vibrant, Monochrome)
  - Confidence level (Safe, Balanced, Bold)
- “Apply” triggers `WardrobePairingService` with weights → new set of pairing seeds (logged by analytics)

**Implementation notes**
- Use `showModalBottomSheet` with frosted glass background
- Persist last mood choice per occasion in provider
- Add AppLogger entries for each action

---

### 3. Recent Generations (`home-recent`)  
**Layout**
- `SizedBox(height: 220)` w/ `PageView` or horizontal `ListView`
- Card width ~160, border radius 20, drop shadow
- Image area 60% (try `AspectRatio 4:5`)
- Fallback grid when no mannequin image (reuse helper from earlier)
- Info: title, items count, tight/loose badge pill, timestamp (“Today”, “2d ago”)
- Action row: heart toggle, share icon (already there), ellipsis for more actions

**Interactions**
- Tap card → saved look detail screen (mannequin preview + tips)
- Heart → toggles favorite (persist using `OutfitStorageService` or new flag field)
- Share → share sheet w/ base64 image or text fallback
- `View All` → push to `SavedLooksScreen` (create if missing) with filters for `tight`, `loose`, `occasion`, `score`

**Overflow fixes**
- Replace `Expanded` combos with fixed `SizedBox`
- Use `Flexible` text & `maxLines: 2`
- Add `LayoutBuilder` to adjust font sizes

**Empty State**
- Card with custom illustration + CTA button “Generate your first look” (launch `showInteractivePairingSheet`)

---

### 4. Today’s Picks (`home-today-picks`)  
**Two-tab control**
- `SegmentedButton` or custom pill switch “For Today” / “For Tonight”
- Animated indicator (slide)

**Cards (horiz scroll)**
- Show hero item thumb + supporting items (mini stacked avatars)
- Weather chip (°C + icon) from new `WeatherService`
- Match score progress bar (tight > 0.75, loose > 0.5)
- Action buttons:
  - `Wear now` (marks as worn, increments wear count, logs event)
  - `Save look` (stores as `SavedOutfit` with metadata)
  - `Swap item` (show bottom drawer listing alternatives — re-run pairing replacing one slot)

**Pull-to-refresh**
- `RefreshIndicator` already wrapping — tie to provider call `rerollToday()`
- Add subtle confetti/delight when new set appears (optional)

**Error fallback**
- If pairing fails or only 1 item in wardrobe, show styling tips list with hero item

---

### 5. Your Wardrobe Snapshot (`home-wardrobe`)  
**Grid preview**
- `SliverGrid` or `GridView` inside `SizedBox(height: 220)`
- 2 rows, 3 columns (auto shrink for small data)
- Each tile:
  - Polished image (rounded 16, drop shadow)
  - Overlay gradient bottom with:
    - Category chip (Top, Bottom…)
    - Wear count (icon + text)
  - Floating quick action bar on hover/long-press: Pair, Surprise, Delete (matching quick actions sheet)

**Footer CTA**
- If `<6 items`: show dashed “Upload more items” card linking to upload flow
- `View All` → push `EnhancedClosetScreen` (maybe preset to relevant tab)

---

### 6. Search & Theme Strip (`home-search-theme`)  
**Bar content**
- Rounded 20 `TextField` with glass effect
- Prefix icon (magnifying glass)
- Placeholder “Search wardrobe, outfits, inspirations…”
- Suffix cluster:
  - Mic icon (voice search) – stub for now, display snackbar or permission request
  - Filter icon (opens bottom sheet with occasion/season/color checkboxes)
  - Sun/moon icon toggling theme (light ↔ dusk). Use `AppTheme.getDarkTheme()`, persist via `homeThemeProvider`.

**Search flow**
- On submit: push `HomeSearchResultsScreen` (new) with `TabBar` (`Items`, `Looks`, `Inspiration`)
- Items tab: list of tiles linking to item preview
- Looks tab: use existing saved looks
- Inspiration tab: stub now, later integrate with visual search providers
- Maintain search history chips below bar (scrollable row, `homeSearchHistoryProvider`)

---

### 7. UX / Visual Enhancements  
- Apply soft gradient background to hero container only per user request (“What would you like to wear…” remains only text)
- Add parallax effect to cards on scroll (use `Transform.translate`)
- Implement `RefreshIndicator` custom shape (animated arc)
- Loading skeletons using `Shimmer` (if not already in project)
- Offline banner: show at top when connection lost (monitor via connectivity service)

---

### 8. Analytics & Logging  
- Add AppLogger events for section impressions, taps, saved look, theme swap, search
- Hook into Firebase/Mixpanel later; for now wrap with `homeAnalyticsService?.track…`

---

### 9. Execution Plan  
1. **Refactor state**  
   - Create `home_providers.dart` with Riverpod notifiers  
   - Implement models & caching (SharedPreferences / in-memory)

2. **Update `home_screen.dart`**  
   - Replace ad-hoc methods with modular widgets using states  
   - Add new `HomeSearchBar`, `QuickOutfitIdeasRow`, `RecentGenerationsCarousel`, `TodaysPicksSection`, `WardrobeSnapshotGrid`

3. **Navigation wiring**  
   - Create `SavedLooksScreen`, `HomeSearchResultsScreen` if missing  
   - Ensure `EnhancedClosetScreen` navigation uses `Navigator.push`

4. **Services**  
   - Optional: add `WeatherService`, hooking to `todaysPicksProvider`  
   - Persist favorites in `OutfitStorageService` (extend model with bool)  

5. **Theme toggle**  
   - Extend `AppTheme` to expose dusk theme (reuse `getDarkTheme`)  
   - Update `main.dart` to listen to theme provider (wrap `MaterialApp` in `Consumer`)

6. **Testing & QA**  
   - Write widget tests for each section  
   - Validate with empty wardrobe / no saved looks / offline scenarios  
   - Check overflow on small devices

---

With this blueprint locked, we can start implementing the providers & modular widgets step-by-step, ensuring each area is premium, responsive, and deeply integrated with the rest of the app.
## 🌟 Design Philosophy

**Core Principles:**
- **Minimalism with Purpose**: Every element serves a function
- **Soft, Breathable Spacing**: 20px base unit for consistency
- **Subtle Depth**: Shadows and gradients create hierarchy without noise
- **Fluid Motion**: Micro-animations guide attention naturally
- **Touch-Friendly**: 48px minimum touch targets
- **Premium Materials**: Glassmorphism, soft gradients, rounded edges

---

## 📐 Layout Structure

```
┌─────────────────────────────────────────┐
│  AppBar                                  │  56px
│  ┌─────────────────────┬──────┬──────┐ │
│  │ Search Bar          │ 🔆   │ 🔔   │ │
│  └─────────────────────┴──────┴──────┘ │
├─────────────────────────────────────────┤
│                                          │
│  [Hero Section]                          │  180px
│  "What would you like to wear today?"    │
│  [Add Item to Wardrobe CTA]              │
│                                          │
├─────────────────────────────────────────┤
│                                          │
│  Quick Outfit Ideas                      │  140px
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐  │
│  │Casual│ │ Work │ │ Date │ │Party │  │
│  └──────┘ └──────┘ └──────┘ └──────┘  │
│                                          │
├─────────────────────────────────────────┤
│                                          │
│  Recent Generations     [View All →]    │
│  ┌─────────────────────────────────┐   │  240px
│  │ ┌────┐ ┌────┐ ┌────┐ ┌────┐    │   │
│  │ │Look│ │Look│ │Look│ │Look│... │   │
│  │ └────┘ └────┘ └────┘ └────┘    │   │
│  └─────────────────────────────────┘   │
│                                          │
├─────────────────────────────────────────┤
│                                          │
│  Today's Picks                           │
│  ┌──────────┬──────────┐               │  260px
│  │For Today │For Tonight│   (Tabs)     │
│  └──────────┴──────────┘               │
│  ┌─────────────────────────────────┐   │
│  │ ┌────┐ ┌────┐ ┌────┐         │   │
│  │ │Pick│ │Pick│ │Pick│ ...     │   │
│  │ └────┘ └────┘ └────┘         │   │
│  └─────────────────────────────────┘   │
│                                          │
├─────────────────────────────────────────┤
│                                          │
│  Your Wardrobe          [View All →]    │
│  ┌─────┬─────┬─────┐                   │  280px
│  │Item │Item │Item │                   │
│  ├─────┼─────┼─────┤                   │
│  │Item │Item │Item │                   │
│  └─────┴─────┴─────┘                   │
│  [Upload More Items]                    │
│                                          │
└─────────────────────────────────────────┘
│  Dynamic Island Nav Bar                  │  80px
└─────────────────────────────────────────┘
```

---

## 🎯 Section 1: Enhanced Search Bar

### Visual Design
```
┌─────────────────────────────────────────────────────────┐
│ 🔍  Search wardrobe, outfits, inspirations...  🎤 🎛️ 🔆 │
└─────────────────────────────────────────────────────────┘
```

**Specifications:**
- **Height**: 48px
- **Background**: `rgba(255, 255, 255, 0.95)` with backdrop blur 10px
- **Border**: 1px solid `rgba(0, 0, 0, 0.08)`
- **Border Radius**: 24px (pill shape)
- **Padding**: 16px horizontal
- **Shadow**: `0 2px 8px rgba(0, 0, 0, 0.04)`

**Icons (Right Side):**
1. **🎤 Mic Icon** (Voice Search)
   - Size: 20px
   - Color: Primary color
   - Tap: Show "Voice search coming soon" snackbar
   - Ripple effect on tap

2. **🎛️ Filter Icon** (Advanced Filters)
   - Size: 20px
   - Color: Primary color
   - Tap: Open `SearchFilterSheet` (bottom sheet)
   - Badge dot (red) when filters active

3. **🔆 Sun/Moon Icon** (Theme Toggle)
   - Size: 22px
   - Color: Amber (sun) / Indigo (moon)
   - Tap: Toggle theme with animation
   - Toast: "Switched to dark mode" / "Switched to light mode"
   - Smooth 300ms transition

**Behavior:**
- Tap: Navigate to `HomeSearchResultsScreen`
- Keyboard opens with autofocus
- Show recent search history chips below (horizontal scroll)

**Search History Chips:**
```
┌────────┐ ┌──────┐ ┌─────────┐
│ jeans  │ │ red  │ │ casual  │ ...
└────────┘ └──────┘ └─────────┘
```
- Max 6 recent searches
- Clear button (X) on each chip
- Tap chip: Perform search

---

## 🎯 Section 2: Quick Outfit Ideas

### Visual Design
```
Quick Outfit Ideas                              [Trending ✨]

┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│              │ │              │ │              │ │              │
│   🏖️         │ │   💼         │ │   💖         │ │   🎉         │
│              │ │              │ │              │ │              │
│   Casual     │ │    Work      │ │    Date      │ │   Party      │
│              │ │              │ │              │ │              │
└──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘
```

**Card Specifications:**
- **Size**: 110px × 110px
- **Border Radius**: 20px
- **Background**: Soft gradient per occasion
  - Casual: `linear-gradient(135deg, #E3F2FD 0%, #BBDEFB 100%)`
  - Work: `linear-gradient(135deg, #F3E5F5 0%, #E1BEE7 100%)`
  - Date: `linear-gradient(135deg, #FCE4EC 0%, #F8BBD0 100%)`
  - Party: `linear-gradient(135deg, #FFF3E0 0%, #FFE0B2 100%)`
- **Border**: 1px solid matching color (20% opacity)
- **Shadow**: `0 4px 12px rgba(0, 0, 0, 0.08)`
- **Icon**: 32px, centered, colored to match theme
- **Label**: 14px, weight 600, centered below icon

**New Badge** (Top-Right Corner):
```
┌──────────────┐
│      [✨ New]│
│   🏖️        │
│             │
│   Casual    │
└──────────────┘
```
- Badge: 6px dot + "New" text
- Color: Accent color (orange)
- Position: Absolute, top: 8px, right: 8px
- Pulse animation (scale 1.0 → 1.2 → 1.0, 2s infinite)

**Interactions:**

1. **Tap (Short Press)**
   - Haptic feedback (light)
   - Scale animation: 1.0 → 0.95 → 1.0 (150ms)
   - Navigate to `WardrobePairingSheet`
   - Mode: `PairingMode.surpriseMe`
   - Filter: Selected occasion
   - Log: `AppLogger.info('Quick Idea tapped: $occasion')`

2. **Long-Press**
   - Haptic feedback (medium)
   - Card lifts with shadow increase
   - Show `CustomizeMoodSheet` (modal bottom sheet)
   - Sheet height: 60% of screen
   - Content: Mood customization sliders

**Customize Mood Sheet:**
```
┌─────────────────────────────────────────┐
│            Customize Mood                │
│         ─────────────                    │
│                                          │
│  Tone                                    │
│  ├──────●──────┤                        │
│  Relaxed      Polished                  │
│                                          │
│  Palette                                 │
│  ┌────────┐ ┌────────┐ ┌────────┐      │
│  │Neutral │ │Vibrant │ │  Mono  │      │
│  └────────┘ └────────┘ └────────┘      │
│     (selected)                           │
│                                          │
│  Confidence                              │
│  ├───●────────┤                         │
│  Safe        Bold                        │
│                                          │
│            [Apply Mood]                  │
└─────────────────────────────────────────┘
```

**Sheet Specifications:**
- **Background**: Glassmorphism (`rgba(255, 255, 255, 0.95)` + blur)
- **Handle**: 40px × 4px pill, centered top
- **Padding**: 24px
- **Sliders**: Custom styled with primary color track
- **Apply Button**: Full width, primary color, 56px height

---

## 🎯 Section 3: Recent Generations

### Visual Design
```
Recent Generations                          [View All →]

┌──────────────────────────────────────────────────────┐
│ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐        │
│ │        │ │        │ │        │ │        │   →    │
│ │  IMG   │ │  IMG   │ │  IMG   │ │  IMG   │        │
│ │        │ │        │ │        │ │        │        │
│ ├────────┤ ├────────┤ ├────────┤ ├────────┤        │
│ │Title   │ │Title   │ │Title   │ │Title   │        │
│ │3 items │ │4 items │ │3 items │ │5 items │        │
│ │[Tight] │ │[Loose] │ │[Tight] │ │[Loose] │        │
│ │❤️ 📤   │ │🤍 📤   │ │❤️ 📤   │ │🤍 📤   │        │
│ └────────┘ └────────┘ └────────┘ └────────┘        │
└──────────────────────────────────────────────────────┘
```

**Card Specifications:**
- **Size**: 160px width × 220px height
- **Border Radius**: 20px
- **Spacing**: 12px between cards
- **Shadow**: `0 4px 16px rgba(0, 0, 0, 0.08)`
- **Background**: White with subtle gradient overlay

**Image Area** (Top 60%):
- **Height**: 132px
- **Border Radius**: 20px top, 0 bottom
- **Fit**: cover
- **Fallback**: 2×2 grid of item images
- **Overlay**: Gradient from transparent to `rgba(0, 0, 0, 0.2)` at bottom

**Info Area** (Bottom 40%):
- **Padding**: 12px
- **Title**: 12px, weight 600, max 2 lines, ellipsis
- **Item Count**: 10px, 60% opacity, weight 400
- **Badge**: Pill shape, 8px text, tight=green/loose=purple

**Badge Styles:**
```css
.tight-badge {
  background: #E8F5E9;
  color: #2E7D32;
  padding: 4px 8px;
  border-radius: 12px;
}

.loose-badge {
  background: #F3E5F5;
  color: #6A1B9A;
  padding: 4px 8px;
  border-radius: 12px;
}
```

**Action Row** (Bottom of card):
- **Height**: 32px
- **Layout**: Flex row, space-between
- **Icons**: 16px size
- **Heart**: Filled/outline toggle, red when favorited
- **Share**: Always outline, primary color

**Interactions:**
1. **Tap Card**
   - Navigate to `LookDetailScreen` (new screen)
   - Pass: `SavedOutfit` object
   - Show: Full mannequin, all items, styling tips

2. **Tap Heart**
   - Toggle favorite status
   - Animation: Scale + pulse (300ms)
   - Persist to storage
   - Snackbar: "Added to favorites ❤️" / "Removed from favorites"

3. **Tap Share**
   - Open native share sheet
   - Share: Mannequin image (if exists) + text
   - Text: "{title} • {items.length} items • Created with Vestiq"

4. **Long-Press**
   - Haptic feedback
   - Show action sheet:
     - View Look
     - Save a Copy
     - Edit Notes
     - Delete Look

**Empty State:**
```
┌─────────────────────────────────────────┐
│              ✨                          │
│                                          │
│      No saved outfits yet                │
│                                          │
│  Create your first look to see it here  │
│                                          │
│      [Generate Your First Look]         │
└─────────────────────────────────────────┘
```
- **Button**: Opens `showInteractivePairingSheet` with first wardrobe item
- **Icon**: 80px, 30% opacity
- **Text**: Centered, muted colors

**View All Screen:**
- Full-screen grid view
- 2 columns on phone, 3-4 on tablet
- Filter chips: All / Tight / Loose / Favorites
- Sort dropdown: Recent / Score / Name
- Search bar at top
- Pull-to-refresh

---

## 🎯 Section 4: Today's Picks

### Visual Design
```
Today's Picks

┌──────────────┬──────────────┐
│  For Today   │ For Tonight  │  ← Segmented Control
└──────────────┴──────────────┘

┌────────────────────────────────────────────────────┐
│ ┌──────────┐ ┌──────────┐ ┌──────────┐           │
│ │          │ │          │ │          │     →     │
│ │ Hero     │ │ Hero     │ │ Hero     │           │
│ │ +stack   │ │ +stack   │ │ +stack   │           │
│ │          │ │          │ │          │           │
│ ├──────────┤ ├──────────┤ ├──────────┤           │
│ │ ☀️ 22°C  │ │ ☀️ 22°C  │ │ ☀️ 22°C  │           │
│ │ 87% match│ │ 92% match│ │ 81% match│           │
│ │┌────────┐│ │┌────────┐│ │┌────────┐│           │
│ ││Wear Now││ ││Wear Now││ ││Wear Now││           │
│ │└────────┘│ │└────────┘│ │└────────┘│           │
│ └──────────┘ └──────────┘ └──────────┘           │
└────────────────────────────────────────────────────┘
```

**Segmented Control:**
- **Width**: Full width - 40px (20px margins)
- **Height**: 40px
- **Background**: `rgba(0, 0, 0, 0.05)`
- **Selected**: White background with shadow
- **Indicator**: Animated slide (250ms ease-out)
- **Text**: 14px, weight 600

**Card Specifications:**
- **Size**: 180px width × 240px height
- **Border Radius**: 20px
- **Background**: White
- **Shadow**: `0 6px 20px rgba(0, 0, 0, 0.08)`

**Hero Image + Stack:**
- **Layout**: Primary item (large) + 3 stacked mini items
- **Primary**: 100px × 100px, centered
- **Stack**: 3 circles, 32px diameter, overlapping by 8px
- **Position**: Bottom-right of image area

**Weather Chip:**
- **Layout**: Icon + temp + condition
- **Background**: `rgba(0, 0, 0, 0.6)` with blur
- **Color**: White
- **Position**: Top-left of image, 8px padding
- **Border Radius**: 16px

**Match Score:**
- **Progress Bar**: Full width, 4px height
- **Color**: Green (>75%), Amber (50-75%), Red (<50%)
- **Percentage**: 14px, weight 700, centered

**Action Buttons:**
```
┌─────────────┬─────────────┬─────────────┐
│  Wear Now   │  Save Look  │  Swap Item  │
└─────────────┴─────────────┴─────────────┘
```
- **Height**: 36px
- **Style**: Outlined buttons
- **Spacing**: 8px between
- **Icons**: 16px, before text

**Interactions:**

1. **Wear Now**
   - Mark all items as worn
   - Increment wear count for each item
   - Show success snackbar with confetti animation
   - Log event to analytics
   - Update "Last Worn" timestamp

2. **Save Look**
   - Save as `SavedOutfit`
   - Add to Recent Generations
   - Snackbar: "Look saved! ✨"
   - Icon changes to checkmark for 2s

3. **Swap Item**
   - Show `SwapItemSheet` (bottom sheet)
   - Display: All items in outfit
   - Tap item: Show alternatives from wardrobe
   - Select alternative: Re-generate pairing
   - Update card in place (smooth transition)

**Pull-to-Refresh:**
- Custom indicator: Rotating outfit icon
- Haptic feedback when triggered
- Calls `todaysPicksProvider.reroll()`
- Success: Subtle confetti animation

**Empty State:**
```
┌─────────────────────────────────────────┐
│              👗                          │
│                                          │
│    Add items to your wardrobe            │
│    to get today's suggestions            │
│                                          │
│      [Upload Your First Item]           │
└─────────────────────────────────────────┘
```

---

## 🎯 Section 5: Your Wardrobe

### Visual Design
```
Your Wardrobe                               [View All →]

┌────────┬────────┬────────┐
│        │        │        │
│  IMG   │  IMG   │  IMG   │
│        │        │        │
│ [Top]  │[Bottom]│[Shoes] │
│ Worn 5x│ Worn 2x│ Worn 8x│
├────────┼────────┼────────┤
│        │        │        │
│  IMG   │  IMG   │  IMG   │
│        │        │        │
│ [Dress]│ [Top]  │[Access]│
│ Worn 1x│ Worn 3x│ Worn 6x│
└────────┴────────┴────────┘

            [Upload More Items]
```

**Grid Specifications:**
- **Layout**: 3 columns × 2 rows (6 items max)
- **Tile Size**: Dynamic, maintains aspect ratio 1:1
- **Gap**: 12px
- **Total Height**: ~220px

**Tile Design:**
- **Border Radius**: 16px
- **Background**: Polished image
- **Overlay**: Linear gradient from transparent to `rgba(0, 0, 0, 0.7)` at bottom
- **Shadow**: `0 2px 8px rgba(0, 0, 0, 0.1)`

**Overlay Info** (Bottom):
- **Category Chip**: 
  - Background: `rgba(255, 255, 255, 0.9)`
  - Text: 10px, weight 700, uppercase
  - Padding: 4px 8px
  - Border Radius: 8px
  - Position: Bottom-left, 8px margin

- **Wear Count**:
  - Icon: Repeat icon, 12px
  - Text: "Worn 5x", 10px, white, weight 500
  - Position: Bottom-right, 8px margin

**Quick Actions** (Long-Press):
```
┌─────────────────────────────────────────┐
│  ┌──────────────────────────────────┐  │
│  │    [Image Preview]                │  │
│  └──────────────────────────────────┘  │
│                                          │
│  ✨ Pair This Item                      │
│  🎲 Surprise Me                         │
│  📍 Style by Location                   │
│  ─────────────────────────────────────  │
│  👁️  View Details                      │
│  🗑️  Delete Item                       │
└─────────────────────────────────────────┘
```

**Upload More CTA** (Footer):
- **Condition**: Show when < 6 items
- **Style**: Dashed border, 2px, primary color
- **Height**: 56px
- **Text**: "Upload more items to complete your wardrobe"
- **Icon**: Camera icon, 24px
- **Tap**: Navigate to `UploadOptionsScreen`

**View All Button:**
- **Style**: Text button with arrow
- **Color**: Primary
- **Weight**: 600
- **Tap**: Navigate to `EnhancedClosetScreen`

**Interactions:**
1. **Tap Tile**: `showWardrobeItemPreview`
2. **Long-Press**: Show quick actions sheet
3. **Tap View All**: Navigate to closet with animation

---

## 🎨 Visual Enhancements

### 1. **Parallax Scroll Effect**
```dart
Transform.translate(
  offset: Offset(0, scrollOffset * 0.3),
  child: HeroSection(),
)
```
- Applied to hero section
- Creates depth as user scrolls

### 2. **Card Slide-In Animations**
```dart
AnimatedBuilder(
  animation: animationController,
  builder: (context, child) {
    return Transform.translate(
      offset: Offset(0, 50 * (1 - animation.value)),
      child: Opacity(
        opacity: animation.value,
        child: child,
      ),
    );
  },
)
```
- Stagger by 50ms per card
- Duration: 300ms
- Curve: easeOutCubic

### 3. **Loading Skeletons**
```
┌─────────────────────────────┐
│ ░░░░░░░░░░░░░░░░░░░░░░░░░ │  ← Shimmer
│                              │
│ ░░░░  ░░░░  ░░░░  ░░░░     │
│ ░░░░  ░░░░  ░░░░  ░░░░     │
└─────────────────────────────┘
```
- Shimmer effect: Light sweep every 1.5s
- Colors: Base gray → lighter gray → base
- Border radius matches actual components

### 4. **Haptic Feedback Map**
| Action | Feedback Type |
|--------|---------------|
| Tap card | Light |
| Long-press | Medium |
| Toggle favorite | Success (if supported) |
| Delete | Warning |
| Save | Success |
| Error | Error |

---

## 📱 Responsive Breakpoints

| Device | Columns | Card Size | Margins |
|--------|---------|-----------|---------|
| Phone (< 600px) | Defined per section | Full-width - 40px | 20px |
| Tablet (600-900px) | +1 column | Proportional | 32px |
| Desktop (> 900px) | +2 columns | Max 240px | 40px |

---

## 🎭 Theme Support

### Light Mode
- Background: `#FCFCFC`
- Card Background: `#FFFFFF`
- Text Primary: `#1A1A2C`
- Text Secondary: `#8A8A8F`
- Border: `rgba(0, 0, 0, 0.08)`

### Dark Mode (Dusk Theme)
- Background: `#0F0F0F`
- Card Background: `#1A1A1A`
- Text Primary: `#FFFFFF`
- Text Secondary: `#B3B3B3`
- Border: `rgba(255, 255, 255, 0.12)`

**Transition:**
- Duration: 300ms
- Curve: easeInOut
- Animate: Colors, shadows, borders
- Persist: SharedPreferences

---

## 🔄 State Management Flow

```dart
// Home Screen watches all providers
Consumer(
  builder: (context, ref, child) {
    final quickIdeas = ref.watch(quickIdeasProvider);
    final recentLooks = ref.watch(recentLooksProvider);
    final todaysPicks = ref.watch(todaysPicksProvider);
    final wardrobe = ref.watch(wardrobeSnapshotProvider);
    final isDark = ref.watch(homeThemeProvider);
    
    return HomeScreenContent(
      quickIdeas: quickIdeas,
      recentLooks: recentLooks,
      todaysPicks: todaysPicks,
      wardrobe: wardrobe,
      isDark: isDark,
    );
  },
)
```

---

## ✨ Polish Checklist

- [ ] All animations run at 60fps
- [ ] Touch targets >= 48px
- [ ] No text overflow anywhere
- [ ] Empty states for all sections
- [ ] Loading states for all sections
- [ ] Error states with retry
- [ ] Offline mode with banner
- [ ] Pull-to-refresh on all scrollable areas
- [ ] Haptic feedback on all interactions
- [ ] AppLogger events for all actions
- [ ] Accessibility labels on all interactive elements
- [ ] Semantic labels for screen readers
- [ ] High contrast mode support
- [ ] RTL layout support (future)

---

## 🚀 Implementation Order

1. **Phase 1**: Update existing home_screen.dart to use providers
2. **Phase 2**: Implement Quick Outfit Ideas enhancements
3. **Phase 3**: Upgrade Recent Generations with all features
4. **Phase 4**: Build Today's Picks from scratch
5. **Phase 5**: Polish Your Wardrobe section
6. **Phase 6**: Complete search & theme toggle
7. **Phase 7**: Add all animations & transitions
8. **Phase 8**: QA & refinement

---

**This blueprint ensures every pixel serves the premium, elegant experience Vestiq users deserve! 🎨✨**
