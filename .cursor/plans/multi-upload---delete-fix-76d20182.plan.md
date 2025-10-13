<!-- 76d20182-49ca-4f73-97c9-fc6310779ef9 a949944c-a0ed-441f-bc22-f114aeef750d -->
# Perfect Outfit Generation System

## Problem Statement

Current outfit generation has critical issues:

1. Uploaded items are being replaced with AI-generated alternatives
2. Multiple tops are being blended into one hideous merged item
3. Not all uploaded items appear across the 6 generations
4. When user uploads "2 shoes + 1 top", they expect to see that top in ALL generations with different shoes, but currently see random tops

## Solution: Category-Constrained Outfit Composition (CCOC)

### Core Rules

1. If user uploads items in a category (e.g., 3 tops), ONLY those items appear in that category across all generations
2. Each outfit uses exactly ONE item per uploaded category
3. Every uploaded item must appear at least once across 6 generations
4. Unuploaded categories (shoes, accessories, etc.) can be AI-generated with matching pieces
5. Good pairings can appear multiple times, but all items show at least once

### Example Scenarios

- **3 tops + 1 skirt**: All 6 outfits show that same skirt, with the 3 tops distributed (top1: 2x, top2: 2x, top3: 2x)
- **3 shoes + 1 top**: All 6 outfits show that top, with shoes alternating (shoe1: 3x or 2x or 1x, shoe2: 2x or 1x shoe3: 2x or 1x but at leaset once each in all 6), bottoms can vary (AI-generated matching)
- **4 shoes + 1 dress**: All 6 outfits show that dress, with 4 shoes appearing at least once, some repeated
- **2 tops + 2 bottoms**: All 4 combinations shown once (top1+bottom1, top1+bottom2, top2+bottom1, top2+bottom2), then repeat 2 best pairings

## Implementation Plan

### Phase 1: Rewrite Combination Logic

**File**: `lib/core/utils/gemini_api_service_new.dart`

**Replace** `_composeOutfitCombinations` (lines 891-1101) with new algorithm:

```dart
static List<_OutfitCombination> _composeOutfitCombinations(
  List<ClothingAnalysis> items,
) {
  // Step 1: Categorize ALL uploaded items
  final categoryMap = {
    'tops': items.where((item) => item.itemType.toLowerCase().contains('top')).toList(),
    'bottoms': items.where((item) => item.itemType.toLowerCase().contains('bottom')).toList(),
    'dresses': items.where((item) => item.itemType.toLowerCase().contains('dress')).toList(),
    'shoes': items.where((item) => item.itemType.toLowerCase().contains('shoe') || 
                                    item.itemType.toLowerCase().contains('footwear')).toList(),
    'outerwear': items.where((item) => item.itemType.toLowerCase().contains('outer')).toList(),
    'accessories': items.where((item) => item.itemType.toLowerCase().contains('accessory')).toList(),
  };
  
  // Step 2: Identify uploaded vs unuploaded categories
  final uploadedCategories = categoryMap.entries
      .where((entry) => entry.value.isNotEmpty)
      .map((entry) => entry.key)
      .toList();
  
  // Step 3: Generate exhaustive combinations
  final combinations = _generateExhaustiveCombinations(categoryMap, uploadedCategories);
  
  // Step 4: Balance distribution to ensure all items appear
  final balancedCombinations = _balanceDistribution(combinations, categoryMap);
  
  // Step 5: Limit to 6 outfits
  return balancedCombinations.take(6).toList();
}
```

**Add new helper method** `_generateExhaustiveCombinations`:

