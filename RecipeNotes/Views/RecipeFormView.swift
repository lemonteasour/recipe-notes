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
    @State private var steps: [Step] = []

    var recipeToEdit: Recipe?

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Recipe name", text: $name)

                    TextField("Description", text: $desc, axis: .vertical)
                }

                Section("Ingredients") {
                    ForEach(ingredients.sorted(by: { $0.index < $1.index }), id: \.id) { ingredient in
                        if let binding = $ingredients.first(where: { $0.id == ingredient.id }) {
                            HStack {
                                TextField("Name", text: binding.name)
                                TextField("Quantity", text: binding.quantity)
                                    .frame(width: 100)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                    }
                    .onDelete { offsets in
                        ingredients.remove(atOffsets: offsets)
                        reindexIngredients()
                    }
                    .onMove { indices, newOffset in
                        ingredients.move(fromOffsets: indices, toOffset: newOffset)
                        reindexIngredients()
                    }

                    Button("Add ingredient") {
                        ingredients.append(Ingredient(name: "", quantity: "", index: ingredients.count))
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
                    .onDelete { offsets in
                        steps.remove(atOffsets: offsets)
                        reindexSteps()
                    }
                    .onMove { indices, newOffset in
                        steps.move(fromOffsets: indices, toOffset: newOffset)
                        reindexSteps()
                    }

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

    private func reindexIngredients() {
        for (index, ingredient) in ingredients.enumerated() {
            ingredient.index = index
        }
    }

    private func reindexSteps() {
        for (index, step) in steps.enumerated() {
            step.index = index
        }
    }

    private func loadRecipe() {
        guard let recipe = recipeToEdit else {
            // TODO: Clipboard autofill
            return
        }
        name = recipe.name
        desc = recipe.desc
        ingredients = recipe.ingredients
        steps = recipe.steps
    }


    private func saveRecipe() -> Bool {
        // Form validation logic
        guard !name.isEmpty else { return false }

        if let recipe = recipeToEdit {
            recipe.name = name
            recipe.desc = desc
            recipe.ingredients = ingredients
            recipe.steps = steps
        } else {
            let newRecipe = Recipe(
                name: name,
                desc: desc,
                ingredients: ingredients,
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
