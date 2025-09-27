//
//  RecipeFormViewModel.swift
//  RecipeNotes
//
//  Created by Jay Hui on 27/09/2025.
//

import SwiftUI
import SwiftData

@MainActor
class RecipeFormViewModel: ObservableObject {
    private var context: ModelContext?
    let recipeToEdit: Recipe?

    // MARK: - Published form state
    @Published var name = ""
    @Published var desc = ""
    @Published var ingredients: [Ingredient] = []
    @Published var ingredientHeadings: [IngredientHeading] = []
    @Published var steps: [Step] = []

    // MARK: - Computed
    var combinedIngredientItems: [any IngredientItem] {
        let all: [any IngredientItem] = ingredients + ingredientHeadings
        return all.sorted { $0.index < $1.index }
    }

    // MARK: - Init
    init(context: ModelContext? = nil, recipeToEdit: Recipe? = nil) {
        self.context = context
        self.recipeToEdit = recipeToEdit
        loadRecipe()
    }

    func setContext(_ context: ModelContext) {
        self.context = context
    }

    // MARK: - Bindings
    func binding(for ingredient: Ingredient) -> Binding<Ingredient>? {
        guard let idx = ingredients.firstIndex(where: { $0.id == ingredient.id }) else { return nil }
        return Binding(
            get: { self.ingredients[idx] },
            set: { self.ingredients[idx] = $0 }
        )
    }

    func binding(for heading: IngredientHeading) -> Binding<IngredientHeading>? {
        guard let idx = ingredientHeadings.firstIndex(where: { $0.id == heading.id }) else { return nil }
        return Binding(
            get: { self.ingredientHeadings[idx] },
            set: { self.ingredientHeadings[idx] = $0 }
        )
    }

    // MARK: - Ingredient Items
    func addIngredient() {
        let newIndex = combinedIngredientItems.count
        ingredients.append(Ingredient(name: "", quantity: "", index: newIndex))
    }

    func addHeading() {
        let newIndex = combinedIngredientItems.count
        ingredientHeadings.append(IngredientHeading(name: "", index: newIndex))
    }

    func reindexIngredientItems(using ordered: [any IngredientItem]) {
        for (i, item) in ordered.enumerated() {
            if let ing = item as? Ingredient,
               let idx = ingredients.firstIndex(where: { $0.id == ing.id }) {
                ingredients[idx].index = i
            } else if let heading = item as? IngredientHeading,
                      let idx = ingredientHeadings.firstIndex(where: { $0.id == heading.id }) {
                ingredientHeadings[idx].index = i
            }
        }
    }

    func deleteIngredientItems(at offsets: IndexSet) {
        var all = combinedIngredientItems
        all.remove(atOffsets: offsets)
        ingredients = all.compactMap { $0 as? Ingredient }
        ingredientHeadings = all.compactMap { $0 as? IngredientHeading }
        reindexIngredientItems(using: all)
    }

    func moveIngredientItems(from indices: IndexSet, to newOffset: Int) {
        var all = combinedIngredientItems
        all.move(fromOffsets: indices, toOffset: newOffset)
        ingredients = all.compactMap { $0 as? Ingredient }
        ingredientHeadings = all.compactMap { $0 as? IngredientHeading }
        reindexIngredientItems(using: all)
    }

    // MARK: - Steps
    func addStep() {
        steps.append(Step(value: "", index: steps.count))
    }

    private func reindexSteps() {
        for (i, step) in steps.enumerated() {
            step.index = i
        }
    }

    func deleteSteps(at offsets: IndexSet) {
        steps.remove(atOffsets: offsets)
        reindexSteps()
    }

    func moveSteps(from indices: IndexSet, to newOffset: Int) {
        steps.move(fromOffsets: indices, toOffset: newOffset)
        reindexSteps()
    }

    // MARK: - Persistence
    func loadRecipe() {
        guard let recipe = recipeToEdit else { return }
        name = recipe.name
        desc = recipe.desc
        ingredients = recipe.ingredients.sorted { $0.index < $1.index }
        ingredientHeadings = recipe.ingredientHeadings.sorted { $0.index < $1.index }
        steps = recipe.steps.sorted { $0.index < $1.index }
    }

    func saveRecipe() -> Bool {
        guard !name.isEmpty else { return false }
        guard let context = context else { return false }

        // Normalize indices
        let all = combinedIngredientItems
        reindexIngredientItems(using: all)

        if let recipe = recipeToEdit {
            recipe.name = name
            recipe.desc = desc
            recipe.ingredients = ingredients
            recipe.ingredientHeadings = ingredientHeadings
            recipe.steps = steps
        } else {
            let newRecipe = Recipe(
                name: name,
                desc: desc,
                ingredients: ingredients,
                ingredientHeadings: ingredientHeadings,
                steps: steps
            )
            context.insert(newRecipe)
        }
        return true
    }
}
