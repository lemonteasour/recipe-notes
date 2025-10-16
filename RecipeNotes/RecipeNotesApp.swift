//
//  RecipeNotesApp.swift
//  RecipeNotes
//
//  Created by Jay Hui on 20/08/2025.
//

import SwiftUI
import SwiftData

@main
struct RecipeNotesApp: App {
    @StateObject private var recipeListViewModel: RecipeListViewModel
    private let container: ModelContainer

    init() {
        container = try! ModelContainer(for: Recipe.self, PantryItem.self)
        let context = container.mainContext
        _recipeListViewModel = StateObject(wrappedValue: RecipeListViewModel(context: context))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(.accentColor)
                .environmentObject(recipeListViewModel)
                .modelContainer(container)
        }
    }
}
