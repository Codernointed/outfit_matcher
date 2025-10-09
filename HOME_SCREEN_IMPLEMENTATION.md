# 🏠 Home Screen Complete Implementation Plan

## 📋 Overview

This document outlines the complete implementation strategy for transforming the Vestiq home screen into a premium, fully-functional dashboard that serves as the central hub for outfit discovery and wardrobe management.

---

## 🎯 Implementation Phases

### Phase 1: Foundation & State Management ✅ **STARTED**
**Duration:** 1-2 days  
**Status:** In Progress

#### Completed:
- ✅ Created `home_providers.dart` with Riverpod state management
- ✅ Defined all state classes (HomeState, QuickIdeasState, RecentLooksState, etc.)
- ✅ Implemented providers for each section
- ✅ Created `HomeSearchResultsScreen` for search functionality

#### Next Steps:
1. Test providers with existing data
2. Add error handling and retry logic
3. Implement caching strategies

---

### Phase 2: Quick Outfit Ideas Enhancement
**Duration:** 1 day  
**Priority:** High

#### Tasks:
1. **Update UI Components**
   - Add "New ✨" badge when suggestions available
   - Implement long-press gesture for "Customize Mood" modal
   - Add subtle animations on card tap

2. **Create Customize Mood Modal**
   ```dart
   // lib/features/outfit_suggestions/presentation/widgets/customize_mood_sheet.dart
   - Tone slider (Relaxed ↔ Polished)
   - Palette selector (Neutral, Vibrant, Monochrome)
   - Confidence level (Safe, Balanced, Bold)
   - Apply button triggers pairing with weights
   ```

3. **Wire Navigation**
   - Tap → `showWardrobePairingSheet` with `PairingMode.surpriseMe` + occasion filter
   - Long-press → `showCustomizeMoodSheet`
   - Log all interactions with AppLogger

#### Files to Modify:
- `lib/features/outfit_suggestions/presentation/screens/home_screen.dart` (_buildQuickActions)
- Create: `lib/features/outfit_suggestions/presentation/widgets/customize_mood_sheet.dart`

---

### Phase 3: Recent Generations Upgrade
**Duration:** 1-2 days  
**Priority:** High

#### Tasks:
1. **Enhance Card Display**
   - Fixed card width (160px) and height (220px)
   - Add tight/loose badge pill
   - Improve image fallback (grid of item images)
   - Add share functionality

2. **Create Saved Looks Library Screen**
   ```dart
   // lib/features/outfit_suggestions/presentation/screens/saved_looks_screen.dart
   - Filter chips (occasion, score, tight/loose)
   - Grid view of all saved looks
   - Sort options (recent, score, favorites)
   - Search within saved looks
   ```

3. **Implement Actions**
   - Tap card → Navigate to look detail screen
   - Heart → Toggle favorite (persist to storage)
   - Share → Share sheet with image/text
   - Long-press → Action sheet (View, Save copy, Edit notes, Delete)

#### Files to Modify:
- `lib/features/outfit_suggestions/presentation/screens/home_screen.dart` (_buildRecentGenerations)
- Create: `lib/features/outfit_suggestions/presentation/screens/saved_looks_screen.dart`
- Create: `lib/features/outfit_suggestions/presentation/screens/look_detail_screen.dart`

---

### Phase 4: Today's Picks Implementation
**Duration:** 2-3 days  
**Priority:** High

#### Tasks:
1. **Create Tab System**
   ```dart
   // Custom segmented button for "For Today" / "For Tonight"
   - Animated indicator
   - Smooth transitions
   - State persistence
   ```

2. **Generate Smart Picks**
   - Integrate with `WardrobePairingService`
   - Consider time of day (morning = casual, evening = elevated)
   - Factor in weather (optional Weather API integration)
   - Use wear history to rotate underused items

3. **Card Design**
   - Hero item thumbnail
   - Supporting items (stacked avatars)
   - Weather chip (°C + icon)
   - Match score progress bar
   - Action buttons (Wear Now, Save Look, Swap Item)

4. **Actions Implementation**
   - **Wear Now**: Mark as worn, increment wear count, log event
   - **Save Look**: Store as SavedOutfit
   - **Swap Item**: Show bottom drawer with alternatives, re-run pairing

