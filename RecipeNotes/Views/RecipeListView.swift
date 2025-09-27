//
//  RecipeListView.swift
//  RecipeNotes
//
//  Created by Jay Hui on 21/08/2025.
//

import SwiftUI
import SwiftData

struct RecipeListView: View {
    @EnvironmentObject private var viewModel: RecipeListViewModel
    
    @Query(sort: \Recipe.createdAt, order: .reverse)
    private var allRecipes: [Recipe]
    
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.showingFilterSheet = true
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddForm) {
                RecipeFormView()
            }
            .sheet(isPresented: $viewModel.showingFilterSheet) {
                IngredientFilterView()
                    .environmentObject(viewModel)
            }
            .searchable(text: $viewModel.searchText, prompt: "Search recipes")
        }
    }
}

#Preview {
    let container = PreviewData.containerWithSamples()
    let viewModel = RecipeListViewModel(context: container.mainContext)

    return RecipeListView()
        .environmentObject(viewModel)
        .modelContainer(container)
}
