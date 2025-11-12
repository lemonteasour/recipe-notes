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
    private let container: ModelContainer

    init() {
        MobileAds.shared.start()
        container = try! ModelContainer(for: Recipe.self, PantryItem.self, PantryCategory.self)
        let context = container.mainContext
        _recipeListViewModel = StateObject(wrappedValue: RecipeListViewModel(context: context))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(.accent)
                .environmentObject(recipeListViewModel)
                .modelContainer(container)
        }
    }
}
