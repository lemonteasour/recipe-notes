//
//  RecipeDetailView.swift
//  RecipeNotes
//
//  Created by Jay Hui on 21/08/2025.
//

import SwiftUI

struct RecipeDetailView: View {
    var recipe: Recipe

    @State private var showEdit = false
    @State private var cookingMode = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if cookingMode {
                RecipeDetailCookingView(recipe: recipe)
            } else {
                List {
                    if !recipe.desc.isEmpty {
                        Section("Details") {
                            Text(recipe.desc)
                        }
                    }

                    Section("Ingredients") {
                        ForEach(recipe.ingredients) { ingredient in
                            HStack {
                                Text(ingredient.name)
                                Spacer()
                                Text(ingredient.quantity)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Section("Steps") {
                        ForEach(recipe.steps.indices, id: \.self) { index in
                            HStack(alignment: .top) {
                                Text("\(index + 1).")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 24)

                                Text(recipe.steps[index].value)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(recipe.name)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(
                    cookingMode ? "Normal" : "Cook"
                ) {
                    cookingMode.toggle()
                }
                Button("Edit") {
                    showEdit = true
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            RecipeFormView(recipeToEdit: recipe)
        }
    }
}

#Preview {
    let recipe = Recipe(
        name: "Oyakodon",
        desc: "Desc",
        ingredients: [
            Ingredient(name: "Egg", quantity: "4"),
            Ingredient(name: "Chicken", quantity: "300g")
        ],
        steps: [Step(value: "Step")])
    RecipeDetailView(recipe: recipe)
}