#### Files to Modify:
- `lib/features/outfit_suggestions/presentation/screens/home_screen.dart` (_buildTodaysSuggestions)
- `lib/features/outfit_suggestions/presentation/providers/home_providers.dart` (TodaysPicksNotifier)
- Create: `lib/features/outfit_suggestions/presentation/widgets/todays_picks_card.dart`
- Create: `lib/features/outfit_suggestions/presentation/widgets/swap_item_sheet.dart`

---

### Phase 5: Your Wardrobe Snapshot
**Duration:** 1 day  
**Priority:** Medium

#### Tasks:
1. **Grid Layout**
   - 2 rows × 3 columns
   - Polished image display
   - Category chip overlay
   - Wear count indicator

2. **Quick Actions**
   - Tap → `showWardrobeItemPreview`
   - Long-press → Quick actions (Pair, Surprise, Delete)
   - Hover effect (if applicable)

3. **Footer CTA**
   - Show "Upload more items" when < 6 items
   - Link to `UploadOptionsScreen`
   - "View All" → Navigate to `EnhancedClosetScreen`

#### Files to Modify:
- `lib/features/outfit_suggestions/presentation/screens/home_screen.dart` (_buildRecentItemsPreview)
- `lib/features/outfit_suggestions/presentation/providers/home_providers.dart` (WardrobeSnapshotNotifier)

---

### Phase 6: Search & Theme Toggle
**Duration:** 1-2 days  
**Priority:** Medium

#### Tasks:
1. **Search Bar Enhancement**
   - Glass effect background
   - Debounced search (300ms)
   - Search history chips
   - Voice input stub (show permission dialog)

2. **Filter System**
   ```dart
   // lib/features/outfit_suggestions/presentation/widgets/search_filter_sheet.dart
   - Occasion checkboxes
   - Season checkboxes
   - Color palette selector
   - Apply/Reset buttons
   ```

3. **Theme Toggle**
   - Sun/Moon icon in AppBar
   - Persist theme choice in SharedPreferences
   - Smooth transition animation
   - Toast feedback on toggle

4. **Search Results Screen** ✅ **CREATED**
   - Already implemented with 3 tabs
   - Items, Looks, Inspiration
   - Needs testing and refinement

#### Files to Modify:
- `lib/features/outfit_suggestions/presentation/screens/home_screen.dart` (AppBar)
- `lib/main.dart` (Theme provider integration)
- `lib/core/services/app_settings_service.dart` (Add theme persistence)
- Create: `lib/features/outfit_suggestions/presentation/widgets/search_filter_sheet.dart`

---

## 🎨 UX Enhancements (Cross-Cutting)

### Animation & Motion
- [ ] Parallax effect on scroll
- [ ] Card slide-in animations
- [ ] Micro-haptics on interactions
- [ ] Pull-to-refresh with custom indicator
- [ ] Confetti animation on "Today's Picks" reroll

### Loading States
- [ ] Shimmer placeholders for all sections
- [ ] Skeleton screens
- [ ] Progressive loading (show cached data first)

### Error Handling
- [ ] Retry buttons on error states
- [ ] Offline banner
- [ ] Graceful degradation
- [ ] AppLogger integration throughout

---

## 📊 Data Flow Architecture

```
┌─────────────────────────────────────────────────┐
│              Home Screen UI                      │
│  (MainContentHomeScreen - ConsumerStatefulWidget)│
└────────────────┬────────────────────────────────┘
                 │
                 │ watches
                 ▼
┌─────────────────────────────────────────────────┐
│           Riverpod Providers                     │
│  - quickIdeasProvider                            │
│  - recentLooksProvider                           │
│  - todaysPicksProvider                           │
│  - wardrobeSnapshotProvider                      │
│  - homeThemeProvider                             │
│  - homeSearchHistoryProvider                     │
└────────────────┬────────────────────────────────┘
                 │
                 │ calls
                 ▼
┌─────────────────────────────────────────────────┐
│              Services Layer                      │
│  - OutfitStorageService                          │
│  - EnhancedWardrobeStorageService                │
│  - WardrobePairingService                        │
│  - AppSettingsService                            │
└─────────────────────────────────────────────────┘
```

