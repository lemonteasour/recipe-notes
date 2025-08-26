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
    @State private var steps = ""

    var recipeToEdit: Recipe?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        String(localized: "Recipe name"),
                        text: $name
                    )
                    TextField(
                        String(localized: "Description"),
                        text: $desc,
                        axis: .vertical
                    )
                }

                Section(String(localized: "Ingredients")) {
                    ForEach($ingredients) { $ingredient in
                        HStack {
                            TextField(
                                String(localized: "Name"),
                                text: $ingredient.name
                            )
                            TextField(
                                String(localized: "Quantity"),
                                text: $ingredient.quantity
                            )
                            .frame(width: 100)
                            .multilineTextAlignment(.trailing)
                        }
                    }
                    .onDelete(perform: deleteIngredient)

                    Button(String(localized: "Add ingredient")) {
                        ingredients.append(
                            Ingredient(name: "", quantity: "")
                        )
                    }
                }

                Section(String(localized: "Steps")) {
                    TextEditor(text: $steps)
                }
            }
            .navigationTitle(String(localized: "New Recipe"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Save")) {
                        saveRecipe()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear(perform: loadRecipe)
        }
    }

    private func deleteIngredient(at offsets: IndexSet) {
        ingredients.remove(atOffsets: offsets)
    }

    private func loadRecipe() {
        guard let recipe = recipeToEdit else {
            // prefillFromClipboard()
            return
        }
        name = recipe.name
        desc = recipe.desc
        ingredients = recipe.ingredients
        steps = recipe.steps
    }


    private func saveRecipe() {
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
    }
}

#Preview {
    RecipeFormView()
}
