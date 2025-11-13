# CRITICAL: Deploy Firestore Rules NOW

## The Problem
Your app is showing this error:
```
W/Firestore: Write failed at users/EkDFtM28D5dLip2YtDjAOFTyjMF3: 
Status{code=PERMISSION_DENIED, description=Missing or insufficient permissions., cause=null}
```

This is because the **Firestore security rules** have been updated in your code but **NOT deployed** to Firebase.

## The Fix (Takes 30 seconds)

### Step 1: Open a PowerShell terminal
Press `Ctrl + Shift + ` ` (backtick) in VS Code

### Step 2: Run this single command:
```powershell
firebase deploy --only firestore:rules
```

### Step 3: Wait for confirmation
You should see:
```
✔  firestore: rules file firestore.rules compiled successfully
✔  firestore: released rules firestore.rules to cloud.firestore
✔  Deploy complete!
```

## Why This Is Needed

The `firestore.rules` file in your project has been updated to include subcollection permissions:
- `/users/{userId}/favorite_items/{itemId}` ← **NEW**
- `/users/{userId}/favorite_outfits/{outfitId}` ← **NEW**
- `/users/{userId}/wardrobe/{itemId}`
- `/users/{userId}/outfits/{outfitId}`
- `/users/{userId}/looks/{lookId}`

Without deploying these rules, Firebase will **DENY all writes** to these subcollections, causing the permission error you're seeing.

## Test After Deploying

1. Close the app completely (swipe it away)
2. Reopen the app
3. Try to sign in again
4. **Permission errors should be gone!**

---

**DO THIS NOW before continuing!**
