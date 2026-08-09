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
    var id: UUID = UUID()
    var value: String = ""
    @Attribute(originalName: "index") var sortOrder: Int = 0
    var recipe: Recipe?

    init(value: String, sortOrder: Int) {
        self.id = UUID()
        self.value = value
        self.sortOrder = sortOrder
    }
}

extension Array where Element == Step {
    /// Returns the steps ordered by their `sortOrder`.
    ///
    /// Ties break on `id` so the order is deterministic. Once devices sync,
    /// two of them reordering the same recipe offline merge field-by-field and
    /// can land on duplicate `sortOrder`s; without a tie-break the list would
    /// shuffle between renders until the next save renormalizes it.
    func sortedByOrder() -> [Step] {
        sorted { lhs, rhs in
            lhs.sortOrder == rhs.sortOrder
                ? lhs.id.uuidString < rhs.id.uuidString
                : lhs.sortOrder < rhs.sortOrder
        }
    }
}
