//
//  RecipeListViewModel.swift
//  RecipeBB
//
//  Created by Jay Hui on 05/09/2025.
//


import SwiftUI
import SwiftData

@MainActor
@Observable
final class RecipeListViewModel {
    private let context: ModelContext

    var searchText = ""
    var selectedIngredients: Set<String> = []
    var ingredientSearch = ""
    var showingAddForm = false
    var showingFilterSheet = false

    init(context: ModelContext) {
        self.context = context
    }

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
        IngredientCatalog.normalized(allRecipes.flatMap { $0.ingredients.map(\.name) })
    }

    /// Return ingredient names filtered by `ingredientSearch`
    func filteredIngredients(from allIngredients: [String]) -> [String] {
        if ingredientSearch.isEmpty { return allIngredients }
        return allIngredients.filter { $0.localizedStandardContains(ingredientSearch) }
    }

    /// Delete recipes
    func deleteRecipe(at offsets: IndexSet, from allRecipes: [Recipe]) throws {
        for index in offsets {
            context.delete(allRecipes[index])
        }
        try context.save()
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
