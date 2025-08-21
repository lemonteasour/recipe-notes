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

    @State private var title = ""
    @State private var desc = ""
    @State private var ingredients: [Ingredient] = []
    @State private var steps = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section{
                    TextField("Title", text: $title)
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
                    .onDelete(perform: deleteIngredient)
                    
                    Button {
                        ingredients.append(Ingredient(name: "", quantity: ""))
                    } label: {
                        Label("Add Ingredient", systemImage: "plus.circle")
                    }
                }

                Section("Steps") {
                    TextEditor(text: $steps)
                }
            }
            .navigationTitle("Add Recipe")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRecipe()
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func deleteIngredient(at offsets: IndexSet) {
        ingredients.remove(atOffsets: offsets)
    }

    private func saveRecipe() {
        let newRecipe = Recipe(
            title: title,
            desc: desc,
            ingredients: ingredients,
            steps: steps
        )
        context.insert(newRecipe)
    }
}

#Preview {
    RecipeFormView()
}
