# 🍳 Recipe App

A simple and modern iOS app for organizing cooking recipes.

**[Download on the App Store!](https://apps.apple.com/app/id6752032405)**

## ✨ Features

- **Add & Edit Recipes**
  - Name, description, ingredients, and step-by-step instructions.
  - Supports drag-and-drop reordering for steps and ingredients.
- **Recipe Search & Filter**
  - Global search bar for recipe names and descriptions.
  - Ingredient filter dropdown (multi-select).
- **Ingredient Management**
  - Multi-select ingredient filter to quickly find recipes using what you have.
  - Ingredient headings in recipes to better organize ingredients.
  - Search within ingredients for faster filtering.
- **Data Persistence**
  - Recipes are stored locally using **SwiftData**, with instant updates.
 
## 🛠️ Technologies Used

- **SwiftUI:** For building a modern, declarative, and responsive user interface across Apple platforms.
- **SwiftData:** Apple's new framework for robust and efficient local data persistence, integrated seamlessly with SwiftUI.

## 🚀 Getting Started

### Prerequisites

- Xcode 16.4+
- iOS 18.5+ (minimum deployment target)
- [CocoaPods](https://cocoapods.org/) - Install with `sudo gem install cocoapods`

### Installation

Clone the repository and open in Xcode:

```bash
git clone https://github.com/lemonteasour/recipe-notes.git
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

- New UI design
- Rating for each recipe
- Export/import recipes to/from clipboard
- Tags & categories (e.g. "Good with drinks", "Hong Kong cuisine")
- Recipe images & photo picker
- Improved filter UI with chips for active filters

## 📄 License

This project is licensed under the MIT License. See the LICENSE file for details.
