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
                        ForEach(recipe.sortedIngredients, id: \.id) { ingredientItem in
                            if let ingredient = ingredientItem as? Ingredient {
                                HStack {
                                    Text(ingredient.name)
                                    Spacer()
                                    Text(ingredient.quantity)
                                        .foregroundColor(.secondary)
                                }
                            } else if let heading = ingredientItem as? IngredientHeading {
                                Text(heading.name)
                                    .font(.headline)
                            }
                        }
                    }


                    Section("Steps") {
                        ForEach(recipe.sortedSteps, id: \.id) { step in
                            HStack(alignment: .top) {
                                Text("\(step.index + 1).")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 24)

                                Text(step.value)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(recipe.name)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(cookingMode ? "Normal" : "Cook") {
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
            Ingredient(name: "Egg", quantity: "4", index: 0),
            Ingredient(name: "Chicken", quantity: "300g", index: 1)
        ],
        steps: [
            Step(value: "Step1", index: 0),
            Step(value: "Step1", index: 1),
            Step(value: "Step1", index: 2)
        ])
    RecipeDetailView(recipe: recipe)
}
