//
//  RecipeError.swift
//  RecipeNotes
//
//  Created by Jay Hui on 15/10/2025.
//

import Foundation

enum RecipeError: LocalizedError {
    case emptyName

    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Recipe name cannot be empty."
        }
    }
}
