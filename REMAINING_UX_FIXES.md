# Remaining UX Fixes - Implementation Guide

## ✅ Completed (Steps 1-8)

1. **Surprise Me Logic** - Separated from Pair This Item, now shows different creative outfits
2. **View Inspiration Notes** - Added custom styling notes dialog with pre-filled context
3. **Category Exclusion** - No more shirt+shirt or jeans+jeans pairings, smart layering logic
4. **Full-Body Mannequins** - Enhanced Gemini prompts with aggressive head-to-toe instructions
5. **Empty State FAB** - FAB only shows when closet has items, empty state has dedicated button
6. **Dynamic Island Navbar** - Premium glassmorphism bottom navigation created

## 🚧 Remaining Fixes (Steps 7-8)
### Step 3: Redesign Item Details Sheet
**File:** `lib/features/wardrobe/presentation/sheets/wardrobe_item_preview_sheet.dart`

**Current Issue:** Cluttered modal with too many buttons and information

**Solution:**
- Simplify hero image display (full-width, no overlays)
- Move quick actions to compact pill buttons at bottom
- Group metadata into collapsible sections:
  - **Style Info** (color, pattern, formality)
  - **Occasions** (work, casual, date)
  - **Care Notes** (user notes, wear count)
- Remove redundant "Pair This" button (use quick actions from long-press instead)

### Step 4: Fix Pairing Logic - Exclude Same Categories
**File:** `lib/core/services/wardrobe_pairing_service.dart`

**Current Issue:** Pairing shows shirt+shirt, jeans+jeans (illogical combinations)

**Solution:**
Add category exclusion logic in `_generatePairThisItemPairings()`:

```dart
// Helper method to check if item can layer
bool _isLayeringPiece(WardrobeItem item) {
  final type = item.analysis.itemType.toLowerCase();
  return type.contains('jacket') || 
         type.contains('blazer') || 
         type.contains('vest') || 
         type.contains('coat') || 
         type.contains('cardigan');
}

// Update pairing generation
if (_isTop(heroItem)) {
  // Exclude other tops UNLESS they're layering pieces
  final validTops = tops.where((t) => 
    t.id != heroItem.id && _isLayeringPiece(t)
  ).toList();
  
  // Always include bottoms, shoes, accessories
  final bottoms = availableItems.where(_isBottom).toList();
  final shoes = availableItems.where(_isShoes).toList();
  final accessories = availableItems.where(_isAccessory).toList();
}

if (_isBottom(heroItem)) {
  // Show ALL tops (they pair with bottoms)
  // Show shoes and accessories
  // EXCLUDE other bottoms
  final validItems = availableItems.where((item) => 
    !_isBottom(item) || item.id == heroItem.id
  ).toList();
}

if (_isDress(heroItem)) {
  // Show jackets/coats for layering
  // Show shoes and accessories
  // EXCLUDE other dresses
  final validItems = availableItems.where((item) => 
    _isLayeringPiece(item) || _isShoes(item) || _isAccessory(item)
  ).toList();
}
```

### Step 5: Resolve Scoring Inconsistency
**File:** `lib/core/services/wardrobe_pairing_service.dart`

**Current Issue:** Pair This says "Bottom 1 is best", Surprise Me says "Bottom 2 is best"

**Root Cause:** Surprise Me uses randomization which can override compatibility scores

**Solution:**
1. Ensure both modes use `_getCompatibilityScore()` with cache
2. Log scores for debugging:
```dart
AppLogger.debug('Compatibility scores', data: {
  'hero': heroItem.id,
  'item': candidateItem.id,
  'score': score,
  'mode': mode.toString(),
});
```
3. In Surprise Me, only randomize WITHIN same score tier:
```dart
// Group by score tiers
final highScore = candidates.where((c) => score >= 0.8).toList();
final medScore = candidates.where((c) => score >= 0.6 && score < 0.8).toList();
final lowScore = candidates.where((c) => score < 0.6).toList();

// Pick randomly from appropriate tier
final selected = isTight 
  ? highScore.isNotEmpty ? highScore[random.nextInt(highScore.length)] : medScore.first
  : medScore.isNotEmpty ? medScore[random.nextInt(medScore.length)] : lowScore.first;
```

### Step 6: Full-Body Mannequin View
**File:** `lib/core/utils/gemini_api_service_new.dart`

