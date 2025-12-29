//
//  Step.swift
//  RecipeNotes
//
//  Created by Jay Hui on 26/08/2025.
//

import Foundation
import SwiftData

@Model
class Step: Identifiable {
    @Attribute(.unique) var id: UUID
    var value: String
    @Attribute(originalName: "index") var sortOrder: Int
    var recipe: Recipe?

    init(value: String, sortOrder: Int) {
        self.id = UUID()
        self.value = value
        self.sortOrder = sortOrder
    }
}
