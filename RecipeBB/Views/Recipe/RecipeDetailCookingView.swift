//
//  RecipeDetailCookingView.swift
//  RecipeBB
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
                    .padding(.vertical, 4)

                ForEach(recipe.sortedIngredients, id: \.id) { item in
                    IngredientItemRowView(item: item)
                }
            }

            VStack {
                Text("Steps")
                    .font(.title2).bold()
                    .padding(.vertical, 4)

                ForEach(recipe.sortedSteps, id: \.id) { step in
                    StepRowView(step: step)
                        .padding(.vertical, 2)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

#Preview {
    RecipeDetailCookingView(recipe: PreviewData.sampleRecipeEnglish)
}
