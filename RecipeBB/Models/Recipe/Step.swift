//
//  Step.swift
//  RecipeBB
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

extension Array where Element == Step {
    /// Returns the steps ordered by their `sortOrder`.
    func sortedByOrder() -> [Step] {
        sorted { $0.sortOrder < $1.sortOrder }
    }
}
