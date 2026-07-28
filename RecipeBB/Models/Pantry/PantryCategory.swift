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

    // Deleting a category orphans its items (they become uncategorized) rather
    // than deleting them. This was .cascade up to 0.6.0; changing it shipped
    // without a migration, and StoreMigrationTests confirms a populated 0.6.0
    // store still opens and keeps its items. Note this is a behavior change as
    // well as a rule change — items that used to disappear with their category
    // now survive as uncategorized.
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
