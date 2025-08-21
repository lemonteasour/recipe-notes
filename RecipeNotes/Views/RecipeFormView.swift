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
    @State private var ingredientsText = ""
    @State private var steps = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section{
                    TextField("Title", text: $title)
                    TextField("Description", text: $desc, axis: .vertical)
                }

                Section("Ingredients (one per line)") {
                    TextEditor(text: $ingredientsText)
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
    
    private func saveRecipe() {
        let ingredients = ingredientsText
            .split(separator: "\n")
            .map { String($0) }
        
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
