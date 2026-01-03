Profile Integration
New "Replay Tutorial" option in Profile → Settings
Resets all walkthroughs so users can take the tour again
# In-App Walkthrough Feature Implementation Plan
Create an engaging, visually stunning walkthrough experience for first-time users, guiding them through the Home screen and Closet screen with modern animations and spotlight effects.
## User Review Required
> [!IMPORTANT]
> This feature will be shown to **first-time users only** after their initial login. Users can skip the walkthrough at any time, and it will not be shown again.
**Design Questions:**
1. Should the walkthrough trigger immediately after first login, or after uploading their first clothing item?
2. Do you want a "Replay Tutorial" option in settings for users who skipped?
---
## Proposed Changes
### Core Walkthrough System
#### [NEW] walkthrough_service.dart
Central service to manage walkthrough state:
- Track which walkthroughs have been completed (stored in SharedPreferences)
- Control when to trigger walkthroughs
- Methods: `shouldShowHomeWalkthrough()`, `completeHomeWalkthrough()`, etc.
#### [NEW] walkthrough_overlay.dart
The main animated overlay widget featuring:
- **Spotlight effect**: Dims entire screen except for highlighted element
- **Animated tooltip**: Speech bubble that points to the spotlighted area
- **Pulse animation**: Subtle pulsing around the spotlighted element
- **Progress indicator**: Shows "Step 1 of 5" style progress
- **Skip button**: Allow users to exit anytime
- **Smooth transitions**: Animated movement between spotlight targets
#### [NEW] walkthrough_step.dart
Model for defining walkthrough steps:
```dart
class WalkthroughStep {
  final GlobalKey targetKey;     // Key of element to spotlight
  final String title;            // Step title ("Your Wardrobe")
  final String description;      // Explanation text
  final EdgeInsets tooltipPadding;
  final TooltipPosition position; // above, below, left, right
}
```
### Home Screen Walkthrough
[MODIFY] home_screen.dart
Add GlobalKeys to spotlight targets and integrate walkthrough:

Spotlight Targets (5 steps):

- Hero Section - "Welcome to Vestiq! 👋" - Introduce the app
- Quick Actions Cards - "Get instant outfit ideas" - Explain occasion-based suggestions
- Primary CTA Button - "Start building your wardrobe" - Highlight upload action
- Your Wardrobe Section - "Your digital closet" - Preview of uploaded items
- Bottom Navigation - "Navigate the app" - Explain the four main tabs
### Closet Screen Walkthrough
[MODIFY] enhanced_closet_screen.dart
Add GlobalKeys and integrate walkthrough:

Spotlight Targets (4 steps):

- Category Tabs - "Filter by category" - Show category filtering
- Item Card - "Tap to preview" - Explain tap/long-press actions
- Search Bar - "Find items fast" - Highlight search functionality
- Swipe Planner Button - "Plan outfits" - Advanced feature intro
### Animation Specifications
Spotlight Animation:

- Fade in: 300ms ease-out
- Hole expansion: 400ms with elastic curve
- Pulse ring: 1.5s infinite loop, 10% scale increase
Tooltip Animation:

- Slide in from edge: 350ms with bounceOut curve
- Text fade in: 200ms after tooltip appears
Step Transition:

- Cross-fade: 250ms
- Spotlight morph: 400ms (shape transitions smoothly between targets)
### Verification Plan
Manual Testing (User Required)
Since this is a visual/UX feature with complex animations, automated testing is limited. The verification will primarily be manual:

Test Steps:

- Clear app data or use a new user account
- Complete signup/login flow
- Verify Home walkthrough appears with 5 steps:
  - Each spotlight highlights the correct element
  - Tooltip text is readable and positioned correctly
  - "Next" button advances to next step
  - "Skip" button closes walkthrough
  - Progress indicator shows correct step count
- Navigate to Closet screen
- Verify Closet walkthrough appears with 4 steps
- Complete walkthrough, then restart app
- Verify walkthrough does NOT appear again (persistence works)
Code Quality Verification
Run Flutter analyze to check for any errors:

```
flutter analyze lib/core/services/walkthrough_service.dart lib/core/widgets/walkthrough_overlay.dart
```
Visual Verification
After implementation, I will capture screenshots or a screen recording demonstrating:

- Spotlight effect with dimmed background
- Tooltip positioning and animations
- Smooth transitions between steps
### Implementation Order
1. Create WalkthroughStep model
2. Create WalkthroughService for state management
3. Build WalkthroughOverlay widget with animations
4. Add GlobalKeys to Home screen targets
5. Integrate walkthrough into Home screen
6. Add GlobalKeys to Closet screen targets
7. Integrate walkthrough into Closet screen
8. Test complete flow
9. Polish animations and timing
### Files Summary
Action | File
NEW | lib/core/models/walkthrough_step.dart
NEW | lib/core/services/walkthrough_service.dart
NEW | lib/core/widgets/walkthrough_overlay.dart
MODIFY | lib/features/outfit_suggestions/presentation/screens/home_screen.dart
MODIFY | lib/features/wardrobe/presentation/screens/enhanced_closet_screen.dart
