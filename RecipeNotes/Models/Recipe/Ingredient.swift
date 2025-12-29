//
//  Ingredient.swift
//  RecipeNotes
//
//  Created by Jay Hui on 21/08/2025.
//

import Foundation
import SwiftData

@Model
class Ingredient: IngredientItem, Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var quantity: String
    @Attribute(originalName: "index") var sortOrder: Int
    var recipe: Recipe?

    init(name: String, quantity: String, sortOrder: Int) {
        self.id = UUID()
        self.name = name
        self.quantity = quantity
        self.sortOrder = sortOrder
    }
}
