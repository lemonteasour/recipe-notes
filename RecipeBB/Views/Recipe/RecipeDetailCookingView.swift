//
//  RecipeDetailCookingView.swift
//  RecipeBB
//
//  Created by Jay Hui on 05/09/2025.
//

import SwiftUI

/// Read-while-you-cook layout: larger type and looser spacing than the detail
/// list, so the recipe stays legible with the phone propped up on the counter.
struct RecipeDetailCookingView: View {
    var recipe: Recipe

    var body: some View {
        let ingredientItems = recipe.sortedIngredientItems
        let steps = recipe.sortedSteps

        if ingredientItems.isEmpty, steps.isEmpty {
            ContentUnavailableView(
                "Nothing to Cook",
                systemImage: "list.bullet.rectangle",
                description: Text("This recipe has no ingredients or steps yet.")
            )
        } else {
            content(ingredientItems: ingredientItems, steps: steps)
        }
    }

    private func content(ingredientItems: [any IngredientItem], steps: [Step]) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                if !ingredientItems.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Ingredients")
                            .font(.title2).bold()

                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(ingredientItems.enumerated()), id: \.element.id) { index, item in
                                if let heading = item as? IngredientHeading {
                                    Text(heading.name)
                                        .font(.title3).bold()
                                        .padding(.top, index == 0 ? 0 : 16)
                                        .padding(.bottom, 8)
                                } else if let ingredient = item as? Ingredient {
                                    if index > 0, !(ingredientItems[index - 1] is IngredientHeading) {
                                        Divider()
                                            .opacity(0.6)
                                            .padding(.horizontal, 16)
                                    }

                                    HStack(alignment: .firstTextBaseline) {
                                        Text(ingredient.name)
                                        Spacer(minLength: 16)
                                        Text(ingredient.quantity)
                                            .foregroundStyle(.secondary)
                                            .multilineTextAlignment(.trailing)
                                    }
                                    .font(.title3)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                    }
                }

                if !steps.isEmpty {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Steps")
                            .font(.title2).bold()

                        // Numbered by position rather than `sortOrder`, so steps
                        // that land on a duplicate order after a sync merge still
                        // read 1, 2, 3.
                        ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                Text(index + 1, format: .number)
                                    .font(.title3).bold()
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                                    .frame(width: 20, alignment: .trailing)

                                Text(step.value)
                                    .font(.title3)
                                    .lineSpacing(4)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
    }
}

#Preview {
    RecipeDetailCookingView(recipe: PreviewData.sampleRecipeEnglish)
}
