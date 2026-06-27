//
//  IngredientCatalog.swift
//  RecipeBB
//
//  Created by Jay Hui on 27/09/2025.
//

import Foundation
import SwiftData

/// Helpers for deriving the set of ingredient names known to the app.
enum IngredientCatalog {
    /// Normalizes raw ingredient names into a unique, trimmed, alphabetically sorted list.
    static func normalized<S: Sequence>(_ names: S) -> [String] where S.Element == String {
        let cleaned = names
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return Array(Set(cleaned)).sorted()
    }

    /// Fetches every unique ingredient name stored in the given context.
    static func uniqueNames(in context: ModelContext) -> [String] {
        let ingredients = (try? context.fetch(FetchDescriptor<Ingredient>())) ?? []
        return normalized(ingredients.map(\.name))
    }
}
