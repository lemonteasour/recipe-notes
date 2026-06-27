//
//  PantryItem.swift
//  RecipeBB
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
    var sortOrder: Int
    var category: PantryCategory?

    init(
        name: String,
        quantity: String = "",
        sortOrder: Int,
        category: PantryCategory? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.quantity = quantity
        self.sortOrder = sortOrder
        self.category = category
    }
}
