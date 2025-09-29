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
    @StateObject private var viewModel: RecipeListViewModel
    private let container: ModelContainer

    init() {
        container = try! ModelContainer(for: Recipe.self)
        let context = container.mainContext
        _viewModel = StateObject(wrappedValue: RecipeListViewModel(context: context))
    }

    var body: some Scene {
        WindowGroup {
            RecipeListView()
                .tint(.accentColor)
                .environmentObject(viewModel)
                .modelContainer(container)
        }
    }
}