```dart
static List<_OutfitCombination> _generateExhaustiveCombinations(
  Map<String, List<ClothingAnalysis>> categoryMap,
  List<String> uploadedCategories,
) {
  final combinations = <_OutfitCombination>[];
  
  // Handle dress as special case (dress replaces top+bottom)
  if (categoryMap['dresses']!.isNotEmpty) {
    for (final dress in categoryMap['dresses']!) {
      // If shoes uploaded, pair with each shoe
      if (categoryMap['shoes']!.isNotEmpty) {
        for (final shoe in categoryMap['shoes']!) {
          combinations.add(_OutfitCombination(
            items: [dress, shoe],
            uploadedItems: [dress, shoe],
            unuploadedCategories: ['outerwear', 'accessories'],
            metadata: {
              'styleLabel': 'elegant evening',
              'description': '${dress.primaryColor} dress with ${shoe.primaryColor} ${shoe.itemType}',
            },
          ));
        }
      } else {
        // No shoes uploaded, let AI generate
        combinations.add(_OutfitCombination(
          items: [dress],
          uploadedItems: [dress],
          unuploadedCategories: ['shoes', 'outerwear', 'accessories'],
          metadata: {
            'styleLabel': 'dress ensemble',
            'description': '${dress.primaryColor} dress styling',
          },
        ));
      }
    }
  }
  // Handle top + bottom combinations
  else {
    final tops = categoryMap['tops']!;
    final bottoms = categoryMap['bottoms']!;
    final shoes = categoryMap['shoes']!;
    
    // Generate all top+bottom pairs
    if (tops.isNotEmpty && bottoms.isNotEmpty) {
      for (final top in tops) {
        for (final bottom in bottoms) {
          final uploadedItems = [top, bottom];
          final unuploaded = <String>[];
          
          // If shoes uploaded, add each shoe variation
          if (shoes.isNotEmpty) {
            for (final shoe in shoes) {
              combinations.add(_OutfitCombination(
                items: [top, bottom, shoe],
                uploadedItems: [top, bottom, shoe],
                unuploadedCategories: ['outerwear', 'accessories'],
                metadata: {
                  'styleLabel': 'complete look',
                  'description': '${top.primaryColor} ${top.itemType} with ${bottom.primaryColor} ${bottom.itemType}',
                },
              ));
            }
          } else {
            // No shoes uploaded, let AI generate
            combinations.add(_OutfitCombination(
              items: [top, bottom],
              uploadedItems: [top, bottom],
              unuploadedCategories: ['shoes', 'outerwear', 'accessories'],
              metadata: {
                'styleLabel': 'styled pairing',
                'description': '${top.primaryColor} ${top.itemType} paired with ${bottom.primaryColor} ${bottom.itemType}',
              },
            ));
          }
        }
      }
    }
    // Only tops uploaded (no bottoms)
    else if (tops.isNotEmpty && bottoms.isEmpty) {
      for (final top in tops) {
        // If shoes uploaded, pair each top with each shoe
        if (shoes.isNotEmpty) {
          for (final shoe in shoes) {
            combinations.add(_OutfitCombination(
              items: [top, shoe],
              uploadedItems: [top, shoe],
              unuploadedCategories: ['bottoms', 'outerwear', 'accessories'],
              metadata: {
                'styleLabel': 'top + shoe pairing',
                'description': '${top.primaryColor} ${top.itemType} with ${shoe.primaryColor} ${shoe.itemType}',
              },
            ));
          }
        } else {
          combinations.add(_OutfitCombination(
            items: [top],
            uploadedItems: [top],
            unuploadedCategories: ['bottoms', 'shoes', 'outerwear', 'accessories'],
            metadata: {
              'styleLabel': 'top styling',
              'description': 'Outfit featuring ${top.primaryColor} ${top.itemType}',
            },
          ));
        }
      }
    }
    // Only bottoms uploaded (no tops)
    else if (bottoms.isNotEmpty && tops.isEmpty) {
      for (final bottom in bottoms) {
        if (shoes.isNotEmpty) {
          for (final shoe in shoes) {
            combinations.add(_OutfitCombination(
              items: [bottom, shoe],
              uploadedItems: [bottom, shoe],
              unuploadedCategories: ['tops', 'outerwear', 'accessories'],
              metadata: {
                'styleLabel': 'bottom + shoe pairing',
                'description': '${bottom.primaryColor} ${bottom.itemType} with ${shoe.primaryColor} ${shoe.itemType}',
              },
            ));
          }
        } else {
          combinations.add(_OutfitCombination(
            items: [bottom],
            uploadedItems: [bottom],
            unuploadedCategories: ['tops', 'shoes', 'outerwear', 'accessories'],
            metadata: {
              'styleLabel': 'bottom styling',
              'description': 'Outfit featuring ${bottom.primaryColor} ${bottom.itemType}',
            },
          ));
        }
      }
    }
    // Only shoes uploaded
    else if (shoes.isNotEmpty && tops.isEmpty && bottoms.isEmpty) {
      for (final shoe in shoes) {
        combinations.add(_OutfitCombination(
          items: [shoe],
          uploadedItems: [shoe],
          unuploadedCategories: ['tops', 'bottoms', 'outerwear', 'accessories'],
          metadata: {
            'styleLabel': 'shoe spotlight',
            'description': 'Complete look featuring ${shoe.primaryColor} ${shoe.itemType}',
          },
        ));
      }
    }
  }
  
  return combinations;
}
```

