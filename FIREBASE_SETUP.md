# 🔥 Firebase Setup Guide for Vestiq

## ✅ Completed Steps

1. **Firebase Project Created**: `vestiq-app` (Project #722272019813)
2. **FlutterFire Configured**: All platforms registered (Android, iOS, Web, macOS, Windows)
3. **Firebase CLI**: Authenticated and project selected
4. **Firestore Rules**: Created and ready to deploy
5. **Firestore Indexes**: Created and ready to deploy

---

## 🚀 Manual Steps Required (Do These Now)

### Step 1: Enable Firestore Database

The browser should have opened to: https://console.firebase.google.com/project/vestiq-app/firestore

1. Click **"Create Database"**
2. Choose **"Start in production mode"** (we have custom rules)
3. Select **Cloud Firestore location**: Choose **europe-west2** (London - closest to Ghana)
4. Click **"Enable"**

### Step 2: Enable Authentication Providers

The browser should have opened to: https://console.firebase.google.com/project/vestiq-app/authentication/providers

1. **Enable Email/Password**:
   - Click on "Email/Password"
   - Toggle **Enable** switch
   - Click **Save**

2. **Enable Google Sign-In**:
   - Click on "Google"
   - Toggle **Enable** switch
   - Enter Project support email
   - Click **Save**

3. **Configure Google Sign-In for Android** (Important for mobile):
   - Go to Authentication > Settings
   - Scroll to "Authorized domains"
   - Add any custom domains if needed

---

## 🔐 Deploy Firestore Rules (Run After Enabling Firestore)

Once Firestore is enabled, run this command:

```bash
firebase deploy --only firestore
```

This will deploy:
- **Security rules** from `firestore.rules`
- **Indexes** from `firestore.indexes.json`

---

## 📋 Firestore Security Rules Overview

Our security rules ensure:
- ✅ Users can only read/write their own profile
- ✅ Users can only access their own wardrobe items
- ✅ Users can only access their own outfits and looks
- ✅ Public profiles can be read by authenticated users
- ✅ All operations require authentication

---

## 🎯 Test Authentication Flow

After completing the manual steps, test the app:

```bash
flutter run
```

You should see:
1. **Login Screen** with Lottie animation
2. **Sign Up** option
3. **Google Sign-In** button
4. After signup: Email verification prompt
5. After login: Main app (splash → home)

---

## 🔍 Verify Setup in Firebase Console

### Check Users
https://console.firebase.google.com/project/vestiq-app/authentication/users

- Should show users after signup

### Check Firestore Data
https://console.firebase.google.com/project/vestiq-app/firestore/data

- Should show `users` collection after first signup
- Each user document contains all profile data

### Check Firestore Rules
https://console.firebase.google.com/project/vestiq-app/firestore/rules

- Should show the deployed rules from `firestore.rules`

---

## 🛠️ Useful Firebase CLI Commands

```bash
# View current project
firebase projects:list

# Switch project
firebase use vestiq-app

# Deploy only Firestore
firebase deploy --only firestore

# Deploy only Firestore rules (faster)
firebase deploy --only firestore:rules

# Deploy only Firestore indexes
firebase deploy --only firestore:indexes

# Open Firebase console
firebase open

# Open specific Firebase service
firebase open auth
firebase open firestore
```

---

## 📊 User Profile Data Structure

Each user document in Firestore contains:

```typescript
{
  // Authentication
  uid: string
  email: string
  username: string
  displayName: string
  photoUrl: string?
  authProvider: 'email' | 'google' | 'apple' | 'phone'
  createdAt: timestamp
  lastLoginAt: timestamp
  isEmailVerified: boolean
  
  // Profile
  gender: string?
  bio: string?
  dateOfBirth: timestamp?
  location: string?
  country: string?
  
  // Usage Stats
  totalGenerations: number (default: 0)
  todayGenerations: number (default: 0)
  lastGenerationDate: timestamp?
  wardrobeItemCount: number (default: 0)
  savedOutfitCount: number (default: 0)
  favoriteCount: number (default: 0)
  
  // Subscription
  subscriptionTier: 'free' | 'plus' | 'pro' (default: 'free')
  subscriptionExpiryDate: timestamp?
  generationsLimit: number (default: 5 for free)
  wardrobeItemLimit: number (default: 30 for free)
  
  // Preferences
  preferences: {
    showWelcomeTips: boolean
    autoSavePairings: boolean
    highQualityImages: boolean
    analyticsEnabled: boolean
    defaultPairingMode: string
    enableMannequinGeneration: boolean
    enableFlatLayGeneration: boolean
    enableVisualSearch: boolean
  }
  
  // Style Profile
  preferredStyles: string[]
  preferredColors: string[]
  preferredOccasions: string[]
  bodyType: string?
  stylePersonality: string?
  
  // Settings
  notificationsEnabled: boolean
  emailNotificationsEnabled: boolean
  themeMode: 'light' | 'dark' | 'system'
  language: string (default: 'en')
  
  // Social (future)
  followingIds: string[]
  followerIds: string[]
  isPublicProfile: boolean
  
  // Analytics
  featureUsageCount: { [feature: string]: number }
  lastActiveDate: timestamp?
  totalAppOpenCount: number
  totalSessionDuration: number (in minutes)
}
```

---

## 🎨 Collection Structure

```
Firestore
└── users (collection)
    └── {userId} (document)
        ├── wardrobe (subcollection)
        │   └── {itemId} (document)
        ├── outfits (subcollection)
        │   └── {outfitId} (document)
        ├── looks (subcollection)
        │   └── {lookId} (document)
        └── favorites (subcollection)
            └── {favoriteId} (document)
```

---

## ⚠️ Important Notes

1. **Region Selection**: Choose **europe-west2** (London) for Firestore - closest to Ghana
2. **Email Verification**: Users receive verification emails after signup
3. **Google Sign-In**: Requires SHA-1/SHA-256 fingerprints for Android production
4. **Free Tier Limits**: 
   - 5 generations per day
   - 30 wardrobe items max
5. **Firestore Quotas**: 
   - 50K reads/day (free tier)
   - 20K writes/day (free tier)
   - 1GB storage (free tier)

---

## 🐛 Troubleshooting

### "Firestore API not enabled"
Run the enable command or use the console link above

### "Google Sign-In not working"
- Check SHA fingerprints in Firebase Console
- Verify OAuth consent screen is configured
- Check google-services.json is updated

### "Rules deployment failed"
```bash
# Check rules syntax
firebase firestore:rules:get

# Force deploy
firebase deploy --only firestore --force
```

### "User profile not created"
- Check Firestore rules are deployed
- Check Firebase Auth is enabled
- Check console logs for errors

---

## 📞 Support

If you encounter issues:
1. Check Firebase Console for error messages
2. Check Flutter logs: `flutter logs`
3. Check Firestore rules match the deployed version
4. Verify all Firebase services are enabled

---

**Created**: November 12, 2025
**Last Updated**: November 12, 2025