**Current Issue:** Mannequins show cropped torso only (no head/feet)

**Solution:**
Update `_buildMannequinPrompt()`:

```dart
final prompt = '''
Generate a FULL-BODY fashion mannequin image showing the complete outfit from HEAD TO TOE.

CRITICAL REQUIREMENTS:
- Show ENTIRE body: head, torso, legs, feet
- Full-length view with NO cropping
- Professional fashion photography framing
- Mannequin should be centered and fully visible
- Include all clothing items: ${items.map((i) => i.itemType).join(', ')}

Style: $desiredStyle
Pose: $poseDescription
Colors: ${items.map((i) => i.primaryColor).join(', ')}

IMPORTANT: The image must show the complete mannequin from head to feet. Do not crop any body parts.
''';
```

Add validation after generation:
```dart
// Check if image is full-body (heuristic: aspect ratio should be ~3:4 or taller)
if (imageHeight / imageWidth < 1.3) {
  AppLogger.warning('Mannequin may be cropped, retrying...');
  // Retry with more explicit prompt
}
```

### Step 7: Empty State FAB Behavior
**File:** `lib/features/wardrobe/presentation/screens/enhanced_closet_screen.dart`

**Current Issue:** Both FAB and empty state button show when closet is empty

**Solution:**
```dart
@override
Widget build(BuildContext context) {
  final wardrobeAsync = ref.watch(filteredWardrobeItemsProvider);
  
  return Scaffold(
    appBar: _buildAppBar(),
    body: wardrobeAsync.when(
      data: (items) => items.isEmpty 
        ? _buildEmptyState() 
        : _buildClosetGrid(items),
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(error),
    ),
    // Only show FAB when items exist
    floatingActionButton: wardrobeAsync.maybeWhen(
      data: (items) => items.isNotEmpty 
        ? FloatingActionButton.extended(
            onPressed: _navigateToUpload,
            icon: const Icon(Icons.add),
            label: const Text('Add Item'),
          )
        : null,
      orElse: () => null,
    ),
  );
}

Widget _buildEmptyState() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.checkroom, size: 80, color: Colors.grey[300]),
        const SizedBox(height: 24),
        Text('Your closet is empty', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 12),
        Text('Add your first item to get started'),
        const SizedBox(height: 32),
        // Only button when empty
        FilledButton.icon(
          onPressed: _navigateToUpload,
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('Add First Item'),
        ),
      ],
    ),
  );
}
```

### Step 8: Premium Dynamic Island Bottom Navbar
**File:** `lib/features/wardrobe/presentation/widgets/dynamic_island_navbar.dart` (NEW)

**Design Specs:**
- Floating rounded "island" container
- Glassmorphism effect (blur + transparency)
- Centered active tab with expansion animation
- Haptic feedback on tap
- Icons: Closet, Style, Inspire, Profile

**Implementation:**
```dart
class DynamicIslandNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.checkroom, 'Closet'),
              _buildNavItem(1, Icons.auto_awesome, 'Style'),
              _buildNavItem(2, Icons.explore, 'Inspire'),
              _buildNavItem(3, Icons.person, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = currentIndex == index;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 20 : 12,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isActive 
            ? theme.colorScheme.primary.withOpacity(0.2)
            : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive 
                ? theme.colorScheme.primary 
                : theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

## Priority Order
1. ✅ Surprise Me logic (DONE)
2. ✅ View Inspiration notes (DONE)
3. **Pairing category exclusion** (CRITICAL - affects core functionality)
4. **Scoring consistency** (HIGH - user trust issue)
5. **Full-body mannequins** (HIGH - visual quality)
6. **Empty state FAB** (MEDIUM - polish)
7. **Item details redesign** (MEDIUM - UX improvement)
8. **Dynamic island navbar** (LOW - aesthetic enhancement)

## Testing Checklist
- [ ] Surprise Me shows different outfits than Pair This
- [ ] View Inspiration dialog appears with pre-filled + custom notes
- [ ] Pairing never shows shirt+shirt or jeans+jeans
- [ ] Same hero item gives consistent scores in both modes
- [ ] Mannequins show full body (head to toe)
- [ ] FAB hidden when closet empty, shown when populated
- [ ] Item details sheet is clean and uncluttered
- [ ] Bottom navbar has island design with smooth animations
