# Mannequin Generation - API Flow Confirmed & Improvements Applied ✅

## API Call Flow Confirmation

### ✅ **Confirmed: 6 Separate API Calls**

When a user taps **"Get Outfit Ideas"**, here's exactly what happens:

```
User uploads: 1 red jersey top
↓
System creates outfit combinations (6 variations)
↓
📞 API Call #1: "red jersey + casual bottoms" → 1 mannequin image → Wait 400ms
📞 API Call #2: "red jersey + business bottoms" → 1 mannequin image → Wait 400ms
📞 API Call #3: "red jersey + trendy bottoms" → 1 mannequin image → Wait 400ms
📞 API Call #4: "red jersey + sporty bottoms" → 1 mannequin image → Wait 400ms
📞 API Call #5: "red jersey + date night bottoms" → 1 mannequin image → Wait 400ms
📞 API Call #6: "red jersey + weekend bottoms" → 1 mannequin image → Wait 400ms
↓
Result: 6 mannequin images from 6 separate API calls
```

### Technical Flow:

```dart
// Loop 6 times - each iteration = 1 API call
for (int i = 0; i < 6; i++) {
  // Build unique prompt for THIS specific look
  final prompt = _buildMannequinPrompt(
    uploadedItemsToUse: combo.uploadedItems,  // Specific items for this look
    unuploadedCategories: combo.unuploadedCategories,
    userNotes: userNotes,
    desiredStyle: styleLabel,  // Changes per look: casual, business, trendy, etc.
  );
  
  // Make ONE API call to Gemini
  final imageResult = await _callImagePreview(prompt, imageFile);
  
  // Wait 400ms before next call
  await Future.delayed(const Duration(milliseconds: 400));
}
```

### Cost Impact:

| Action | API Calls | Notes |
|--------|-----------|-------|
| 1 outfit request | **6 calls** | One per mannequin |
| Free tier (12 requests) | **72 calls/month** | 12 × 6 |
| Premium tier (100 requests) | **600 calls/month** | 100 × 6 |

**Why 6 separate calls?**
- Each look has different style (casual, business, trendy)
- Different poses (front, runway, three-quarter, etc.)
- Different item combinations from your wardrobe
- Better error handling (if one fails, others succeed)
- More control over variety

---

## Issues Fixed

### **Issue #1: Tight Jeans Overuse for Female Mannequins** 👖

**Problem:** AI defaulted to tight/fitting jeans for almost every female mannequin bottom.

**Solution:** Added specific variety guidance in `_buildMannequinPrompt`:

```dart
if (category.toLowerCase() == 'bottoms') {
  buffer.writeln(
    'BOTTOMS: Vary styles across looks - skirts (fitting, flare, short, long, bodycon), 
    trousers, shorts, wide-leg pants, baggy jeans, joggers. 
    Avoid defaulting to tight jeans every time.'
  );
}
```

**Now AI will generate:**
- ✅ Fitting skirts
- ✅ Flare skirts
- ✅ Short/long skirts
- ✅ Bodycon skirts
- ✅ Trousers
- ✅ Shorts
- ✅ Wide-leg pants
- ✅ Baggy jeans
- ✅ Baggy joggers
- ❌ Not just tight jeans!

### **Issue #2: Excessive Jacket/Layer Covering Tops** 🧥

**Problem:** 
- Jerseys with graphics/text/imprints were being covered with jackets
- AI was adding outerwear to almost every look
- User wanted maximum 2 out of 6 looks with layers

**Solution:** Smart detection + strict layering rules:

#### **Detection Logic:**
```dart
// Automatically detects if top has graphics
bool hasGraphicTop = false;
for (item in uploadedItems) {
  if (item is top) {
    if (item has graphics/jersey/prints/text) {
      hasGraphicTop = true;
      // Add warning in prompt
    }
  }
}
```

#### **Adaptive Layering Rules:**

**For Graphic/Jersey Tops:**
```
⚠️ IMPORTANT: The uploaded top has GRAPHICS/PRINTS/TEXT that MUST be visible
- DO NOT cover this top with jackets/sweaters/coats in ANY of the 6 looks
- Show the top BARE so graphics/text/designs are fully visible
```

**For Plain/Solid Tops:**
```
- Plain tops: Can have a light jacket in MAX 2 out of 6 looks
- MOST LOOKS (4-6 out of 6) should show tops WITHOUT jackets/sweaters/coats
- Outerwear should only add interest, never hide the hero piece
```

