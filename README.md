# Outfit Matcher

A mobile app that helps users find outfit combinations based on photos of their clothing items.

## Features

- **Photo Upload**: Take photos of clothing items or upload from your gallery
- **Item Organization**: Categorize items by type, color, and occasion
- **Smart Suggestions**: Get AI-powered outfit recommendations based on color theory and style matching
- **Virtual Closet**: Keep track of all your clothing items in one place
- **Outfit Saving**: Save your favorite outfits for quick access

## Getting Started

### Prerequisites

- Flutter (2.10.0 or higher)
- Dart (2.16.0 or higher)

### Installation

1. Clone this repository:
```
git clone https://github.com/yourusername/outfit_matcher.git
```

2. Navigate to the project directory:
```
cd outfit_matcher
```

3. Install dependencies:
```
flutter pub get
```

4. Run code generation for freezed models and auto_route:
```
flutter pub run build_runner build --delete-conflicting-outputs
```

5. Run the app:
```
flutter run
```

## Project Structure

The project follows a clean architecture approach with the following structure:

- **core**: Contains app-wide utilities, constants, and services
  - **constants**: App-wide constant values
  - **di**: Dependency injection setup
  - **router**: Navigation setup using AutoRoute
  - **theme**: App theme configuration

- **features**: Contains feature modules
  - **auth**: Authentication feature
  - **onboarding**: Onboarding flow
  - **wardrobe**: Virtual closet and item management
  - **outfit_suggestions**: Outfit recommendation feature
  - **profile**: User profile and settings

## Technologies Used

- **State Management**: Flutter Riverpod
- **Navigation**: Auto Route
- **Dependency Injection**: GetIt
- **Data Classes**: Freezed
- **Storage**: Shared Preferences, Path Provider
- **UI Components**: Flutter Material Design
- **Image Handling**: Image Picker, Cached Network Image

## Next Steps

- Implement user authentication
- Add Firebase backend integration
- Add machine learning for better outfit recommendations
- Support for multiple closets (seasonal, occasion-based)
