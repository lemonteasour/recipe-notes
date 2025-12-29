//
//  IngredientHeading.swift
//  RecipeNotes
//
//  Created by Jay Hui on 11/09/2025.
//

import Foundation
import SwiftData

@Model
class IngredientHeading: IngredientItem, Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    @Attribute(originalName: "index") var sortOrder: Int
    var recipe: Recipe?

    init(name: String, sortOrder: Int) {
        self.id = UUID()
        self.name = name
        self.sortOrder = sortOrder
    }
}