**Add new helper method** `_balanceDistribution`:

```dart
static List<_OutfitCombination> _balanceDistribution(
  List<_OutfitCombination> combinations,
  Map<String, List<ClothingAnalysis>> categoryMap,
) {
  if (combinations.length >= 6) {
    // Ensure each uploaded item appears at least once
    final itemAppearances = <String, int>{};
    final selectedCombinations = <_OutfitCombination>[];
    
    // First pass: ensure each item appears at least once
    for (final category in categoryMap.entries) {
      if (category.value.isEmpty) continue;
      
      for (final item in category.value) {
        final itemId = '${item.itemType}_${item.primaryColor}_${item.subcategory}';
        if (itemAppearances[itemId] == null || itemAppearances[itemId]! == 0) {
          // Find a combination that uses this item
          final combo = combinations.firstWhere(
            (c) => c.uploadedItems.contains(item),
            orElse: () => combinations.first,
          );
          selectedCombinations.add(combo);
          
          // Mark all items in this combo as used
          for (final usedItem in combo.uploadedItems) {
            final usedId = '${usedItem.itemType}_${usedItem.primaryColor}_${usedItem.subcategory}';
            itemAppearances[usedId] = (itemAppearances[usedId] ?? 0) + 1;
          }
        }
      }
    }
    
    // Second pass: fill remaining slots with best combinations
    while (selectedCombinations.length < 6 && combinations.isNotEmpty) {
      // Pick combinations with least-used items
      final scoredCombos = combinations.map((combo) {
        var score = 0;
        for (final item in combo.uploadedItems) {
          final itemId = '${item.itemType}_${item.primaryColor}_${item.subcategory}';
          score += itemAppearances[itemId] ?? 0;
        }
        return {'combo': combo, 'score': score};
      }).toList();
      
      // Sort by score (lower score = less used items = pick this)
      scoredCombos.sort((a, b) => (a['score'] as int).compareTo(b['score'] as int));
      
      final bestCombo = scoredCombos.first['combo'] as _OutfitCombination;
      selectedCombinations.add(bestCombo);
      
      // Update appearances
      for (final item in bestCombo.uploadedItems) {
        final itemId = '${item.itemType}_${item.primaryColor}_${item.subcategory}';
        itemAppearances[itemId] = (itemAppearances[itemId] ?? 0) + 1;
      }
    }
    
    return selectedCombinations;
  } else {
    // Less than 6 combinations, repeat to reach 6
    final repeated = <_OutfitCombination>[];
    for (int i = 0; i < 6; i++) {
      repeated.add(combinations[i % combinations.length]);
    }
    return repeated;
  }
}
```

**Update** `_OutfitCombination` class (line 1616-1621):

```dart
class _OutfitCombination {
  const _OutfitCombination({
    required this.items,
    required this.uploadedItems,  // NEW: explicit list of uploaded items to use
    required this.unuploadedCategories,  // NEW: categories to AI-generate
    required this.metadata,
  });

  final List<ClothingAnalysis> items;
  final List<ClothingAnalysis> uploadedItems;  // NEW
  final List<String> unuploadedCategories;  // NEW
  final Map<String, Object?> metadata;
}
```

