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
///
/// Ingredients and headings share one index space, so ties are possible across
/// the two types. Nothing in the app produces one today — every writer numbers
/// both from the same running count — but once devices sync, two of them
/// reordering the same recipe offline merge field-by-field and can land on
/// duplicate `sortOrder`s. Breaking ties on `id` keeps the list from shuffling
/// between renders until the next save renormalizes it. See `sortedByOrder()`.
func mergedIngredientItems(_ ingredients: [Ingredient], _ headings: [IngredientHeading]) -> [any IngredientItem] {
    (ingredients as [any IngredientItem] + headings as [any IngredientItem])
        .sorted { lhs, rhs in
            lhs.sortOrder == rhs.sortOrder
                ? lhs.id.uuidString < rhs.id.uuidString
                : lhs.sortOrder < rhs.sortOrder
        }
}
