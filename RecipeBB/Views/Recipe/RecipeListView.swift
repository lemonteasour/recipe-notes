//
//  RecipeListView.swift
//  RecipeBB
//
//  Created by Jay Hui on 21/08/2025.
//

import SwiftUI
import SwiftData
import UIKit

struct RecipeListView: View {
    @Environment(\.modelContext) private var context
    @Environment(RecipeListViewModel.self) private var viewModel

    @Query(sort: \Recipe.createdAt, order: .reverse)
    private var allRecipes: [Recipe]

    @State private var showImportError = false
    @State private var errorMessage: String?

    var body: some View {
        @Bindable var viewModel = viewModel
        let filtered = viewModel.filteredRecipes(from: allRecipes)
        NavigationStack {
            List {
                ForEach(filtered) { recipe in
                    NavigationLink(value: recipe) {
                        HStack(spacing: 12) {
                            if let data = recipe.photo, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 48, height: 48)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            Text(recipe.name)
                        }
                    }
                }
                .onDelete { offsets in
                    do {
                        try viewModel.deleteRecipe(at: offsets, from: filtered)
                    } catch {
                        errorMessage = "Failed to delete recipe: \(error.localizedDescription)"
                    }
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
                IngredientFilterView(ingredients: viewModel.allIngredients(from: allRecipes))
                    .environment(viewModel)
            }
            .searchable(text: $viewModel.searchText, prompt: "Search recipes")
            .alert("Import Error", isPresented: $showImportError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Could not import recipe. Please make sure you have copied valid recipe text.")
            }
            .errorAlert($errorMessage)
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
        do {
            try context.save()
        } catch {
            errorMessage = "Failed to save recipe: \(error.localizedDescription)"
        }
    }
}

#Preview {
    let container = PreviewData.containerWithSamples()
    let viewModel = RecipeListViewModel(context: container.mainContext)

    return RecipeListView()
        .environment(viewModel)
        .modelContainer(container)
}
