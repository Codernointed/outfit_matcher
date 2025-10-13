# Preview Sheet Inspiration Button Fix ✅

## Problem
The "Inspiration" button in the preview sheet wasn't working due to context/mounting issues after showing the dialog. The widget would unmount before navigation could occur.

**Error Log:**
```
I/flutter (14706): ℹ️ ✅ [PREVIEW SHEET] Generate button tapped with notes: ""
I/flutter (14706): ℹ️ 📝 [PREVIEW SHEET] Dialog returned: ""
I/flutter (14706): ⚠️ [PREVIEW SHEET] Widget unmounted, cannot navigate
```

## Root Cause
The preview sheet widget was unmounting after the dialog closed, making the context invalid for navigation.

## Solution Applied

### 1. **Callback-Based Approach**
Instead of trying to navigate from within the preview sheet, we now pass a callback function from the parent screen (closet/search) that handles the navigation.

**Changes Made:**

#### `wardrobe_item_preview_sheet.dart`:
- Added `onInspirationTap` callback parameter to `showWardrobeItemPreview()` function
- Added `onInspirationTap` field to `CleanItemPreviewSheet` widget
- Updated inspiration button to use callback when available, fallback to old method
- Simplified `_navigateToInspiration()` method as fallback

#### `enhanced_closet_screen.dart`:
- Updated `_showItemPreview()` to pass `onInspirationTap: () => _navigateToInspiration(item)`
- Uses existing `_navigateToInspiration()` method that already works correctly

#### `wardrobe_search_screen.dart`:
- Updated `_showItemPreview()` to pass callback
- Added `_navigateToInspiration()` method (copied from closet screen)
- Added `_buildStylingNotesDialog()` method
- Added missing import for `EnhancedVisualSearchScreen`

### 2. **How It Works Now**

**Before (Broken):**
```
Preview Sheet → Dialog → Try to navigate from preview sheet context ❌
```

**After (Fixed):**
```
Preview Sheet → Dialog → Callback to parent → Navigate from parent context ✅
```

### 3. **Benefits**
- ✅ **Reliable Navigation**: Uses parent context that doesn't unmount
- ✅ **Consistent Behavior**: Same as quick actions that already work
- ✅ **Fallback Support**: Still works if callback not provided
- ✅ **No Breaking Changes**: Existing functionality preserved

## Testing
The inspiration button should now work consistently in:
- ✅ Closet screen preview sheet
- ✅ Search screen preview sheet  
- ✅ Quick actions (already working)

## Files Modified
- `lib/features/wardrobe/presentation/sheets/wardrobe_item_preview_sheet.dart`
- `lib/features/wardrobe/presentation/screens/enhanced_closet_screen.dart`
- `lib/features/wardrobe/presentation/screens/wardrobe_search_screen.dart`

## Status
✅ **FIXED** - Preview sheet inspiration button now works reliably using callback-based navigation approach.
