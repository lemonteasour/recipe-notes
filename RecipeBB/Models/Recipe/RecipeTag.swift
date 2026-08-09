//
//  RecipeTag.swift
//  RecipeBB
//
//  Created by Jay Hui on 12/07/2026.
//

import Foundation
import SwiftData

@Model
class RecipeTag {
    var id: UUID = UUID()
    var name: String = ""
    var createdAt: Date = Date()

    // Inverse is declared on Recipe.tags. Deleting a tag only unlinks it
    // from its recipes; deleting a recipe only unlinks it from its tags.
    var recipes: [Recipe]?

    /// Non-optional view onto `recipes` — see the schema rules on `Recipe`.
    var recipeList: [Recipe] { recipes ?? [] }

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
    }
}
