//
//  PantryError.swift
//  RecipeNotes
//
//  Created by Jay Hui on 16/10/2025.
//

import Foundation

enum PantryError: LocalizedError {
    case emptyName

    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Item name cannot be empty."
        }
    }
}