### Phase 2: Fix Prompt to Prevent Blending

**File**: `lib/core/utils/gemini_api_service_new.dart`

**Update** `_buildMannequinPrompt` signature and implementation (lines 699-830):

```dart
static String _buildMannequinPrompt({
  required List<ClothingAnalysis> uploadedItemsToUse,  // CHANGED: only items for THIS outfit
  required List<String> unuploadedCategories,  // NEW: categories to AI-generate
  String? userNotes,
  String? desiredStyle,
  String? pairingNotes,
  String gender = 'male',
}) {
  final buffer = StringBuffer();
  
  buffer.writeln('🚨🚨🚨 CRITICAL INSTRUCTION: USE ONLY THE UPLOADED ITEMS LISTED BELOW 🚨🚨🚨');
  buffer.writeln('DO NOT replace uploaded items with similar alternatives.');
  buffer.writeln('DO NOT blend multiple items from the same category.');
  buffer.writeln('DO NOT create new versions of uploaded items.');
  buffer.writeln();
  
  buffer.writeln('You are creating ONE complete outfit with:');
  buffer.writeln();
  
  // List ONLY the items to use in THIS specific outfit
  buffer.writeln('UPLOADED ITEMS TO USE (MANDATORY - DO NOT CHANGE THESE):');
  for (final item in uploadedItemsToUse) {
    buffer.writeln('✓ ${item.itemType.toUpperCase()}: ${item.primaryColor} ${item.subcategory ?? item.itemType}');
    buffer.writeln('  - Material: ${item.material}');
    buffer.writeln('  - Fit: ${item.fit}');
    buffer.writeln('  - Pattern: ${item.patternType}');
    buffer.writeln('  🚨 USE THIS EXACT ${item.itemType.toUpperCase()} - NO SUBSTITUTIONS');
    buffer.writeln();
  }
  
  buffer.writeln('CATEGORIES TO AI-GENERATE (create matching items for these):');
  for (final category in unuploadedCategories) {
    buffer.writeln('● ${category.toUpperCase()}: Generate a matching item that complements the uploaded pieces');
  }
  buffer.writeln();
  
  buffer.writeln('🚨 CRITICAL RULES:');
  buffer.writeln('1. The uploaded items listed above MUST appear exactly as described');
  buffer.writeln('2. DO NOT create alternative versions of uploaded items');
  buffer.writeln('3. DO NOT merge or blend multiple uploaded items into one');
  buffer.writeln('4. For unuploaded categories, generate stylish matching pieces');
  buffer.writeln('5. Show COMPLETE mannequin from HEAD TO TOE - NO CROPPING');
  buffer.writeln();
  
  // Gender requirement
  final genderInstruction = gender.toLowerCase() == 'female'
      ? 'Female mannequin with feminine styling and fit'
      : 'Male mannequin with masculine styling and fit';
  buffer.writeln('Gender: $genderInstruction');
  buffer.writeln();
  
  if (userNotes != null && userNotes.isNotEmpty) {
    buffer.writeln('User preferences: $userNotes');
    buffer.writeln();
  }
  
  if (pairingNotes != null && pairingNotes.isNotEmpty) {
    buffer.writeln('Styling notes: $pairingNotes');
    buffer.writeln();
  }
  
  buffer.writeln('Create a professional full-body mannequin image showing:');
  buffer.writeln('- The exact uploaded items as the core of the outfit');
  buffer.writeln('- AI-generated complementary pieces for unuploaded categories');
  buffer.writeln('- Complete outfit from head to toe with visible footwear');
  buffer.writeln('- Professional fashion photography quality');
  buffer.writeln('- Studio lighting and clean background');
  
  return buffer.toString();
}
```

**Update all calls to** `_buildMannequinPrompt` in `generateEnhancedMannequinOutfits` (around lines 612, 486):

