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
    @Relationship(deleteRule: .cascade) var ingredients: [Ingredient]
    @Relationship(deleteRule: .cascade) var ingredientHeadings: [IngredientHeading]
    @Relationship(deleteRule: .cascade) var steps: [Step]
    var createdAt: Date

    init(
        name: String,
        desc: String,
        ingredients: [Ingredient] = [],
        ingredientHeadings: [IngredientHeading] = [],
        steps: [Step] = []
    ) {
        self.id = UUID()
        self.name = name
        self.desc = desc
        self.ingredients = ingredients
        self.ingredientHeadings = ingredientHeadings
        self.steps = steps
        self.createdAt = Date()
    }

    // MARK: - Computed properties
    var sortedIngredients: [any IngredientItem] {
        (ingredients as [any IngredientItem] + ingredientHeadings as [any IngredientItem]).sorted { $0.index < $1.index }
    }

    var sortedSteps: [Step] {
        steps.sorted { $0.index < $1.index }
    }
}
