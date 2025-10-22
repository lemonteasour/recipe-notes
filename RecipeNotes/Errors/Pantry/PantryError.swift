//
//  PantryError.swift
//  RecipeNotes
//
//  Created by Jay Hui on 16/10/2025.
//

import Foundation

enum PantryError: LocalizedError {
    case emptyName
    case saveFailed(Error)

    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Item name cannot be empty."
        case .saveFailed(let error):
            return "Failed to save: \(error.localizedDescription)"
        }
    }
}
