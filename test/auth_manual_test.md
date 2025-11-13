# Manual Auth Flow Testing Guide

## Prerequisites
- App must be running on a device/emulator
- Firebase project must be configured
- Google Sign-In must be configured (optional)

## Test Scenarios

### 1. Fresh Install - Onboarding → Signup Flow
**Steps:**
1. Clear app data or fresh install
2. Launch app
3. Verify: Splash screen appears
4. Verify: Onboarding screens appear (swipe through)
5. Tap "Get Started" on last onboarding screen
6. Verify: Login screen appears with "Create Account" option
7. Tap "Create Account"
8. Verify: Signup screen appears
9. Fill in email, password, confirm password
10. Tap "Sign Up"
11. Verify: Profile creation screen appears (3 steps)
12. Enter name → Continue
13. Select gender → Continue
14. (Optional) Select photo → Complete Profile
15. Verify: Home screen appears with user logged in

**Expected Behavior:**
- ✅ Smooth transition from onboarding → login → signup → profile creation → home
- ✅ No infinite loading
- ✅ Profile saves successfully to Firestore
- ✅ Gender preference saved locally

**Common Issues:**
- ❌ "Failed to save profile" → Check UserProfileService registration in service_locator
- ❌ Stuck on profile screen → Check onComplete callback
- ❌ Goes back to onboarding → Check SharedPreferences onboarding flag

---

### 2. Email Login Flow
**Steps:**
1. Log out from app (if logged in)
2. Launch app
3. Verify: Login screen appears directly (onboarding completed)
4. Enter valid email and password
5. Tap "Sign In"
6. Verify: Home screen appears

**Expected Behavior:**
- ✅ Direct to login (skip onboarding)
- ✅ Skip profile creation if gender already set
- ✅ Fast authentication

**Common Issues:**
- ❌ Wrong email/password → Show error message
- ❌ Network error → Show retry option

---

### 3. Forgot Password Flow
**Steps:**
1. On login screen, tap "Forgot Password?"
2. Verify: Dialog appears with email input
3. Enter email address
4. Tap "Send Reset Email"
5. Verify: Success message appears
6. Check email inbox for reset link
7. Click reset link
8. Set new password
9. Return to app and login with new password

**Expected Behavior:**
- ✅ Password reset email sent via Firebase
- ✅ Success feedback shown
- ✅ Can login with new password

**Common Issues:**
- ❌ Email not sent → Check Firebase console
- ❌ Invalid email → Show validation error

---

### 4. Google Sign-In Flow (if configured)
**Steps:**
1. On login or signup screen, tap Google icon button
2. Verify: Google account picker appears
3. Select Google account
4. Grant permissions
5. Verify: Returns to app
6. If first time: Profile creation screen appears
7. If returning: Home screen appears

**Expected Behavior:**
- ✅ Google OAuth flow completes
- ✅ User profile created/fetched from Firestore
- ✅ Smooth transition to home or profile creation

**Common Issues:**
- ❌ "No Google account selected" → User cancelled
- ❌ Google Sign-In not configured → Check SHA-1 in Firebase console
- ❌ Network error → Check internet connection

---

### 5. Returning User Flow
**Steps:**
1. User has completed onboarding and profile previously
2. Close and reopen app
3. Verify: Directly goes to home screen (no onboarding, no profile creation)

**Expected Behavior:**
- ✅ Skip onboarding
- ✅ Skip profile creation
- ✅ Auth state restored from Firebase

---

### 6. Logged Out User Flow
**Steps:**
1. User logs out
2. Verify: Redirected to login screen
3. Verify: No onboarding shown
4. Login again
5. Verify: Home screen appears

**Expected Behavior:**
- ✅ Skip onboarding (already completed)
- ✅ Login works
- ✅ Profile data persists

---

## Auth Flow State Transitions

```
First Launch:
Splash → Onboarding → Login → Signup → Profile Creation → Home

Returning User (logged in):
Splash → Home

Returning User (logged out):
Splash → Login → Home (if profile complete)
Splash → Login → Profile Creation → Home (if profile incomplete)

Forgot Password:
Login → Forgot Password Dialog → Email Sent → Login

Google Sign-In (new):
Login → Google Picker → Profile Creation → Home

Google Sign-In (returning):
Login → Google Picker → Home
```

---

## Code Locations

**Auth Service:** `lib/features/auth/domain/services/auth_service.dart`
- `signUpWithEmail()`
- `signInWithEmail()`
- `signInWithGoogle()`
- `sendPasswordResetEmail()`

**Auth Flow Controller:** `lib/features/auth/presentation/providers/auth_flow_controller.dart`
- Evaluates: onboarding completion, auth status, profile completeness

**Screens:**
- Login: `lib/features/auth/presentation/screens/login_screen.dart`
- Signup: `lib/features/auth/presentation/screens/signup_screen.dart`
- Profile Creation: `lib/features/onboarding/presentation/screens/profile_creation_screen.dart`
- Onboarding: `lib/features/onboarding/presentation/screens/onboarding_screen.dart`

**Auth Wrapper:** `lib/features/auth/presentation/widgets/auth_wrapper.dart`
- Routes based on AuthFlowState

---

## Testing Checklist

- [ ] Fresh install onboarding → signup works
- [ ] Email login works
- [ ] Forgot password sends email
- [ ] Google sign-in works (if configured)
- [ ] Returning user skips onboarding
- [ ] Profile creation saves successfully
- [ ] No infinite loading states
- [ ] Error messages display correctly
- [ ] Auth state persists across app restarts
