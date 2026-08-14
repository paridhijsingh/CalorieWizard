# CalorieWizard

Snap, Track, and Transform — an iOS SwiftUI app that turns meal photos into calorie and macro insights, tracks your daily intake, and crafts healthy recipes with Gemini AI.

![Platform](https://img.shields.io/badge/iOS-17%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5-orange)
![UI](https://img.shields.io/badge/UI-SwiftUI-purple)
![AI](https://img.shields.io/badge/AI-Gemini-green)

## Features

### Landing & Onboarding
- Animated CalorieWizard logo with scale/opacity pulse
- Custom purple CW brand mark on landing + home-screen App Icon
- Soft plum brand theme (`BrandTheme`) shared by landing + hub menu so UI matches the logo
- Landing uses the logo as a full-bleed background (not a floating card)
- Aesthetic spring transitions: landing → hub, menu → feature screens (slide + soft scale)
- Swipe between feature screens like flashcards, with previous/next arrows and page dots
- Tagline: **Snap, Track, and Transform**
- **Get Started** → email/password auth (Supabase), then profile or hub
- **Aesthetic Explore menu hub** after auth (expand/collapse destinations)
- **Returning users**: signed-in session restores profile from Supabase; Get Started goes to the hub menu
- **New users**: profile setup for first name, last name, email, and optional phone
- **Skip for now** on profile setup to jump to the hub menu
- **Family multi-user**: each person signs in on their own device; RLS keeps data private per account

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
- Water drink reminders with sliders for interval (10 min–3 hrs), active time range, and sound (Default / Silent / Alert)
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
| Local persistence | SwiftData (meals, water, favorites) + `@AppStorage` (profile cache) |
| Cloud auth & sync | Supabase Auth + Postgres (profiles, meals, water, favorites) with RLS |
| Photos | PhotosUI + `UIImagePickerController` camera |
| Charts | Swift Charts macro ring |
| AI | Google Gemini (`generateContent`) — required for Analyze & Recipes when building locally |
| Nutrition API helper | USDA FoodData Central client (`USDAService`) — optional / future |

## Project Structure

```
CalorieWizard/
├── CalorieWizardApp.swift      # App entry + landing/profile → hub flow
├── BrandTheme.swift            # Logo plum palette for landing + hub
├── BrandTransitions.swift      # Shared spring page/cover transitions
├── AuthView.swift              # Email/password sign up & sign in
├── AuthManager.swift           # Supabase Auth session state
├── SupabaseManager.swift       # Client + SUPABASE_URL / ANON_KEY config
├── SupabaseSyncService.swift   # Upsert profile / meals / water / favorites
├── LandingView.swift           # Animated welcome screen
├── AppHubMenuView.swift        # Aesthetic expand/collapse destination menu
├── ProfileSetupView.swift      # Save or Skip for now
├── MainTabView.swift           # Legacy tab shell (optional)
├── DashboardView.swift         # Period goals + charts
├── FoodScannerView.swift       # Gemini meal photo analysis
├── RecipeGeneratorView.swift   # Recipe Wizard + Favorites
├── WaterTrackerView.swift      # Hydration logging + reminder controls
├── HistoryView.swift           # Meal log
├── ProfileView.swift           # Profile, goals, notification toggles, sign out
├── ContentView.swift           # Shared models, parser, macro ring helpers
├── FavoriteRecipe.swift        # Saved recipes + recipe JSON payload
├── HydrationModels.swift       # WaterEntry + ReminderEvent
├── NotificationManager.swift   # Local water & calorie-limit alerts + sounds
├── ImagePicker.swift           # Camera bridge
├── UserProfileStore.swift      # AppStorage keys
├── APIKeys.swift               # Reads GEMINI/USDA from env + Info.plist
└── USDAService.swift           # Optional USDA helper (not required to run)
```

Supabase SQL (committed):

```
supabase/
└── schema.sql                  # Tables + RLS policies
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
- A free [Supabase](https://supabase.com) project (for multi-device / family sync)

### Do you need API keys?

| Key | Who needs it? | Why |
|-----|----------------|-----|
| **Gemini** | Anyone who **clones or builds** this repo and wants AI features | Powers **Analyze** (meal photo recognition) and **Recipe Wizard**. Without it, the rest of the app (dashboard, water, history, profile) still works. |
| **Supabase URL + anon key** | Anyone who wants **sign-in and cloud sync** | Email auth and syncing profile / meals / water / favorites across devices. Without them, the app can still run locally but auth will show a configuration error. |
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
   SUPABASE_URL = https:/$()/YOUR_PROJECT.supabase.co
   SUPABASE_ANON_KEY = your_anon_key_here
   ```
   - Gemini: [Google AI Studio](https://aistudio.google.com/)
   - Supabase: Project Settings → API → Project URL + `anon` / publishable key
   - **xcconfig tip:** write `https:/$()/…` not `https://…` — in `.xcconfig`, `//` starts a comment and would truncate the URL to `https:`
4. In the Supabase SQL Editor, run `supabase/schema.sql` (creates tables + row-level security).
5. In Supabase Auth settings, enable **Email** provider (confirm email optional for local testing).
6. Open `CalorieWizard.xcodeproj`, select your team under **Signing & Capabilities**, then build and run.

### How keys are loaded

1. **Build-time:** `Config/Debug.xcconfig` / `Release.xcconfig` include `Secrets.xcconfig`, and values are injected into `Info.plist`.
2. **Runtime:** `APIKeys.swift` / `SupabaseConfig` read process environment variables first, then Info.plist.

Optional Xcode scheme override: **Product → Scheme → Edit Scheme → Run → Arguments → Environment Variables**.

> **Security:** Never commit `Config/Secrets.xcconfig`. Only `Secrets.xcconfig.example` belongs in git. Use the **anon** key in the app (safe with RLS), never the **service_role** key.

## App Flow

```
Landing (every launch)
   └─ Get Started
        ├─ Signed in → Hub (or profile setup if incomplete)
        └─ Auth (Sign Up / Sign In via Supabase)
             └─ Profile Setup (new) or Hub (returning)
                  └─ Choose Dashboard / Analyze / Recipes / Water / History / Profile
```

## Roadmap / Changelog

Keep this section updated as features land.

### Current
- [x] Animated landing + Get Started
- [x] Supabase email auth for multi-user / family devices
- [x] Cloud sync for profile, meals, water, and favorite recipes (RLS per user)
- [x] Profile row created on sign-in/sign-up so Table Editor is populated immediately
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
- [x] Water tracker with daily logging
- [x] Water reminders (interval + time-range sliders, sound options)
- [x] Calorie limit alerts with reminder log
- [x] Aesthetic expand/collapse hub menu after Get Started

### Next ideas
- [ ] Pull remote meals/water/favorites into SwiftData on launch
- [ ] Cuisine / flavor chip filters on Recipe Wizard
- [ ] Barcode / USDA packaged food lookup
- [ ] Share meal or recipe summary cards

## Privacy

- Meal photos stay on-device (file names sync; image bytes are not uploaded yet)
- Profile and nutrition logs sync to your Supabase project when signed in (RLS: only your `auth.uid()` rows)
- Local cache uses SwiftData + `UserDefaults` / `@AppStorage`
- AI requests are sent to Google Gemini when you analyze a meal or generate a recipe

## License

Personal / educational project by Paridhi Singh. Update this section if you choose an open-source license.
