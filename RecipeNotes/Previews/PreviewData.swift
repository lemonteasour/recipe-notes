//
//  PreviewData.swift
//  RecipeNotes
//
//  Created by Jay Hui on 28/09/2025.
//


import SwiftData

@MainActor
enum PreviewData {

    static let sampleRecipe: Recipe = Recipe(
        name: "Oyakodon",
        desc: "Japanese chicken & egg rice bowl, for 2 people",
        ingredients: [
            Ingredient(name: "Chicken meat", quantity: "200g", index: 0),
            Ingredient(name: "Onion", quantity: "1/2", index: 1),
            Ingredient(name: "Egg", quantity: "3", index: 2),
            Ingredient(name: "Rice", quantity: "250g", index: 3),
            Ingredient(name: "Mentsuyu", quantity: "4tbsp", index: 5),
            Ingredient(name: "Water", quantity: "200ml", index: 6),
            Ingredient(name: "Potato starch", quantity: "Some", index: 7),
        ],
        ingredientHeadings: [
            IngredientHeading(name: "Condiments", index: 4)
        ],
        steps: [
            Step(value: "Cut chicken into bite-sized pieces. Slice onions to about 5 mm thickness.", index: 0),
            Step(value: "In a pan, add the listed condiments (except potato starch), then add chicken and onions.", index: 1),
            Step(value: "Simmer until the chicken is cooked through. Add potato starch (mixed with a little water) to thicken the sauce.", index: 2),
            Step(value: "Lightly beat the eggs (do not over-mix). Pour in half of the eggs and cook over medium-high heat until just set.", index: 3),
            Step(value: "Add the remaining eggs, turn off the heat, and cover. Let it rest for 10 minutes.", index: 4),
            Step(value: "Serve over rice.", index: 5)
        ]
    )


    /// Returns a ModelContainer with seeded sample data
    static func containerWithSamples() -> ModelContainer {
        do {
            let container = try ModelContainer(
                for: Recipe.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext

            // Seed if empty
            if try context.fetch(FetchDescriptor<Recipe>()).isEmpty {
                context.insert(sampleRecipe)
            }

            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }
}
