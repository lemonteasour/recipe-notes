//
//  ValidationError.swift
//  RecipeBB
//
//  Created by Jay Hui on 27/09/2025.
//

import Foundation

/// User-facing validation failures surfaced when saving recipes or pantry data.
enum ValidationError: LocalizedError {
    case emptyRecipeName
    case emptyPantryItemName
    case emptyCategoryName

    var errorDescription: String? {
        switch self {
        case .emptyRecipeName:
            return String(localized: "Recipe name cannot be empty.")
        case .emptyPantryItemName:
            return String(localized: "Item name cannot be empty.")
        case .emptyCategoryName:
            return String(localized: "Category name cannot be empty.")
        }
    }
}
