//
//  RecipeListView.swift
//  RecipeNotes
//
//  Created by Jay Hui on 21/08/2025.
//

import SwiftUI
import SwiftData

struct RecipeListView: View {
    @Environment(\.modelContext) private var context
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
                    viewModel.deleteRecipe(at: offsets, from: allRecipes, context: context)
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
                    .environment(\.modelContext, context)
            }
            .searchable(text: $viewModel.searchText, prompt: "Search recipes")
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Recipe.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = container.mainContext
    
    let recipe = Recipe(
        name: "Oyakodon",
        desc: "Desc",
        ingredients: [
            Ingredient(name: "Egg", quantity: "4"),
            Ingredient(name: "Chicken", quantity: "300g")
        ],
        steps: [Step(value: "Step")])
    context.insert(recipe)
    
    return RecipeListView()
        .environmentObject(RecipeListViewModel())
        .modelContainer(container)
}
