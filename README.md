# 🍳 RecipeBB

A simple and modern iOS app for organizing cooking recipes.

**[Download on the App Store!](https://apps.apple.com/app/id6752032405)**

## ✨ Features

- **Recipes**
  - Name, description, photo, ingredients, and step-by-step instructions.
  - Ingredient headings to group a long list; drag-and-drop reordering for ingredients and steps.
  - Tags and favorites, with favorites pinned to the top of the list.
- **Finding a recipe**
  - Search across names and descriptions.
  - Multi-select filters for tags and ingredients, with a search box inside the ingredient list.
  - Sort by date or name; sections by month or initial, with an index scrubber down the side.
- **Cooking mode**
  - A stripped-back, read-at-a-distance step view that keeps the screen awake while you cook.
- **Pantry**
  - Track what's on hand, organized into categories you can reorder.
- **Planner**
  - Month calendar with breakfast / lunch / dinner entries per day.
  - An entry can link to a saved recipe — renames follow — or stand on its own with a note.
- **Import & export**
  - Share a recipe as plain text from the share sheet, and paste one back in from the clipboard.
- **Preferences**
  - Theme: same as device, light, or dark.
  - Localized in English, Japanese, and Traditional Chinese.

## 🛠️ Technologies Used

- **SwiftUI:** For building a modern, declarative, and responsive user interface across Apple platforms.
- **SwiftData:** Apple's new framework for robust and efficient local data persistence, integrated seamlessly with SwiftUI. The schema is shaped for CloudKit — no unique constraints, defaults on every attribute, optional relationships with explicit inverses — ahead of sync being turned on.
- **Google Mobile Ads:** A single rewarded ad, offered from the More tab.

## 🚀 Getting Started

### Prerequisites

- Xcode 26.6+
- iOS 26.0+ (minimum deployment target)

Dependencies (Google Mobile Ads) are managed with Swift Package Manager and resolve
automatically on first open — there is no separate install step.

### Installation

Clone the repository and open in Xcode:

```bash
git clone https://github.com/lemonteasour/recipe-notes.git
cd recipe-notes
open RecipeBB.xcodeproj
```

### Ad configuration

`RecipeBB/Resources/Config.xcconfig` holds the AdMob identifiers and is **gitignored**, so a
fresh clone won't have it. Create it before building:

```
// RecipeBB/Resources/Config.xcconfig
ADMOB_APP_ID = ca-app-pub-3940256099942544~1458002511
ADMOB_REWARDED_AD_UNIT_ID = ca-app-pub-3940256099942544/1712485313
```

Those are Google's public test identifiers — check the
[test ads documentation](https://developers.google.com/admob/ios/test-ads) for the current
values, and never point a development build at the production unit. Both are substituted into
`Info.plist` at build time.

> **Note:** a missing or misreferenced `Config.xcconfig` does **not** fail the build. It
> succeeds with both values empty. To confirm they resolved, inspect the built app rather than
> trusting a green build:
>
> ```bash
> plutil -extract GADApplicationIdentifier raw \
>   ~/Library/Developer/Xcode/DerivedData/RecipeBB-*/Build/Products/Debug-iphonesimulator/RecipeBB.app/Info.plist
> ```

Run on Simulator or a physical device.

## 🏗️ Project Structure

Source lives under `RecipeBB/`, split into six folders. Only the app entry point,
`RecipeBBApp.swift`, sits outside them.

- `Models/` – SwiftData models and other data structures. No side effects.
- `ViewModels/` – `@Observable` `@MainActor` ViewModels backing the views.
- `Views/` – SwiftUI views.
- `Services/` – Types that reach outside our own code (ads, seeding, persistence queries).
  The test for membership: would you want to swap or mock it in a test?
- `Extensions/` – `Type+Feature.swift` extensions on types we don't own.
- `Resources/` – L10n (English, Japanese, Traditional Chinese) and build config.

Tests live outside that tree, in `RecipeBBTests/` (unit) and `RecipeBBUITests/` (UI).

### Naming

- Views end in `View`; files declaring a `ViewModifier` or a `View` extension end in `Modifier`.
- ViewModels end in `ViewModel`.
- Services end in `Service`.

### Localization

English is the source language. New user-facing strings are extracted into
`Resources/Localizable.xcstrings` on build; the `ja` and `zh-Hant` values are filled in by hand.

## 📄 License

This project is licensed under the MIT License. See the LICENSE file for details.
