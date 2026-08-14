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
- Calories consumed vs goal for **Today / Week / Month / Year**
- Protein / carbs / fat progress for the selected period
- Calorie bar chart and nutrition line chart
- Live list of meals logged today

### Analyze (Meal Scanner)
- Take a photo or pick from the library
- Gemini vision analysis for food name, calories, and macros
- Macro progress ring with editable values
- Saves analyzed meals into History and today’s tracker

### Recipe Wizard (Chef & Recipes)
- Enter pantry ingredients with diet and health filters
- Target calorie slider
- Gemini generates structured recipes with macros
- **Save to Favorites** and **Log to Today**
- **Favorites** segment to browse, open, log, or delete saved recipes

### Water
- Log water with quick add (100 ml / glass / bottle) or a custom slider
- Daily hydration goal with progress ring
- Water drink reminders (every 1–4 hours, 8 AM–10 PM)
- Reminder log for water schedule updates and calorie-limit alerts

### History
- Thumbnail, meal name, timestamp, calories, and macros for every logged entry
- Detail view and swipe-to-delete
- Photos stored on-device

### Profile
- View and edit saved personal details
- Daily calorie goal **slider** with suggestions (Gentle cut, Maintain, Active, Muscle gain)
- Auto week / month / year calorie totals based on daily goal
- Macro target sliders for protein, carbs, and fat
- Light and dark mode via semantic system colors

## Tech Stack

| Area | Choice |
|------|--------|
| UI | SwiftUI |
| Persistence | SwiftData (`MealEntry`) + `@AppStorage` (profile) |
| Photos | PhotosUI + `UIImagePickerController` camera |
| Charts | Swift Charts macro ring |
| AI | Google Gemini (`generateContent`) — required for Analyze & Recipes when building locally |
| Nutrition API helper | USDA FoodData Central client (`USDAService`) — optional / future |

## Project Structure

```
CalorieWizard/
├── CalorieWizardApp.swift      # App entry + landing/profile flow
├── LandingView.swift           # Animated welcome screen
├── ProfileSetupView.swift      # Save or Skip for now
├── MainTabView.swift           # Today / Analyze / Recipes / Water / History / Profile
├── DashboardView.swift         # Period goals + charts
├── FoodScannerView.swift       # Gemini meal photo analysis
├── RecipeGeneratorView.swift   # Recipe Wizard + Favorites
├── WaterTrackerView.swift      # Hydration logging + reminder log
├── HistoryView.swift           # Meal log
├── ProfileView.swift           # Profile, goals, notification toggles
├── ContentView.swift           # Shared models, parser, macro ring helpers
├── FavoriteRecipe.swift        # Saved recipes + recipe JSON payload
├── HydrationModels.swift       # WaterEntry + ReminderEvent
├── NotificationManager.swift   # Local water & calorie-limit alerts
├── ImagePicker.swift           # Camera bridge
├── UserProfileStore.swift      # AppStorage keys
├── APIKeys.swift               # Reads GEMINI/USDA from env + Info.plist
└── USDAService.swift           # Optional USDA helper (not required to run)
```

Config (project root):

```
Config/
├── Debug.xcconfig
├── Release.xcconfig
├── Secrets.xcconfig.example    # committed template
└── Secrets.xcconfig            # local only (gitignored)
```

## Requirements

- Xcode 16+ (tested with newer Xcode / iOS 26 SDK)
- iOS Simulator or device (camera permission for live meal photos)
- Notifications permission (optional, for water + calorie-limit reminders)

### Do you need API keys?

| Key | Who needs it? | Why |
|-----|----------------|-----|
| **Gemini** | Anyone who **clones or builds** this repo and wants AI features | Powers **Analyze** (meal photo recognition) and **Recipe Wizard**. Without it, the rest of the app (dashboard, water, history, profile) still works. |
| **USDA** | **Optional** — mainly for contributors | `USDAService` is included for future packaged-food lookup. It is **not required** for the current app experience. |

Everyday end users of a future App Store build would **not** manage keys themselves (that would be handled by the developer/backend). Keys in this repo are for **local development, cloning, and contributing**.

## Setup

1. Clone the repo:
   ```bash
   git clone https://github.com/paridhijsingh/CalorieWizard.git
   cd CalorieWizard
   ```
2. Create your local secrets file (gitignored):
   ```bash
   cp Config/Secrets.xcconfig.example Config/Secrets.xcconfig
   ```
3. Edit `Config/Secrets.xcconfig`:
   ```
   GEMINI_API_KEY = your_gemini_key_here
   USDA_API_KEY =                    # leave blank unless you need USDA
   ```
   Get a free Gemini key from [Google AI Studio](https://aistudio.google.com/).
4. Open `CalorieWizard.xcodeproj`, select your team under **Signing & Capabilities**, then build and run.

### How keys are loaded

1. **Build-time:** `Config/Debug.xcconfig` / `Release.xcconfig` include `Secrets.xcconfig`, and values are injected into `Info.plist`.
2. **Runtime:** `APIKeys.swift` reads process environment variables first, then Info.plist.

Optional Xcode scheme override: **Product → Scheme → Edit Scheme → Run → Arguments → Environment Variables**.

> **Security:** Never commit `Config/Secrets.xcconfig`. Only `Secrets.xcconfig.example` belongs in git.

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
- [x] API keys via xcconfig / environment variables (not hardcoded)
- [x] Save recipes to Favorites + log recipes to daily tracker
- [x] Favorites tab inside Recipes
- [x] Dashboard week / month / year goals with calorie & macro charts
- [x] Profile daily goal slider with smart suggestions
- [x] Water tracker tab with daily logging
- [x] Water drink reminders + calorie limit alerts with reminder log

### Next ideas
- [ ] Cuisine / flavor chip filters on Recipe Wizard
- [ ] Barcode / USDA packaged food lookup
- [ ] Share meal or recipe summary cards
## Privacy

- Meal photos and history are stored on-device
- Profile fields are stored in `UserDefaults` / `@AppStorage`
- AI requests are sent to Google Gemini when you analyze a meal or generate a recipe

## License

Personal / educational project by Paridhi Singh. Update this section if you choose an open-source license.
