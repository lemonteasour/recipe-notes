//
//  IngredientItem.swift
//  RecipeBB
//
//  Created by Jay Hui on 11/09/2025.
//

import Foundation

protocol IngredientItem: Identifiable {
    var id: UUID { get }
    var name: String { get set }
    var sortOrder: Int { get set }
}

/// Merges ingredients and headings into a single list ordered by `sortOrder`.
func mergedIngredientItems(_ ingredients: [Ingredient], _ headings: [IngredientHeading]) -> [any IngredientItem] {
    (ingredients as [any IngredientItem] + headings as [any IngredientItem])
        .sorted { $0.sortOrder < $1.sortOrder }
}
