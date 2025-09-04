//
//  RecipeListViewModel.swift
//  RecipeNotes
//
//  Created by Jay Hui on 05/09/2025.
//


import SwiftUI
import SwiftData

@MainActor
final class RecipeListViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var selectedIngredients: Set<String> = []
    @Published var ingredientSearch = ""
    @Published var showingAddForm = false
    @Published var showingFilterSheet = false

    /// Return recipes filtered by search text and selected ingredients
    func filteredRecipes(from allRecipes: [Recipe]) -> [Recipe] {
        allRecipes.filter { recipe in
            let matchesNameOrDesc =
                searchText.isEmpty ||
                recipe.name.localizedStandardContains(searchText) ||
                recipe.desc.localizedStandardContains(searchText)

            let matchesIngredients =
                selectedIngredients.isEmpty ||
                recipe.ingredients.contains { selectedIngredients.contains($0.name) }

            return matchesNameOrDesc && matchesIngredients
        }
    }

    /// Return all unique ingredients (used for filtering)
    func allIngredients(from allRecipes: [Recipe]) -> [String] {
        let names = allRecipes.flatMap { recipe in
            recipe.ingredients.map { $0.name }
        }
        return Array(Set(names)).sorted()
    }

    /// Return ingredients filtered by ingredientSearch
    func filteredIngredients(from allRecipes: [Recipe]) -> [String] {
        let all = allIngredients(from: allRecipes)
        if ingredientSearch.isEmpty { return all }
        return all.filter { $0.localizedStandardContains(ingredientSearch) }
    }

    /// Delete recipes
    func deleteRecipe(at offsets: IndexSet, from allRecipes: [Recipe], context: ModelContext) {
        for index in offsets {
            context.delete(allRecipes[index])
        }
    }

    /// Toggle selection for an ingredient
    func toggleIngredient(_ ingredient: String) {
        if selectedIngredients.contains(ingredient) {
            selectedIngredients.remove(ingredient)
        } else {
            selectedIngredients.insert(ingredient)
        }
    }
}
