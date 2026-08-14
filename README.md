# CalorieWizard

Snap, Track, and Transform — an iOS SwiftUI app that turns meal photos into calorie and macro insights, tracks your daily intake, and crafts healthy recipes with Gemini AI.

![Platform](https://img.shields.io/badge/iOS-17%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5-orange)
![UI](https://img.shields.io/badge/UI-SwiftUI-purple)
![AI](https://img.shields.io/badge/AI-Gemini-green)

## Features

### Landing & Onboarding
- Animated CalorieWizard logo with scale/opacity pulse
- Tagline: **Snap, Track, and Transform**
- **Get Started** continues into the app
- **Returning users**: saved profile stays in place; Get Started goes to the dashboard
- **New users**: profile setup for first name, last name, email, and optional phone
- **Skip for now** on profile setup to jump straight to the dashboard

### Today Dashboard
- Calories consumed today vs daily goal (default **2,000 kcal**, editable in Profile)
- Protein / carbs / fat breakdown for the day
- Live list of meals logged today (SwiftData)

### Analyze (Meal Scanner)
- Take a photo or pick from the library
- Gemini vision analysis for food name, calories, and macros
- Macro progress ring (Protein, Carbs, Fats)
- Transparent AI disclaimer: estimates are guidance and can be edited
- Tap any macro to manually adjust values
- Saves analyzed meals (and photos) into History and today’s tracker

### Recipe Wizard (Chef & Recipes)
- Enter pantry ingredients
- Meal type: Main Course / Snack / Dessert
- Dietary focus: Balanced, High-Protein, Low-Carb, Vegetarian, Keto
- Health-aware options: gluten-free, diabetic-friendly, heart-healthy, low-sodium
- Target calorie slider
- Gemini generates a gourmet, preservative-free style recipe with timing, steps, and estimated macros

### History
- Thumbnail, meal name, timestamp, calories, and macros for every logged entry
- Detail view and swipe-to-delete
- Photos stored on-device

### Profile
- View and edit saved personal details
- Adjust daily calorie goal
- Light and dark mode via semantic system colors

## Tech Stack

| Area | Choice |
|------|--------|
| UI | SwiftUI |
| Persistence | SwiftData (`MealEntry`) + `@AppStorage` (profile) |
| Photos | PhotosUI + `UIImagePickerController` camera |
| Charts | Swift Charts macro ring |
| AI | Google Gemini (`generateContent`) |
| Nutrition API helper | USDA FoodData Central client (`USDAService`) |

## Project Structure

```
CalorieWizard/
├── CalorieWizardApp.swift      # App entry + landing/profile flow
├── LandingView.swift           # Animated welcome screen
├── ProfileSetupView.swift      # Save or Skip for now
├── MainTabView.swift           # Today / Analyze / Recipes / History / Profile
├── DashboardView.swift         # Daily calorie & macro summary
├── FoodScannerView.swift       # Photo analysis
├── RecipeGeneratorView.swift   # Recipe Wizard
├── HistoryView.swift           # Meal log
├── ProfileView.swift           # Profile & goals
├── ContentView.swift           # Shared models, parser, macro ring helpers
├── ImagePicker.swift           # Camera bridge
├── UserProfileStore.swift      # AppStorage keys
└── USDAService.swift           # USDA search helper
```

## Requirements

- Xcode 16+ (tested with newer Xcode / iOS 26 SDK)
- iOS Simulator or device with camera permission for live capture
- A [Google AI Studio](https://aistudio.google.com/) Gemini API key
- Optional: [USDA FoodData Central](https://fdc.nal.usda.gov/api-guide.html) API key

## Setup

1. Clone the repo:
   ```bash
   git clone https://github.com/paridhijsingh/CalorieWizard.git
   cd CalorieWizard
   open CalorieWizard.xcodeproj
   ```
2. Add your Gemini API key where `YOUR_GEMINI_API_KEY` appears (see `FoodScannerView.swift`, `RecipeGeneratorView.swift`, and `ContentView.swift`).
3. Optionally set your USDA key in `USDAService.swift` (`YOUR_USDA_API_KEY`).
4. Select your team under **Signing & Capabilities**.
5. Build and run on a simulator or device.

> **Security:** Never commit real API keys. Prefer local config or Xcode build settings for secrets.

## App Flow

```
Landing (every launch)
   └─ Get Started
        ├─ Existing profile → Dashboard tabs
        └─ New user → Profile Setup
             ├─ Save & Continue → Dashboard
             └─ Skip for now → Dashboard
```

## Roadmap / Changelog

Keep this section updated as features land.

### Current
- [x] Animated landing + Get Started
- [x] Profile save / skip for returning & new users
- [x] Daily calorie dashboard (SwiftData)
- [x] Gemini meal photo analysis + editable macros
- [x] Meal history with photos
- [x] Recipe Wizard with diet & health filters
- [x] Light / dark mode support

### Next ideas
- [ ] Save favorite recipes
- [ ] Log recipe macros to daily tracker with one tap
- [ ] Cuisine / flavor chip filters on Recipe Wizard
- [ ] Weekly trends and charts
- [ ] Move API keys to secure local configuration

## Privacy

- Meal photos and history are stored on-device
- Profile fields are stored in `UserDefaults` / `@AppStorage`
- AI requests are sent to Google Gemini when you analyze a meal or generate a recipe

## License

Personal / educational project by Paridhi Singh. Update this section if you choose an open-source license.
