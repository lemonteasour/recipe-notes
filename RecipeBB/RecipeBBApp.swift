//
//  RecipeBBApp.swift
//  RecipeBB
//
//  Created by Jay Hui on 20/08/2025.
//

import SwiftUI
import SwiftData
import os

@main
struct RecipeBBApp: App {
    @AppStorage(AppearanceMode.storageKey) private var appearanceMode: AppearanceMode = .system
    @State private var recipeListViewModel: RecipeListViewModel?
    private let container: ModelContainer?
    private let containerError: Error?

    init() {
        // Safely initialize ModelContainer with error handling
        var tempContainer: ModelContainer?
        var tempError: Error?

        do {
            tempContainer = try ModelContainer(
                for: Recipe.self, RecipeTag.self, PantryItem.self, PantryCategory.self, MealPlanEntry.self
            )
        } catch {
            tempError = error
            // Log the whole error, not localizedDescription — Core Data puts
            // the useful part (failing entity, migration detail) in userInfo,
            // and .public keeps it from being redacted in device logs.
            Logger.persistence.critical(
                "Failed to initialize ModelContainer: \(String(describing: error), privacy: .public)"
            )
        }

        self.container = tempContainer
        self.containerError = tempError

        // Initialize ViewModel only if container succeeded. The in-memory
        // fallback declares the *same* model types, so a schema-level failure
        // throws there too — building it with `try!` turned any such failure
        // into a launch-time trap for every user. If it fails, go without a
        // ViewModel and show the error screen instead.
        if let tempContainer {
            _recipeListViewModel = State(
                initialValue: RecipeListViewModel(context: tempContainer.mainContext)
            )
        } else {
            let fallbackContainer = try? ModelContainer(
                for: Recipe.self, RecipeTag.self, PantryItem.self, PantryCategory.self, MealPlanEntry.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            _recipeListViewModel = State(
                initialValue: fallbackContainer.map { RecipeListViewModel(context: $0.mainContext) }
            )
        }
    }

    var body: some Scene {
        WindowGroup {
            // Grouped so the appearance override covers the error screen too
            Group {
                if containerError == nil, let container, let recipeListViewModel {
                    ContentView()
                        .tint(.accent)
                        .environment(recipeListViewModel)
                        .modelContainer(container)
                        .task {
                            // Gather ad consent (showing the form if required),
                            // then start the Mobile Ads SDK
                            await AdMobService.shared.requestConsentAndStart()
                        }
                } else {
                    // Anything that leaves us without a usable container or
                    // ViewModel lands here rather than on a blank window
                    DatabaseErrorView(error: containerError)
                }
            }
            .preferredColorScheme(appearanceMode.colorScheme)
        }
    }
}
