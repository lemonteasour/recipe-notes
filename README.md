# 🍳 Recipe App

A simple and modern iOS app for organizing cooking recipes.

Built with **SwiftUI** and **SwiftData**, the app lets you create, search, and filter recipes with ease.

## ✨ Features

- **Add & Edit Recipes**
  - Name, description, ingredients, and step-by-step instructions.
  - Supports drag-and-drop reordering for steps and ingredients.
- **Ingredient Management**
  - Multi-select ingredient filter to quickly find recipes using what you have.
  - Ingredient headings in recipes to better organize ingredients.
  - Search within ingredients for faster filtering.
- **Search & Filter**
  - Global search bar for recipe names and descriptions.
  - Ingredient filter dropdown (multi-select).
- **Data Persistence**
  - Recipes are stored locally using **SwiftData**, with instant updates.

## 🚀 Getting Started

### Prerequisites

- Xcode 16.4+
- iOS 18.5+ (minimum deployment target)

### Installation

Clone the repository and open in Xcode:

```bash
git clone git@github.com:lemonteasour/recipe-notes.git
cd recipe-notes
pod install
open RecipeNotes.xcworkspace
```

Run on Simulator or a physical device.

## 🏗️ Project Structure

- `Models/` – SwiftData Models
- `Views/` – SwiftUI Views
- `ViewModels/` – SwiftUI ViewModels
- `Resources/` – L10n (English and Japanese labels)

## 🔮 Roadmap

- Export/import recipes to/from clipboard
- Tags & categories (e.g. "Good with drinks", "Hong Kong cuisine")
- Recipe images & photo picker
- Improved filter UI with chips for active filters

## 📄 License

This project is licensed under the MIT License. See the LICENSE file for details.
