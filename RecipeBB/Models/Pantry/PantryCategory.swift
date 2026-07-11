//
//  PantryCategory.swift
//  RecipeBB
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

    // Deleting a category orphans its items (they become uncategorized) rather than
    // deleting them. Changing the delete rule needs no store migration — delete rules
    // are enforced at runtime and aren't part of the schema version hash.
    @Relationship(deleteRule: .nullify, inverse: \PantryItem.category)
    var items: [PantryItem]?

    init(
        name: String,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.sortOrder = sortOrder
    }
}
