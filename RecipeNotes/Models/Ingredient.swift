//
//  Ingredient.swift
//  RecipeNotes
//
//  Created by Jay Hui on 21/08/2025.
//

import Foundation
import SwiftData

@Model
class Ingredient {
    var name: String
    var quantity: String
    
    init(name: String, quantity: String) {
        self.name = name
        self.quantity = quantity
    }
}
