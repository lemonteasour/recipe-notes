//
//  Recipe.swift
//  RecipeNotes
//
//  Created by Jay Hui on 21/08/2025.
//

import Foundation
import SwiftData

@Model
class Recipe {
    @Attribute(.unique) var id: UUID
    var name: String
    var desc: String
    var ingredients: [Ingredient]
    var steps: [Step]
    var createdAt: Date

    init(
        name: String,
        desc: String,
        ingredients: [Ingredient] = [],
        steps: [Step]
    ) {
        self.id = UUID()
        self.name = name
        self.desc = desc
        self.ingredients = ingredients
        self.steps = steps
        self.createdAt = Date()
    }
}
