//
//  Recipe.swift
//  RecipeBB
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
    @Attribute(.externalStorage) var photo: Data?
    @Relationship(deleteRule: .cascade, inverse: \Ingredient.recipe) var ingredients: [Ingredient]
    @Relationship(deleteRule: .cascade, inverse: \IngredientHeading.recipe) var ingredientHeadings: [IngredientHeading]
    @Relationship(deleteRule: .cascade, inverse: \Step.recipe) var steps: [Step]
    // Default values let existing stores lightweight-migrate to this schema.
    @Relationship(deleteRule: .nullify, inverse: \RecipeTag.recipes) var tags: [RecipeTag] = []
    var isFavorite: Bool = false
    var createdAt: Date

    init(
        name: String,
        desc: String,
        photo: Data? = nil,
        ingredients: [Ingredient] = [],
        ingredientHeadings: [IngredientHeading] = [],
        steps: [Step] = []
    ) {
        self.id = UUID()
        self.name = name
        self.desc = desc
        self.photo = photo
        self.ingredients = ingredients
        self.ingredientHeadings = ingredientHeadings
        self.steps = steps
        self.createdAt = Date()
    }

    // MARK: - Computed properties
    /// Ingredients and headings merged into a single list ordered by `sortOrder`.
    var sortedIngredientItems: [any IngredientItem] {
        mergedIngredientItems(ingredients, ingredientHeadings)
    }

    var sortedSteps: [Step] {
        steps.sortedByOrder()
    }

    var sortedTags: [RecipeTag] {
        tags.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}
