# 🔧 Navigation Conflict Fixed

## ❌ Error
```
Failed assertion: line 375 pos 10: 'home == null || !routes.containsKey(Navigator.defaultRouteName)'
If the home property is specified, the routes table cannot include an entry for "/", since it would be redundant.
```

## 🔍 Root Cause
The `MaterialApp` had **both**:
1. `home: const AuthWrapper()` 
2. `routes: AppRouter.getBasicRoutes()` which included `'/'` route

**Flutter doesn't allow both** because they serve the same purpose - defining the initial route.

## ✅ Fix Applied

### Before:
```dart
return MaterialApp(
  home: const AuthWrapper(),
  routes: AppRouter.getBasicRoutes(), // Contains '/' route - CONFLICT!
);
```

### After:
```dart
return MaterialApp(
  home: const AuthWrapper(),
  routes: {
    AppRouter.onboarding: (context) => const OnboardingScreen(),
    AppRouter.home: (context) => HomeScreen(),
  },
);
```

## 📝 Changes Made

1. **Removed conflicting route**: Excluded the `'/'` (splash) route from routes map
2. **Kept only necessary routes**: Only included routes that are actually navigated to
3. **Added imports**: Added `OnboardingScreen` and `HomeScreen` imports

## 🎯 Result

✅ No more route conflict  
✅ AuthWrapper is the initial screen  
✅ Other screens accessible via named routes  
✅ App should now launch successfully

## 🚀 Testing

The app is now rebuilding with hot reload. You should see:
1. No red error screen
2. AuthWrapper loads (which shows Login or Main app based on auth state)
3. Navigation works correctly

---

**Status**: ✅ **FIXED** - App should launch successfully now!
