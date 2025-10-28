//
//  PantryCategory.swift
//  RecipeNotes
//
//  Created by Jay Hui on 23/10/2025.
//

import Foundation
import SwiftData

@Model
class PantryCategory {
    @Attribute(.unique) var id: UUID
    var name: String
    var sortOrder: Int
    var createdAt: Date

//    @Relationship(deleteRule: .cascade, inverse: \PantryItem.category)
    var items: [PantryItem]?

    init(
        name: String,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }
}
