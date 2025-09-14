//
//  RecipeFormView.swift
//  RecipeNotes
//
//  Created by Jay Hui on 21/08/2025.
//

import SwiftUI
import SwiftData

struct RecipeFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var desc = ""
    @State private var ingredients: [Ingredient] = []
    @State private var ingredientHeadings: [IngredientHeading] = []
    @State private var steps: [Step] = []

    var recipeToEdit: Recipe?

    /// Merge and sort all items into an array of IngredientItems
    private var combinedIngredientItems: [any IngredientItem] {
        let all: [any IngredientItem] = ingredients + ingredientHeadings
        return all.sorted { $0.index < $1.index }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Recipe name", text: $name)
                    TextField("Description", text: $desc, axis: .vertical)
                }

                Section("Ingredients") {
                    ForEach(combinedIngredientItems, id: \.id) { item in
                        if let ingredient = item as? Ingredient,
                           let binding = binding(for: ingredient) {
                            HStack {
                                TextField("Name", text: binding.name)
                                TextField("Quantity", text: binding.quantity)
                                    .frame(width: 100)
                                    .multilineTextAlignment(.trailing)
                            }
                        } else if let heading = item as? IngredientHeading,
                                  let binding = binding(for: heading) {
                            TextField("Heading", text: binding.name)
                                .font(.headline)
                        }
                    }
                    .onDelete(perform: deleteIngredientItems)
                    .onMove(perform: moveIngredientItems)

                    Button("Add ingredient") {
                        // append at the end of the current UI order
                        let newIndex = combinedIngredientItems.count
                        ingredients.append(Ingredient(name: "", quantity: "", index: newIndex))
                    }

                    Button("Add heading") {
                        let newIndex = combinedIngredientItems.count
                        ingredientHeadings.append(IngredientHeading(name: "", index: newIndex))
                    }

                }

                Section("Steps") {
                    ForEach(steps.sorted(by: { $0.index < $1.index }), id: \.id) { step in
                        if let binding = $steps.first(where: { $0.id == step.id }) {
                            HStack(alignment: .top) {
                                Text("\(step.index + 1).")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 24)

                                TextField("Step", text: binding.value, axis: .vertical)
                            }
                        }
                    }
                    .onDelete(perform: deleteSteps)
                    .onMove(perform: moveSteps)

                    Button("Add step") {
                        steps.append(Step(value: "", index: steps.count))
                    }
                }
            }
            .navigationTitle(recipeToEdit == nil ? "New Recipe" : "Edit Recipe")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if saveRecipe() { dismiss() }
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear(perform: loadRecipe)
        }
    }
}

// MARK: - Private helpers
extension RecipeFormView {
    /// Return Binding for an Ingredient by finding its index in the local array.
    func binding(for ingredient: Ingredient) -> Binding<Ingredient>? {
        guard let idx = ingredients.firstIndex(where: { $0.id == ingredient.id }) else { return nil }
        return $ingredients[idx]
    }

    /// Return Binding for an IngredientHeading
    func binding(for heading: IngredientHeading) -> Binding<IngredientHeading>? {
        guard let idx = ingredientHeadings.firstIndex(where: { $0.id == heading.id }) else { return nil }
        return $ingredientHeadings[idx]
    }

    /// Reindex ordered list (use the UI order array)
    func reindexIngredientItems(using ordered: [any IngredientItem]) {
        for (i, item) in ordered.enumerated() {
            if let ingredient = item as? Ingredient,
               let idx = ingredients.firstIndex(where: { $0.id == ingredient.id }) {
                ingredients[idx].index = i
            } else if let heading = item as? IngredientHeading,
                      let idx = ingredientHeadings.firstIndex(where: { $0.id == heading.id }) {
                ingredientHeadings[idx].index = i
            }
        }
    }

    /// Delete: compute the current UI order, remove offsets from that, and persist indices from resulting order
    func deleteIngredientItems(at offsets: IndexSet) {
        var all = combinedIngredientItems
        all.remove(atOffsets: offsets)

        ingredients = all.compactMap { $0 as? Ingredient }
        ingredientHeadings = all.compactMap { $0 as? IngredientHeading }

        reindexIngredientItems(using: all)
    }

    /// Move: compute a local mutable 'all' representing UI order, reorder it, then persist and reindex from it
    func moveIngredientItems(from indices: IndexSet, to newOffset: Int) {
        var all = combinedIngredientItems
        all.move(fromOffsets: indices, toOffset: newOffset)

        ingredients = all.compactMap { $0 as? Ingredient }
        ingredientHeadings = all.compactMap { $0 as? IngredientHeading }

        reindexIngredientItems(using: all)
    }

    func reindexSteps() {
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



    func loadRecipe() {
        guard let recipe = recipeToEdit else { return }
        name = recipe.name
        desc = recipe.desc

        // sort on load by each item's index so local arrays reflect UI order
        ingredients = recipe.ingredients.sorted(by: { $0.index < $1.index })
        ingredientHeadings = recipe.ingredientHeadings.sorted(by: { $0.index < $1.index })
        steps = recipe.steps.sorted(by: { $0.index < $1.index })
    }

    func saveRecipe() -> Bool {
        guard !name.isEmpty else { return false }

        // As a safeguard, normalize indices before saving (so stored indices match UI order)
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

#Preview {
    RecipeFormView()
}