---

## 🔧 Technical Considerations

### Performance
- **Lazy Loading**: Load sections as they scroll into view
- **Image Caching**: Use `CachedNetworkImage` for remote images
- **Debouncing**: Search input, scroll events
- **Memoization**: Cache expensive computations

### Offline Support
- **Cached Data**: Show last loaded data when offline
- **Offline Banner**: Display at top when no connection
- **Queue Actions**: Save actions (favorites, wear count) for sync later

### Analytics
- **Track Events**:
  - Section impressions
  - Card taps
  - Search queries
  - Outfit saves/wears
  - Theme toggles
- **Use AppLogger** for all events
- **Future**: Integrate Firebase Analytics

---

## 📝 Testing Strategy

### Unit Tests
- [ ] Provider state transitions
- [ ] Search filtering logic
- [ ] Pairing generation algorithms

### Widget Tests
- [ ] Each section renders correctly
- [ ] Empty states display properly
- [ ] Loading states show/hide correctly
- [ ] Error states with retry work

### Integration Tests
- [ ] Full user flows (search → view → save)
- [ ] Navigation between screens
- [ ] Data persistence

---

## 🚀 Deployment Checklist

### Before Launch
- [ ] All TODOs resolved
- [ ] No debug print statements
- [ ] AppLogger used consistently
- [ ] Error handling complete
- [ ] Loading states implemented
- [ ] Empty states designed
- [ ] Offline mode tested
- [ ] Theme toggle works
- [ ] Search fully functional
- [ ] All navigation wired

### Performance Targets
- [ ] First paint < 1s
- [ ] Section load < 500ms
- [ ] Search results < 300ms
- [ ] Smooth 60fps scrolling
- [ ] Memory usage < 150MB

---

## 📚 File Structure

```
lib/features/outfit_suggestions/
├── presentation/
│   ├── providers/
│   │   └── home_providers.dart ✅
│   ├── screens/
│   │   ├── home_screen.dart (to be updated)
│   │   ├── home_search_results_screen.dart ✅
│   │   ├── saved_looks_screen.dart (to create)
│   │   └── look_detail_screen.dart (to create)
│   └── widgets/
│       ├── customize_mood_sheet.dart (to create)
│       ├── todays_picks_card.dart (to create)
│       ├── swap_item_sheet.dart (to create)
│       └── search_filter_sheet.dart (to create)
```

---

## 🎯 Success Metrics

### User Experience
- **Engagement**: Users interact with 3+ sections per session
- **Discovery**: 60%+ users tap "Today's Picks"
- **Retention**: Users return within 24 hours
- **Satisfaction**: < 5% error rate

### Technical
- **Performance**: 60fps scrolling
- **Reliability**: 99%+ uptime
- **Responsiveness**: < 500ms section load
- **Efficiency**: < 150MB memory usage

---

## 📅 Timeline Summary

| Phase | Duration | Priority | Status |
|-------|----------|----------|--------|
| 1. Foundation | 1-2 days | Critical | ✅ In Progress |
| 2. Quick Ideas | 1 day | High | ⏳ Pending |
| 3. Recent Generations | 1-2 days | High | ⏳ Pending |
| 4. Today's Picks | 2-3 days | High | ⏳ Pending |
| 5. Wardrobe Snapshot | 1 day | Medium | ⏳ Pending |
| 6. Search & Theme | 1-2 days | Medium | ⏳ Pending |
| **Total** | **7-11 days** | | |

---

## 🎉 Next Immediate Actions

1. **Test Current Providers** (30 mins)
   - Run app and verify providers load data
   - Check for any runtime errors
   - Validate state transitions

2. **Update home_screen.dart** (2 hours)
   - Replace current state management with providers
   - Update _buildQuickActions to use quickIdeasProvider
   - Update _buildRecentGenerations to use recentLooksProvider

3. **Create Customize Mood Sheet** (1 hour)
   - Build UI with sliders and toggles
   - Wire to WardrobePairingService
   - Add logging

4. **Implement Long-Press Gesture** (30 mins)
   - Add GestureDetector to Quick Outfit cards
   - Show Customize Mood sheet on long-press
   - Add haptic feedback

---

**Let's build this premium home screen experience! 🚀**

