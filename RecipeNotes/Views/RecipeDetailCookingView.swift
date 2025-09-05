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

                ForEach(recipe.ingredients) { ingredient in
                    HStack {
                        Text(ingredient.name)
                        Spacer()
                        Text(ingredient.quantity)
                            .foregroundColor(.secondary)
                    }
                    .font(.body)
                }
            }

            VStack {
                Text("Steps")
                    .font(.title2).bold()

                ForEach(recipe.steps.indices, id: \.self) { index in
                    HStack {
                        Text("\(index + 1).")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)

                        Text(recipe.steps[index].value)
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
    let recipe = Recipe(
        name: "Oyakodon",
        desc: "Desc",
        ingredients: [
            Ingredient(name: "Egg", quantity: "4"),
            Ingredient(name: "Chicken", quantity: "300g")
        ],
        steps: [Step(value: "Step")])
    RecipeDetailCookingView(recipe: recipe)
}
