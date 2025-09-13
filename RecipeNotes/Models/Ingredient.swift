//
//  Ingredient.swift
//  RecipeNotes
//
//  Created by Jay Hui on 21/08/2025.
//

import Foundation
import SwiftData

@Model
class Ingredient: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var quantity: String
    var index: Int

    init(name: String, quantity: String, index: Int) {
        self.id = UUID()
        self.name = name
        self.quantity = quantity
        self.index = index
    }
}
