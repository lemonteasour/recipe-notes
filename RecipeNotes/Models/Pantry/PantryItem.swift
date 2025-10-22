//
//  PantryItem.swift
//  RecipeNotes
//
//  Created by Jay Hui on 15/10/2025.
//

import Foundation
import SwiftData

@Model
class PantryItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var quantity: String
    var createdAt: Date

    init(
        name: String,
        quantity: String = "",
    ) {
        self.id = UUID()
        self.name = name
        self.quantity = quantity
        self.createdAt = Date()
    }
}
