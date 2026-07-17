//
//  WipeAndReseedTests.swift
//  RecipeBBTests
//
//  Reproduces the device crash when resetting to sample data while the
//  store holds real user data (photos in external storage, tags, pantry).
//

import Testing
import Foundation
import SwiftData
@testable import RecipeBB

@MainActor
struct WipeAndReseedTests {

    /// On-disk container so `.externalStorage` attributes behave like on device
    private func makeContainer() throws -> ModelContainer {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("WipeAndReseedTests-\(UUID().uuidString).store")
        return try ModelContainer(
            for: Recipe.self, RecipeTag.self, PantryItem.self, PantryCategory.self,
            configurations: ModelConfiguration(url: url)
        )
    }

    @Test func wipeAndReseedWithPhotoTagsAndPantry() throws {
        let container = try makeContainer()
        let context = container.mainContext

        // Recipe with a photo big enough to be stored externally
        let recipe = Recipe(
            name: "User Recipe",
            desc: "Has a photo",
            photo: Data(repeating: 0xAB, count: 2_000_000),
            ingredients: [Ingredient(name: "Thing", quantity: "1", sortOrder: 0)],
            ingredientHeadings: [IngredientHeading(name: "Heading", sortOrder: 1)],
            steps: [Step(value: "Do it", sortOrder: 0)]
        )
        context.insert(recipe)
        let tag = RecipeTag(name: "Mine")
        context.insert(tag)
        recipe.tags = [tag]
        recipe.isFavorite = true

        let category = PantryCategory(name: "Stuff", sortOrder: 0)
        context.insert(category)
        context.insert(PantryItem(name: "Item", quantity: "1", sortOrder: 0, category: category))
        try context.save()

        PreviewData.wipeAndReseed(context: context)

        // Old data gone, sample data in
        let recipes = try context.fetch(FetchDescriptor<Recipe>())
        #expect(!recipes.contains { $0.name == "User Recipe" })
        #expect(recipes.count > 1)
        #expect(try context.fetch(FetchDescriptor<PantryItem>()).count > 1)
    }

    @Test func wipeAndReseedTwiceInARow() throws {
        let container = try makeContainer()
        let context = container.mainContext

        PreviewData.wipeAndReseed(context: context)
        PreviewData.wipeAndReseed(context: context)

        #expect(try context.fetch(FetchDescriptor<Recipe>()).count > 1)
    }
}
