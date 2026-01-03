//
//  RecipeClipboardService.swift
//  RecipeNotes
//
//  Created by Jay Hui on 31/10/2025.
//

import Foundation

class RecipeClipboardService {

    /// Exports a recipe to formatted text
    /// - Parameter recipe: The recipe to export
    /// - Returns: A formatted text representation of the recipe
    static func exportRecipeToText(_ recipe: Recipe) -> String {
        var output = ""

        // Recipe name
        output += recipe.name + "\n"

        // Description
        if !recipe.desc.isEmpty {
            output += recipe.desc + "\n"
        }

        output += "\n"

        // Ingredients
        if !recipe.sortedIngredients.isEmpty {
            output += String(localized: "Ingredients") + "\n"

            for item in recipe.sortedIngredients {
                if let heading = item as? IngredientHeading {
                    // Ingredient heading
                    output += heading.name + ":\n"
                } else if let ingredient = item as? Ingredient {
                    // Regular ingredient
                    if ingredient.quantity.isEmpty {
                        output += ingredient.name + "\n"
                    } else {
                        output += ingredient.name + String(localized: " - ") + ingredient.quantity + "\n"
                    }
                }
            }
            output += "\n"
        }

        // Steps
        if !recipe.sortedSteps.isEmpty {
            output += String(localized: "Steps") + "\n"

            for (index, step) in recipe.sortedSteps.enumerated() {
                output += "\(index + 1). " + step.value + "\n"
            }
        }

        return output
    }

    /// Imports a recipe from formatted text
    /// - Parameter text: The formatted text to parse
    /// - Returns: A Recipe object if parsing is successful, nil otherwise
    static func importRecipeFromText(_ text: String) -> Recipe? {
        let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }

        guard !lines.isEmpty else { return nil }

        // Get localized section headers
        let ingredientsHeader = String(localized: "Ingredients")
        let stepsHeader = String(localized: "Steps")

        // Extract recipe name (first non-empty line)
        guard let recipeName = lines.first(where: { !$0.isEmpty }) else { return nil }

        // Find section indices
        let ingredientsIndex = lines.firstIndex { $0 == ingredientsHeader }
        let stepsIndex = lines.firstIndex { $0 == stepsHeader }

        // Extract description (everything between recipe name and ingredients section)
        var description = ""
        if let ingredientsIdx = ingredientsIndex {
            let descLines = lines[1..<ingredientsIdx]
                .filter { !$0.isEmpty }
            description = descLines.joined(separator: "\n")
        } else if let stepsIdx = stepsIndex {
            let descLines = lines[1..<stepsIdx]
                .filter { !$0.isEmpty }
            description = descLines.joined(separator: "\n")
        }

        // Parse ingredients
        var ingredients: [Ingredient] = []
        var ingredientHeadings: [IngredientHeading] = []
        var ingredientSortOrder = 0

        if let startIdx = ingredientsIndex {
            let endIdx = stepsIndex ?? lines.count
            let ingredientLines = lines[(startIdx + 1)..<endIdx]

            for line in ingredientLines {
                guard !line.isEmpty else { continue }

                // Check if it's a heading (ends with ":")
                if line.hasSuffix(":") {
                    let headingName = String(line.dropLast())
                    let heading = IngredientHeading(name: headingName, sortOrder: ingredientSortOrder)
                    ingredientHeadings.append(heading)
                    ingredientSortOrder += 1
                }
                // Ingredient
                else {
                    // Try to split by " - " to separate name and quantity
                    if let xRange = line.range(of: String(localized: " - ")) {
                        let name = String(line[..<xRange.lowerBound])
                        let quantity = String(line[xRange.upperBound...])
                        let ingredient = Ingredient(name: name, quantity: quantity, sortOrder: ingredientSortOrder)
                        ingredients.append(ingredient)
                    } else {
                        // No quantity specified
                        let ingredient = Ingredient(name: line, quantity: "", sortOrder: ingredientSortOrder)
                        ingredients.append(ingredient)
                    }
                    ingredientSortOrder += 1
                }
            }
        }

        // Parse steps
        var steps: [Step] = []

        if let startIdx = stepsIndex {
            let stepLines = lines[(startIdx + 1)...]
            var stepSortOrder = 0

            for line in stepLines {
                guard !line.isEmpty else { continue }

                // Remove step number prefix if present (e.g., "1. ", "2. ")
                if let dotIndex = line.firstIndex(of: "."),
                   line.prefix(upTo: dotIndex).allSatisfy({ $0.isNumber || $0.isWhitespace }) {
                    let stepValue = String(line[line.index(after: dotIndex)...]).trimmingCharacters(in: .whitespaces)
                    let step = Step(value: stepValue, sortOrder: stepSortOrder)
                    steps.append(step)
                    stepSortOrder += 1
                } else {
                    // If no number prefix, add the whole line as a step
                    let step = Step(value: line, sortOrder: stepSortOrder)
                    steps.append(step)
                    stepSortOrder += 1
                }
            }
        }

        // Create and return the recipe
        return Recipe(
            name: recipeName,
            desc: description,
            ingredients: ingredients,
            ingredientHeadings: ingredientHeadings,
            steps: steps
        )
    }
}
