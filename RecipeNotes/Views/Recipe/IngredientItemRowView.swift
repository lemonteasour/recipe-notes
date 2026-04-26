//
//  IngredientItemRowView.swift
//  RecipeNotes
//

import SwiftUI

struct IngredientItemRowView: View {
    let item: any IngredientItem

    var body: some View {
        if let ingredient = item as? Ingredient {
            HStack {
                Text(ingredient.name)
                Spacer()
                Text(ingredient.quantity)
                    .foregroundStyle(.secondary)
            }
        } else if let heading = item as? IngredientHeading {
            HStack {
                Text(heading.name)
                    .font(.headline)
                Spacer()
            }
        }
    }
}
