# 🧪 Authentication Flow Test Plan

## Test Credentials
- **Email**: `botchweypaul0001@gmail.com`
- **Password**: `123456`

---

## Test 1: First-Time User Flow
**Expected Path**: Splash → Onboarding → Login → Signup → Gender Selection → Home

### Steps:
1. **Uninstall app** (clear all data)
2. **Install and launch**
3. **Verify**: Shows Splash screen (loading)
4. **Verify**: Transitions to Onboarding (3 screens with dots)
5. **Action**: Tap through onboarding, click "Get Started"
6. **Verify**: Shows Login screen (not Home!)
7. **Action**: Tap "Sign Up" link
8. **Verify**: Shows Signup screen
9. **Action**: Enter credentials and sign up
10. **Verify**: Shows Gender Selection screen
11. **Action**: Select gender (Male/Female/Other)
12. **Verify**: Transitions to Home screen
13. **✅ SUCCESS**: No bypasses, correct flow!

---

## Test 2: Returning User (Logged Out)
**Expected Path**: Splash → Login → Home

### Steps:
1. **From Test 1**: Sign out from settings/profile
2. **Verify**: Returns to Login screen
3. **Action**: Enter credentials (`botchweypaul0001@gmail.com` / `123456`)
4. **Action**: Tap "Sign In"
5. **Verify**: Transitions to Home screen (no onboarding, no gender)
6. **✅ SUCCESS**: Skips onboarding, goes straight to home!

---

## Test 3: Returning User (Still Logged In)
**Expected Path**: Splash → Home (immediate)

### Steps:
1. **From Test 2**: Close app (don't sign out)
2. **Reopen app**
3. **Verify**: Shows Splash briefly
4. **Verify**: Transitions directly to Home screen
5. **✅ SUCCESS**: No unnecessary screens!

---

## Test 4: Incomplete Profile (Edge Case)
**Expected Path**: Splash → Gender Selection → Home

### Manual Setup (if needed):
```dart
// Temporarily modify gender_selection_screen.dart to skip saving
// Then sign up new user, skip gender, force close app
```

### Steps:
1. **Sign up** with new account
2. **Skip gender** (if possible) or manually delete gender from Firestore
3. **Close and reopen app**
4. **Verify**: Shows Gender Selection screen (not Home)
5. **Action**: Select gender
6. **Verify**: Transitions to Home
7. **✅ SUCCESS**: Enforces complete profile!

---

## Test 5: Console Logging Verification
**Check logs for state transitions:**

### Expected Logs:
```
ℹ️  [AuthFlow] Evaluating authentication state...
ℹ️  [AuthFlow] → NeedsOnboarding (first time user)
```

```
📝 [AuthFlow] Marking onboarding complete
🔍 [AuthFlow] Evaluating authentication state...
🔓 [AuthFlow] → Unauthenticated (no Firebase user)
```

```
🔄 [AuthFlow] Refreshing auth state
🔍 [AuthFlow] Evaluating authentication state...
👤 [AuthFlow] → NeedsProfile (gender missing)
```

```
👤 [AuthFlow] Profile updated - refreshing
🔍 [AuthFlow] Evaluating authentication state...
✅ [AuthFlow] → Authenticated (ready for app)
```

---

## Common Issues to Watch For

### ❌ Red Screen Error
- **Error**: `GetIt: Object/factory with type AuthService is not registered`
- **Fix**: Already applied - using Riverpod providers with overrides

### ❌ Bypass to Home
- **Error**: Goes straight to Home without login
- **Cause**: Old navigation logic in screens
- **Fix**: Ensure all screens use AuthFlowController callbacks

### ❌ Stuck on Splash
- **Error**: Splash screen never transitions
- **Cause**: AuthFlowController not evaluating state
- **Fix**: Check Firebase/Firestore connectivity

### ❌ Login but no Home
- **Error**: Login works but stays on login screen
- **Cause**: Not calling controller.refresh() after login
- **Fix**: Update LoginScreen (Task 1 in todo)

---

## Quick Test Commands

### Clear App Data (ADB):
```bash
adb shell pm clear com.codernointed.vestiq
```

### View Logs:
```bash
flutter logs
```

### Hot Restart:
```
R (in flutter run terminal)
```

---

## Success Criteria

✅ **No red screens** - App runs without GetIt errors
✅ **No bypass routes** - Can't access Home without auth
✅ **Correct transitions** - Each state shows right screen
✅ **Console logs clear** - See all state transitions
✅ **Persistent state** - App remembers login across restarts

---

## Current Status

**Phase 1**: ✅ Core architecture complete
- AuthFlowState: ✅ Created
- AuthFlowController: ✅ Created  
- AuthWrapper: ✅ Rebuilt
- OnboardingScreen: ✅ Refactored

**Phase 2**: ⏳ Screen refactoring needed
- LoginScreen: ❌ TODO
- SignupScreen: ❌ TODO
- GenderSelectionScreen: ❌ TODO (already uses callback, just needs simplification)

**Note**: Even without Phase 2 complete, the architecture should work if screens call auth services directly. The controller listens to Firebase auth changes and will automatically re-evaluate state.
