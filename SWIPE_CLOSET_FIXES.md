# Swipe Closet Fixes - Implementation Plan

## Issues to Fix

### 1. **UI Too Cluttered** ✅
**Problem**: Header takes up almost half the page before wardrobe grid appears
**Solution**: 
- Reduce header padding from `24px` to `16px`
- Change title from `headlineMedium` to `titleLarge`
- Remove subtitle "Your digital wardrobe"
- Make action buttons smaller (22px icons instead of default)
- Reduce CTA padding and make it more compact
- Remove box shadows and unnecessary spacing

**Files to modify**:
- `lib/features/wardrobe/presentation/screens/enhanced_closet_screen.dart` - Replace `_buildCustomHeader` method with minimal version

---

### 2. **Empty Wardrobe Bug** ❌
**Problem**: Swipe planner shows "No items found" even though wardrobe has items
**Root Cause**: The filtering logic in `swipe_planner_providers.dart` is too strict and filters out all items

**Solution**:
1. Check if `getFilteredWardrobeItems` is being called with correct parameters
2. Make filtering more lenient - if no matches, fall back to all items
3. Add logging to see what's being filtered
4. Fix the empty state detection logic

**Files to modify**:
- `lib/features/wardrobe/presentation/providers/swipe_planner_providers.dart`
- `lib/core/services/enhanced_wardrobe_storage_service.dart`

---

### 3. **Overflow Error (296px)** ❌
**Problem**: Swipe planner sheet overflows by 296 pixels
**Root Cause**: Too much content in a fixed-height Column without scrolling

**Solution**:
- Wrap the sheet content in `SingleChildScrollView`
- Use `DraggableScrollableSheet` properly with correct sizing
- Reduce spacing between sections
- Make occasion chips wrap better
- Reduce optional preferences section size

**Files to modify**:
- `lib/features/wardrobe/presentation/sheets/swipe_planner_sheet.dart`

---

### 4. **Swipe Screen UX Polish** ❌
**Problem**: Swipe closet screen needs better UX touches

**Improvements needed**:
1. Add smooth animations when swiping items
2. Better empty state with helpful message
3. Add haptic feedback on swipe
4. Show item count per category
5. Add loading state when generating surprise outfit
6. Better visual feedback when items are selected
7. Add subtle shadows and elevation
8. Improve the current selection preview card

**Files to modify**:
- `lib/features/wardrobe/presentation/screens/swipe_closet_screen.dart`

---

## Implementation Order

1. ✅ Fix cluttered UI (quick win)
2. Fix empty wardrobe bug (critical)
3. Fix overflow error (critical)
4. Add UX polish to swipe screen (enhancement)

---

## Code Changes

### Fix 1: Minimal Header (DONE)
See `enhanced_closet_screen_minimal.dart` for the new `_buildCustomHeader` implementation.

### Fix 2: Empty Wardrobe Bug

In `swipe_planner_providers.dart`, change the filtering logic:

```dart
final swipeClosetPoolsProvider = FutureProvider.autoDispose<SwipeClosetPools>((
  ref,
) async {
  final request = ref.watch(swipeRequestProvider);
  final storage = getIt<EnhancedWardrobeStorageService>();
  
  // Get ALL items first
  final allItems = await storage.getWardrobeItems();
  
  AppLogger.info(
    '🎯 Total wardrobe items: ${allItems.length}',
  );
  
  if (request == null || allItems.isEmpty) {
    return SwipeClosetPools(
      tops: allItems.where((item) => item.analysis.itemType.toLowerCase().contains('top')).toList(),
      bottoms: allItems.where((item) => item.analysis.itemType.toLowerCase().contains('bottom')).toList(),
      footwear: allItems.where((item) => item.analysis.itemType.toLowerCase().contains('shoe') || item.analysis.itemType.toLowerCase().contains('footwear')).toList(),
      accessories: allItems.where((item) => item.analysis.itemType.toLowerCase().contains('accessory')).toList(),
    );
  }

  // Try filtering, but fall back to all items if nothing matches
  try {
    final filtered = await storage.getFilteredWardrobeItems(
      occasion: request.occasion,
      mood: request.mood,
      weather: request.weather,
      colorPreference: request.colorPreference,
    );
    
    AppLogger.info('🔍 Filtered items: ${filtered.length}');
    
    // If filtering returns nothing, use all items
    final itemsToUse = filtered.isEmpty ? allItems : filtered;
    
    return SwipeClosetPools(
      tops: itemsToUse.where((item) => item.analysis.itemType.toLowerCase().contains('top')).toList(),
      bottoms: itemsToUse.where((item) => item.analysis.itemType.toLowerCase().contains('bottom')).toList(),
      footwear: itemsToUse.where((item) => item.analysis.itemType.toLowerCase().contains('shoe') || item.analysis.itemType.toLowerCase().contains('footwear')).toList(),
      accessories: itemsToUse.where((item) => item.analysis.itemType.toLowerCase().contains('accessory')).toList(),
    );
  } catch (e) {
    AppLogger.error('❌ Filtering error, using all items', error: e);
    // Fall back to all items on error
    return SwipeClosetPools(
      tops: allItems.where((item) => item.analysis.itemType.toLowerCase().contains('top')).toList(),
      bottoms: allItems.where((item) => item.analysis.itemType.toLowerCase().contains('bottom')).toList(),
      footwear: allItems.where((item) => item.analysis.itemType.toLowerCase().contains('shoe') || item.analysis.itemType.toLowerCase().contains('footwear')).toList(),
      accessories: allItems.where((item) => item.analysis.itemType.toLowerCase().contains('accessory')).toList(),
    );
  }
});
```

### Fix 3: Overflow Error

In `swipe_planner_sheet.dart`, wrap content in scrollable view:

```dart
return DraggableScrollableSheet(
  initialChildSize: 0.9,
  minChildSize: 0.5,
  maxChildSize: 0.95,
  expand: false,
  builder: (context, scrollController) {
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(  // ADD THIS
        controller: scrollController,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              // ... rest of content
            ),
          ),
        ),
      ),
    );
  },
);
```

### Fix 4: UX Polish

Add to `swipe_closet_screen.dart`:
- Haptic feedback on swipe
- Loading indicators
- Better animations
- Improved empty states
- Item count badges

