//
//  RecipeListView.swift
//  RecipeNotes
//
//  Created by Jay Hui on 21/08/2025.
//

import SwiftUI
import SwiftData
import UIKit

struct RecipeListView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var viewModel: RecipeListViewModel

    @Query(sort: \Recipe.createdAt, order: .reverse)
    private var allRecipes: [Recipe]

    @State private var showImportError = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.filteredRecipes(from: allRecipes)) { recipe in
                    NavigationLink(value: recipe) {
                        Text(recipe.name)
                    }
                }
                .onDelete { offsets in
                    viewModel.deleteRecipe(at: offsets, from: allRecipes)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe)
            }
            .navigationTitle("Recipes")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showingAddForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        viewModel.showingFilterSheet = true
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        importRecipeFromClipboard()
                    } label: {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddForm) {
                RecipeFormView(context: context)
            }
            .sheet(isPresented: $viewModel.showingFilterSheet) {
                IngredientFilterView()
                    .environmentObject(viewModel)
            }
            .searchable(text: $viewModel.searchText, prompt: "Search recipes")
            .alert("Error", isPresented: $showImportError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Could not import recipe. Please make sure you have copied valid recipe text.")
            }
        }
    }

    private func importRecipeFromClipboard() {
        guard let clipboardText = UIPasteboard.general.string else {
            showImportError = true
            return
        }

        guard let recipe = RecipeClipboardService.importRecipeFromText(clipboardText) else {
            showImportError = true
            return
        }

        context.insert(recipe)
        try? context.save()
    }
}

#Preview {
    let container = PreviewData.containerWithSamples()
    let viewModel = RecipeListViewModel(context: container.mainContext)

    return RecipeListView()
        .environmentObject(viewModel)
        .modelContainer(container)
}
