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
                    ForEach($ingredients) { $ingredient in
                        HStack {
                            TextField("Name", text: $ingredient.name)

                            TextField("Quantity", text: $ingredient.quantity)
                            .frame(width: 100)
                            .multilineTextAlignment(.trailing)
                        }
                    }
                    .onDelete { offsets in
                        ingredients.remove(atOffsets: offsets)
                    }
                    .onMove { indices, newOffset in
                        ingredients.move(fromOffsets: indices, toOffset: newOffset)
                    }

                    Button("Add ingredient") {
                        ingredients.append(
                            Ingredient(name: "", quantity: "")
                        )
                    }
                }

                Section("Steps") {
                    ForEach(Array($steps.enumerated()), id: \.element.id) { index, $step in
                        HStack(alignment: .top) {
                            Text("\(index + 1).")
                                .foregroundStyle(.secondary)
                                .frame(width: 24)

                            TextField("Step", text: $step.value, axis: .vertical)
                        }
                    }
                    .onDelete { offsets in
                        steps.remove(atOffsets: offsets)
                    }
                    .onMove { indices, newOffset in
                        steps.move(fromOffsets: indices, toOffset: newOffset)
                    }

                    Button("Add step") {
                        steps.append(Step(value: ""))
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
