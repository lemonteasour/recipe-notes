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
    var title: String
    var desc: String
    var ingredients: [String]
    var steps: String
    var createdAt: Date

    init(
        title: String,
        desc: String,
        ingredients: [String] = [],
        steps: String
    ) {
        self.id = UUID()
        self.title = title
        self.desc = desc
        self.ingredients = ingredients
        self.steps = steps
        self.createdAt = Date()
    }
}
