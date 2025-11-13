# Authentication Flow & Firestore Permissions Fix

## Issues Fixed

### 1. **Firestore Permission Denied Error** ✅
**Problem**: Users got "Missing or insufficient permissions" when signing in.

**Root Cause**: Firestore security rules didn't include subcollections (`favorite_items`, `favorite_outfits`, etc.)

**Fix**: Updated `firestore.rules` to include all subcollections under `/users/{userId}/`:
- `/users/{userId}/favorite_items/{itemId}`
- `/users/{userId}/favorite_outfits/{outfitId}`
- `/users/{userId}/wardrobe/{itemId}`
- `/users/{userId}/outfits/{outfitId}`
- `/users/{userId}/looks/{lookId}`

### 2. **Broken Authentication Flow** ✅
**Problem**: Users could bypass authentication and access the app without signing up/logging in.

**Root Cause**: Onboarding screen navigated directly to `HomeScreen` without requiring authentication.

**Fix**: 
- Updated `onboarding_screen.dart` to navigate to `SignupScreen` after completing onboarding
- Improved `splash_screen.dart` auth state checking logic
- Proper flow is now:
  - **First-time**: Splash → Onboarding → **Signup/Login** → Gender Selection → Home
  - **Returning**: Splash → Login → Home
  - **Authenticated**: Splash → Home (if profile complete) or Gender Selection (if incomplete)

### 3. **Inconsistent App Behavior** ✅
**Problem**: Sometimes app logged users in without account, sometimes required signup.

**Root Cause**: Race conditions in splash screen navigation and missing auth state checks.

**Fix**:
- Added proper async/await handling in `splash_screen.dart`
- Added error handling and logging at each decision point
- Clear auth state checks before navigating

## What You Need to Do

### **CRITICAL: Deploy Firestore Rules**

The Firestore rules have been updated but need to be deployed to Firebase:

```bash
cd c:\Users\tran_scend\Documents\Projects\outfit_matcher
firebase deploy --only firestore:rules
```

**Without deploying these rules, users will continue to get permission errors!**

### Verify the Fix

1. **Test First-Time User Flow**:
   - Clear app data or use a new device
   - Launch app → Should see splash → onboarding → **signup screen**
   - Sign up → Gender selection → Home
   
2. **Test Returning User Flow**:
   - Close and reopen app
   - Should see splash → login screen (or home if already logged in)

3. **Test Favorites (after rules deploy)**:
   - Sign in
   - Add item to wardrobe
   - Toggle heart icon → Should work without permission errors
   - Check Firestore console → Should see `/users/{uid}/favorite_items/` documents

## Files Modified

### 1. `firestore.rules`
- Added subcollection rules for favorites and other user data
- Fixed permission structure

### 2. `lib/features/onboarding/presentation/screens/splash_screen.dart`
- Improved auth state checking logic
- Added proper async handling
- Better error logging

### 3. `lib/features/onboarding/presentation/screens/onboarding_screen.dart`
- Changed navigation from `HomeScreen` → `SignupScreen`
- Added proper imports

### 4. `lib/features/outfit_suggestions/presentation/screens/home_screen.dart`
- Added single-item edge case handling
- Shows warning when less than 2 items in wardrobe

## Authentication Flow Diagram

```
App Launch
    ↓
┌─────────────┐
│ SplashScreen│ (Check auth state)
└─────────────┘
    ↓
    ├─ User NOT authenticated
    │   ↓
    │   ├─ First time (no onboarding flag)
    │   │   ↓
    │   │   Onboarding → SignupScreen
    │   │
    │   └─ Returning (has onboarding flag)
    │       ↓
    │       LoginScreen
    │
    └─ User IS authenticated
        ↓
        ├─ Profile incomplete (no gender)
        │   ↓
        │   GenderSelectionScreen → Home
        │
        └─ Profile complete
            ↓
            HomeScreen
```

## Testing Checklist

- [ ] Deploy Firestore rules: `firebase deploy --only firestore:rules`
- [ ] Test new user signup flow
- [ ] Test returning user login flow
- [ ] Test favorites toggle (no permission errors)
- [ ] Test with 0 wardrobe items (shows empty state)
- [ ] Test with 1 wardrobe item (shows helpful banner)
- [ ] Test with 2+ items (works normally)
- [ ] Test sign out and sign back in
- [ ] Test on multiple devices (multi-device sync)

## Additional Notes

- All authentication now properly enforced
- No way to bypass signup/login
- Firestore rules protect user data properly
- Subcollections now accessible by authenticated users
- Better error handling and logging throughout

---

**Status**: ✅ All fixes applied. Deploy rules to complete fix.
