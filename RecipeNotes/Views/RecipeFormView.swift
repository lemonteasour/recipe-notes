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
                Section(String(localized: "Details")) {
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
                    .onDelete { offsets in
                        ingredients.remove(atOffsets: offsets)
                    }
                    .onMove { indices, newOffset in
                        ingredients.move(fromOffsets: indices, toOffset: newOffset)
                    }
                    
                    Button(String(localized: "Add ingredient")) {
                        ingredients.append(
                            Ingredient(name: "", quantity: "")
                        )
                    }
                }
                
                Section(String(localized: "Steps")) {
                    ForEach(Array($steps.enumerated()), id: \.element.id) { index, $step in
                        HStack(alignment: .top) {
                            Text("\(index + 1).")
                                .foregroundStyle(.secondary)
                                .frame(width: 24, alignment: .trailing)
                            
                            TextField(
                                String(localized: "Step"),
                                text: $step.value,
                                axis: .vertical
                            )
                        }
                    }
                    .onDelete { offsets in
                        steps.remove(atOffsets: offsets)
                    }
                    .onMove { indices, newOffset in
                        steps.move(fromOffsets: indices, toOffset: newOffset)
                    }
                    
                    Button(String(localized: "Add step")) {
                        steps.append(Step(value: ""))
                    }
                }
                
            }
            .navigationTitle(String(localized: "New Recipe"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
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