```dart
// OLD:
final prompt = _buildMannequinPrompt(
  uploadedItems: combo.items,  // This passed ALL items
  userNotes: userNotes,
  desiredStyle: styleLabel,
  pairingNotes: combo.metadata['pairingNotes'] as String?,
  gender: gender,
);

// NEW:
final prompt = _buildMannequinPrompt(
  uploadedItemsToUse: combo.uploadedItems,  // Only items for THIS outfit
  unuploadedCategories: combo.unuploadedCategories,  // Categories to AI-generate
  userNotes: userNotes,
  desiredStyle: styleLabel,
  pairingNotes: combo.metadata['pairingNotes'] as String?,
  gender: gender,
);
```

### Phase 3: Add Distribution Logging

**File**: `lib/core/utils/gemini_api_service_new.dart`

**Add logging** in `generateEnhancedMannequinOutfits` after combinations are generated (around line 596):

```dart
final combinations = _composeOutfitCombinations(items);

// NEW: Log distribution for transparency
final distributionLog = <String, int>{};
for (final combo in combinations.take(6)) {
  for (final item in combo.uploadedItems) {
    final key = '${item.itemType}: ${item.primaryColor} ${item.subcategory ?? ""}';
    distributionLog[key] = (distributionLog[key] ?? 0) + 1;
  }
}

AppLogger.info(
  '📊 Outfit distribution across 6 generations:',
  data: distributionLog,
);
```

### Phase 4: Update Image Passing Strategy

**File**: `lib/core/utils/gemini_api_service_new.dart`

**Update** `_callImagePreview` (lines 833-889) to handle primary item image:

```dart
// In generateEnhancedMannequinOutfits, when calling _callImagePreview:
// OLD:
final primaryImagePath = combo.items
    .firstWhere((item) => item.imagePath != null)
    .imagePath;

// NEW: Use the first uploaded item's image (most important piece)
final primaryImagePath = combo.uploadedItems.isNotEmpty
    ? combo.uploadedItems.first.imagePath
    : combo.items.firstWhere((item) => item.imagePath != null).imagePath;
```

The current approach of passing one primary image + detailed text prompt should work well since we're now being explicit about which items to use.

### Testing Scenarios

After implementation, test with:

1. **3 tops + 1 skirt** → All 6 should show same skirt, tops distributed
2. **2 shoes + 1 top** → All 6 should show same top, shoes alternating, bottoms vary
3. **2 tops + 2 bottoms** → All 4 combinations appear, 2 repeated
4. **1 dress only** → All 6 show same dress with varying AI-generated shoes/accessories
5. **4 shoes + 1 top + 1 bottom** → All 6 show same top+bottom, 4 shoes appear at least once

## Summary of Changes

1. Complete rewrite of `_composeOutfitCombinations` with exhaustive pairing logic
2. New `_generateExhaustiveCombinations` helper for all possible pairings
3. New `_balanceDistribution` helper to ensure all items appear at least once
4. Updated `_OutfitCombination` class with `uploadedItems` and `unuploadedCategories` fields
5. Rewritten `_buildMannequinPrompt` to be explicit about which items to use vs. AI-generate
6. Added distribution logging for transparency
7. Updated image selection to prioritize uploaded items

This will ensure perfect outfit generation with no item blending, replacement, or missing items.

Dont overprompt, Keep it perfect matching and working

### To-dos

- [ ] Rewrite _composeOutfitCombinations method with new exhaustive pairing algorithm
- [ ] Create _generateExhaustiveCombinations helper method for all possible item pairings
- [ ] Create _balanceDistribution helper method to ensure all uploaded items appear at least once
- [ ] Update _OutfitCombination class to include uploadedItems and unuploadedCategories fields
- [ ] Rewrite _buildMannequinPrompt to explicitly list only items for current outfit and prevent blending
- [ ] Update all calls to _buildMannequinPrompt to pass uploadedItems and unuploadedCategories
- [ ] Add logging to show item distribution across 6 generations for transparency
- [ ] Update image selection logic to prioritize uploaded items over all items
- [ ] Test all scenarios: 3 tops + 1 skirt, 2 shoes + 1 top, 2 tops + 2 bottoms, 1 dress only, 4 shoes + 1 top + 1 bottom