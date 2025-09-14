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
    var index: Int

    init(name: String, index: Int) {
        self.id = UUID()
        self.name = name
        self.index = index
    }
}
