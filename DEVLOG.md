# CalorieWizard Dev Log

Daily notes for features shipped, bugs hit, and learnings — raw material for blogs and LinkedIn posts.

## How to use

1. Copy the **Daily entry template** below into a new date section (newest first).
2. Spend 5–10 minutes at end of day filling **Shipped / Bugs / Learnings / Post hooks**.
3. When writing a post, pick 1 hook + 1 bug story + 1 takeaway (don’t dump the whole day).

### LinkedIn / blog tip

- LinkedIn: 1 problem → 1 decision → 1 result → 1 lesson (short)
- Blog: expand the bug story with before/after and code/context screenshots

---

## Daily entry template

```md
## YYYY-MM-DD — <short title>

### Shipped
- 

### Bugs / blockers
- **Issue:**
- **Fix / workaround:**
- **Time lost (approx):**

### Learnings
- 

### Post hooks (draft angles)
1. 
2. 

### Mood / energy (optional)
- 
```

---

## 2026-08-14 — Supabase multi-user, brand, and motion

### Shipped
- Switched multi-user backend plan from Firebase → **Supabase** (Auth + Postgres + RLS)
- Ran `supabase/schema.sql` (profiles, meals, water_logs, favorite_recipes + policies)
- Wired iOS app: sign up / sign in, profile stub sync, meal/water/favorite upserts
- Fixed secrets loading for `SUPABASE_URL` in xcconfig
- Built purple **CW** brand mark into App Icon, landing, and hub
- Unified UI to logo plum palette (`BrandTheme`)
- Landing logo as full-bleed brand page (readable, centered, no floating square)
- Aesthetic transitions: landing → hub, hub → features
- Flashcard-style **swipe + prev/next arrows** between feature screens

### Bugs / blockers
- **Issue:** App crashed: `supabaseURL must have a valid host` (URL became just `https:`)
  - **Fix:** In `.xcconfig`, `//` starts a comment — write `https:/$()/project.supabase.co`
  - **Time lost (approx):** ~20–30 min
- **Issue:** User appeared in Auth → Users, but Table Editor `profiles` / water stayed empty
  - **Cause:** Signup can create a user without a usable session JWT; sync used `try?` and silently no-op’d
  - **Fix:** Require session (sign in after signup if needed), create profile stub on auth, stop swallowing sync errors
  - **Time lost (approx):** ~45–60 min
- **Issue:** “Email not confirmed” + broken confirm link (“site can’t be reached”)
  - **Fix:** Turn **Confirm email** OFF for personal/testing; confirm or recreate the existing user
  - **Time lost (approx):** ~20 min
- **Issue:** Landing logo too big / cropped / right-aligned / visible square tile
  - **Fix:** `scaledToFit` + centered layout; punch plum background to transparency so artwork sits on page color
  - **Time lost (approx):** ~30–40 min
- **Issue:** Supabase Swift warning about initial session refresh behavior
  - **Fix:** Opt in with `emitLocalSessionAsInitialSession: true` and ignore expired stored sessions until refresh

### Learnings
- Backend choice matters less than **auth session reality**: “user exists” ≠ “API calls are authorized”
- Config formats have traps — xcconfig `//` is a classic footgun for HTTPS URLs
- Silent `try?` is fine for demos, terrible for debugging sync
- Brand work is product work: once the logo color was locked, the UI finally felt intentional
- For family testing without App Store: free path is USB + Xcode (TestFlight needs paid Apple Developer)

### Post hooks (draft angles)
1. **“My URL was literally `https:`”** — the xcconfig comment bug that crashed Supabase on launch
2. **“Auth Users had me, Table Editor didn’t”** — why empty tables don’t mean your schema is wrong
3. **“I turned off email confirmation on purpose”** — shipping a family app vs production auth defaults
4. **From SF Symbol wand → custom CW mark** — matching an iOS UI to a logo palette
5. **Flashcard navigation for an app hub** — swipe between features instead of only a menu list

### Mood / energy (optional)
- Productive marathon day: infra → sync debugging → brand polish → motion

### Draft LinkedIn post (optional starter)

> Built multi-user sync for my iOS calorie app today with Supabase.
>
> Funniest bug: the app crashed because my config file treated `https://` as a comment, so the URL became `https:`.
>
> Real lesson: seeing a user in Auth ≠ data will sync. You need a live session before Postgres RLS will let you write.
>
> Also shipped a custom logo, matched the whole UI to it, and added swipeable “flashcard” navigation between features.
>
> Building in public — next up: pulling cloud history onto a fresh device.

---

## Index (quick scan)

| Date | Focus |
|------|--------|
| 2026-08-14 | Supabase auth/sync, brand system, landing, transitions, feature pager |
