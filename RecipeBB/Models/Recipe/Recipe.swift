//
//  Recipe.swift
//  RecipeBB
//
//  Created by Jay Hui on 21/08/2025.
//

import Foundation
import SwiftData

// MARK: - CloudKit schema rules
//
// Every model in this app is shaped for NSPersistentCloudKitContainer, which
// rejects a store that breaks any of these:
//
//   1. No uniqueness constraints. `id` carries no `@Attribute(.unique)`; it is
//      an ordinary attribute the app assigns in `init`. Nothing relies on the
//      store enforcing uniqueness — see `newObjectsOnCloudKitSchemaGetDistinctIDs`.
//   2. Every non-optional attribute has a default value.
//   3. Every relationship is optional, including to-many, and declares an
//      explicit inverse. That is why the arrays below are `[T]?` and why each
//      has a non-optional `…List` accessor: reads go through the accessor,
//      only writes touch the optional.
//
// The `.deny` delete rule is also unsupported; `.cascade` and `.nullify` are
// fine, as is `@Attribute(.externalStorage)` — it maps to a `CKAsset`.
//
// StoreMigrationTests pins that a populated 0.7.2 store still opens here.

@Model
class Recipe {
    var id: UUID = UUID()
    var name: String = ""
    var desc: String = ""
    @Attribute(.externalStorage) var photo: Data?
    @Relationship(deleteRule: .cascade, inverse: \Ingredient.recipe) var ingredients: [Ingredient]?
    @Relationship(deleteRule: .cascade, inverse: \IngredientHeading.recipe) var ingredientHeadings: [IngredientHeading]?
    @Relationship(deleteRule: .cascade, inverse: \Step.recipe) var steps: [Step]?
    @Relationship(deleteRule: .nullify, inverse: \RecipeTag.recipes) var tags: [RecipeTag]?
    var isFavorite: Bool = false
    var createdAt: Date = Date()

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

    // MARK: - Relationship accessors
    /// Non-optional views onto the relationships. CloudKit forces the stored
    /// properties to be optional; nothing reading them cares about the
    /// difference between "empty" and "not set", so reads go through these.
    var ingredientList: [Ingredient] { ingredients ?? [] }
    var headingList: [IngredientHeading] { ingredientHeadings ?? [] }
    var stepList: [Step] { steps ?? [] }
    var tagList: [RecipeTag] { tags ?? [] }

    // MARK: - Computed properties
    /// Ingredients and headings merged into a single list ordered by `sortOrder`.
    var sortedIngredientItems: [any IngredientItem] {
        mergedIngredientItems(ingredientList, headingList)
    }

    var sortedSteps: [Step] {
        stepList.sortedByOrder()
    }

    /// Deleted tags can linger in `tags` until the relationship change is
    /// processed, so filter them out before anyone reads a name off one.
    var sortedTags: [RecipeTag] {
        tagList
            .filter(\.isLive)
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}