### **Additional Improvements:**

**Tops Variety Guidance:**
```
- TOPS: Vary between t-shirts, blouses, tanks, knits. Keep graphics/prints visible.
```

**Outerwear Guidance:**
```
- OUTERWEAR: Use sparingly (max 1-2 looks). Only add if it enhances the outfit 
  without hiding key details.
```

---

## How Detection Works

The system now intelligently detects graphic/printed tops by checking:

1. ✅ `patternType != 'solid'` (not a solid color)
2. ✅ Subcategory contains: "graphic", "jersey", "print"
3. ✅ Design elements contain: "graphic", "text", "logo", "print"

When detected, it:
- Adds **"⚠️ HAS GRAPHICS/PRINTS/TEXT - SHOW BARE WITHOUT JACKET"** to the item description
- Changes layering limits to **ZERO jackets** for all 6 looks
- Ensures graphics/text/designs stay fully visible

---

## What Happens Now

### Example: User uploads a graphic jersey

**Old behavior:**
- Look 1: Jersey + jeans + jacket ❌
- Look 2: Jersey + jeans + sweater ❌
- Look 3: Jersey + jeans + coat ❌
- Look 4: Jersey + jeans + cardigan ❌
- Look 5: Jersey + jeans (finally bare) ✓
- Look 6: Jersey + jeans + blazer ❌

**New behavior:**
- Look 1: Jersey (bare) + flare skirt ✅
- Look 2: Jersey (bare) + trousers ✅
- Look 3: Jersey (bare) + shorts ✅
- Look 4: Jersey (bare) + wide-leg pants ✅
- Look 5: Jersey (bare) + bodycon skirt ✅
- Look 6: Jersey (bare) + baggy jeans ✅

### Example: User uploads a plain black top

**Old behavior:**
- Look 1: Top + jeans + jacket
- Look 2: Top + jeans + jacket
- Look 3: Top + jeans + jacket
- Look 4: Top + jeans + jacket
- Look 5: Top + jeans (bare)
- Look 6: Top + jeans + jacket

**New behavior:**
- Look 1: Top (bare) + fitting skirt ✅
- Look 2: Top (bare) + trousers ✅
- Look 3: Top + blazer + bodycon skirt (layered) ✅
- Look 4: Top (bare) + shorts ✅
- Look 5: Top + cardigan + joggers (layered) ✅
- Look 6: Top (bare) + baggy jeans ✅
- **Max 2/6 with layers** ✓
- **Bottom variety** ✓

---

## Files Modified

- `lib/core/utils/gemini_api_service_new.dart`
  - Added graphic/print detection logic
  - Added bottom variety guidance (skirts, trousers, shorts, baggy options)
  - Strengthened anti-layering rules with smart detection
  - Adaptive layering limits based on top type

## Testing Recommendations

### Test Case 1: Graphic Jersey
- Upload a jersey with graphics/text
- Generate 6 looks
- **Expected:** ALL 6 looks show jersey bare, no jackets
- **Expected:** Bottoms vary (skirts, pants, shorts, joggers)

### Test Case 2: Plain Top
- Upload a solid color plain top
- Generate 6 looks
- **Expected:** MAX 2 looks have light jacket
- **Expected:** 4-6 looks show top bare
- **Expected:** Bottom variety

### Test Case 3: Female Mannequin
- Upload any top with female preference
- Generate 6 looks
- **Expected:** Not all tight jeans
- **Expected:** Mix of skirts, trousers, joggers, wide-leg pants

---

## API Call Optimization Consideration

**Current:** 6 API calls per outfit request (expensive but maximum variety)

**Alternative options if cost becomes prohibitive:**

1. **Batch generation:** 1 API call asking for "6 variations" (cheaper, less control)
2. **Hybrid:** 2-3 API calls generating 2-3 looks each (balance cost vs variety)
3. **Cached combinations:** Reuse similar outfit combos within same session

For now, keeping 6 separate calls for maximum quality and variety.

---

## Summary

✅ **Confirmed:** 6 separate API calls (one per mannequin)  
✅ **Fixed:** Bottom variety (no more just tight jeans)  
✅ **Fixed:** Smart layering detection (graphic tops always bare)  
✅ **Fixed:** Plain tops limited to max 2/6 with jackets  

Ready for testing!

