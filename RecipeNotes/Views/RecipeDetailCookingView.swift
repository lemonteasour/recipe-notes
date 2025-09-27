//
//  RecipeDetailCookingView.swift
//  RecipeNotes
//
//  Created by Jay Hui on 05/09/2025.
//

import SwiftUI

struct RecipeDetailCookingView: View {
    var recipe: Recipe

    var body: some View {
        ScrollView {
            VStack {
                Text("Ingredients")
                    .font(.title2).bold()

                ForEach(recipe.sortedIngredients, id: \.id) { ingredientItem in
                    if let ingredient = ingredientItem as? Ingredient {
                        HStack {
                            Text(ingredient.name)
                            Spacer()
                            Text(ingredient.quantity)
                                .foregroundColor(.secondary)
                        }
                        .font(.body)
                    } else if let heading = ingredientItem as? IngredientHeading {
                        HStack {
                            Text(heading.name)
                                .font(.headline)
                            Spacer()
                        }
                    }
                }
            }

            VStack {
                Text("Steps")
                    .font(.title2).bold()

                ForEach(recipe.sortedSteps, id: \.id) { step in
                    HStack {
                        Text("\(step.index + 1).")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)

                        Text(step.value)
                        Spacer()
                    }
                }
            }
        }
        .frame(width: 300)
        .padding(.vertical, 16)
    }
}

#Preview {
    RecipeDetailCookingView(recipe: PreviewData.sampleRecipe)
}
