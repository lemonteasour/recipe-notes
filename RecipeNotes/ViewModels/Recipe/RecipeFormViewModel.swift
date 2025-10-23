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
    private let context: ModelContext
    let recipeToEdit: Recipe?

    // MARK: - Published form state
    @Published var name = ""
    @Published var desc = ""
    @Published var ingredients: [Ingredient] = []
    @Published var allIngredientNames: [String] = []
    @Published var ingredientHeadings: [IngredientHeading] = []
    @Published var steps: [Step] = []

    // MARK: - Computed
    var combinedIngredientItems: [any IngredientItem] {
        let all: [any IngredientItem] = ingredients + ingredientHeadings
        return all.sorted { $0.sortOrder < $1.sortOrder }
    }

    var sortedSteps: [Step] {
        steps.sorted { $0.sortOrder < $1.sortOrder }
    }

    // MARK: - Init
    init(context: ModelContext, recipeToEdit: Recipe? = nil) {
        self.context = context
        self.recipeToEdit = recipeToEdit
        self.allIngredientNames = fetchAllIngredientNames()
        loadRecipe()
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

    func binding(for step: Step) -> Binding<Step>? {
        guard let idx = steps.firstIndex(where: { $0.id == step.id }) else { return nil }
        return Binding(
            get: { self.steps[idx] },
            set: { self.steps[idx] = $0 }
        )
    }

    // MARK: - Ingredient Items
    func addIngredient() {
        let newIndex = combinedIngredientItems.count
        ingredients.append(Ingredient(name: "", quantity: "", sortOrder: newIndex))
    }

    func addHeading() {
        let newIndex = combinedIngredientItems.count
        ingredientHeadings.append(IngredientHeading(name: "", sortOrder: newIndex))
    }

    func reindexIngredientItems(using ordered: [any IngredientItem]) {
        for (i, item) in ordered.enumerated() {
            if let ing = item as? Ingredient,
               let idx = ingredients.firstIndex(where: { $0.id == ing.id }) {
                ingredients[idx].sortOrder = i
            } else if let heading = item as? IngredientHeading,
                      let idx = ingredientHeadings.firstIndex(where: { $0.id == heading.id }) {
                ingredientHeadings[idx].sortOrder = i
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

    private func fetchAllIngredientNames() -> [String] {
        let descriptor = FetchDescriptor<Ingredient>()
        do {
            let ingredients = try context.fetch(descriptor)
            let names = ingredients
                .map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            return Array(Set(names)).sorted()
        } catch {
            print("Error fetching ingredient names: \(error)")
            return []
        }
    }

    // MARK: - Steps
    func addStep() {
        steps.append(Step(value: "", sortOrder: steps.count))
    }

    private func reindexSteps() {
        for (i, step) in steps.enumerated() {
            step.sortOrder = i
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
        ingredients = recipe.ingredients.sorted { $0.sortOrder < $1.sortOrder }
        ingredientHeadings = recipe.ingredientHeadings.sorted { $0.sortOrder < $1.sortOrder }
        steps = recipe.steps.sorted { $0.sortOrder < $1.sortOrder }
    }

    func saveRecipe() throws {
        guard !name.isEmpty else {
            throw RecipeError.emptyName
        }

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

        try context.save()
    }
}
