//
//  IngredientItem.swift
//  RecipeNotes
//
//  Created by Jay Hui on 11/09/2025.
//

import Foundation

protocol IngredientItem: Identifiable {
    var id: UUID { get }
    var name: String { get set }
    var index: Int { get set }
}
