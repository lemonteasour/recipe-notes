//
//  RecipeNotesApp.swift
//  RecipeNotes
//
//  Created by Jay Hui on 20/08/2025.
//

import SwiftUI
import SwiftData
import GoogleMobileAds

@main
struct RecipeNotesApp: App {
    @StateObject private var recipeListViewModel: RecipeListViewModel
    private let container: ModelContainer?
    private let containerError: Error?

    init() {
        MobileAds.shared.start()

        // Safely initialize ModelContainer with error handling
        var tempContainer: ModelContainer?
        var tempError: Error?

        do {
            tempContainer = try ModelContainer(for: Recipe.self, PantryItem.self, PantryCategory.self)
        } catch {
            tempError = error
            // Log the error for debugging
            print("CRITICAL: Failed to initialize ModelContainer: \(error)")
        }

        self.container = tempContainer
        self.containerError = tempError

        // Initialize ViewModel only if container succeeded
        if let container = tempContainer {
            let context = container.mainContext
            _recipeListViewModel = StateObject(wrappedValue: RecipeListViewModel(context: context))
        } else {
            // Create a dummy ViewModel with a temporary in-memory context
            // This prevents crashes but the app will show error state
            let fallbackContainer = try! ModelContainer(
                for: Recipe.self, PantryItem.self, PantryCategory.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            _recipeListViewModel = StateObject(wrappedValue: RecipeListViewModel(context: fallbackContainer.mainContext))
        }
    }

    var body: some Scene {
        WindowGroup {
            if let error = containerError {
                // Show error view if container initialization failed
                DatabaseErrorView(error: error)
            } else if let container = container {
                ContentView()
                    .tint(.accent)
                    .environmentObject(recipeListViewModel)
                    .modelContainer(container)
            }
        }
    }
}

// Error view shown when database initialization fails
struct DatabaseErrorView: View {
    let error: Error

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)

            Text("Database Error")
                .font(.title)
                .bold()

            Text("Failed to initialize the app's database. This may be due to:")
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                Text("• Insufficient storage space")
                Text("• Database corruption")
                Text("• iOS update migration issues")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)

            Text("Try restarting your device. If the problem persists, you may need to reinstall the app.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .padding()

            Text("Error: \(error.localizedDescription)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
        }
        .padding()
    }
}
