//
//  RecipeDetailView.swift
//  RecipeNotes
//
//  Created by Jay Hui on 21/08/2025.
//


import SwiftUI

struct RecipeDetailView: View {
    @Bindable var recipe: Recipe
    @State private var cookingMode = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if cookingMode {
                ScrollView {
                    Text(String(localized: "Ingredients"))
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

                    Text(String(localized: "Steps"))
                        .font(.title2).bold()
                        .padding(.top)
                    Text(recipe.steps)
                        .font(.body)
                        .padding(.bottom)
                }
                .padding()
            } else {
                List {
                    Section {
                        Text(recipe.desc)
                    }
                    Section(String(localized: "Ingredients")) {
                        ForEach(recipe.ingredients, id: \.self) { ingredient in
                            Text(ingredient.name)
                        }
                    }

                    Section(String(localized: "Steps")) {
                        Text(recipe.steps)
                    }
                }
            }
        }
        .navigationTitle(recipe.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(cookingMode ?
                       String(localized: "Normal") :
                        String(localized: "Cook")
                ) {
                    cookingMode.toggle()
                }
            }
        }
    }
}

#Preview {
    let recipe = Recipe(
        name: "Oyakodon",
        desc: "Desc",
        ingredients: [
            Ingredient(name: "Onion", quantity: "1"),
            Ingredient(name: "Chicken", quantity: "2")
        ],
        steps: "Steps")
    RecipeDetailView(recipe: recipe)
}
