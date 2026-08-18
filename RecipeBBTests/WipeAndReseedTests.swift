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
            for: Recipe.self, RecipeTag.self, PantryItem.self, PantryCategory.self, MealPlanEntry.self,
            configurations: ModelConfiguration(url: url, cloudKitDatabase: .none)
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

        SeedDataService.wipeAndReseed(context: context)

        // Old data gone, sample data in
        let recipes = try context.fetch(FetchDescriptor<Recipe>())
        #expect(!recipes.contains { $0.name == "User Recipe" })
        #expect(recipes.count > 1)
        #expect(try context.fetch(FetchDescriptor<PantryItem>()).count > 1)
    }

    @Test func wipeAndReseedTwiceInARow() throws {
        let container = try makeContainer()
        let context = container.mainContext

        SeedDataService.wipeAndReseed(context: context)
        SeedDataService.wipeAndReseed(context: context)

        #expect(try context.fetch(FetchDescriptor<Recipe>()).count > 1)
        #expect(try context.fetch(FetchDescriptor<MealPlanEntry>()).count > 1)
    }

    /// Planner entries have to be deleted explicitly, not left to the delete
    /// rule: deleting a recipe only *nullifies* them, so they would otherwise
    /// survive the wipe as orphans — and the non-zero count would then make
    /// `seedIfEmpty` skip reseeding them entirely.
    @Test func wipeAndReseedClearsPlannerEntriesIncludingUnlinkedOnes() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let recipe = Recipe(name: "User Recipe", desc: "")
        context.insert(recipe)
        context.insert(MealPlanEntry(dayKey: 20260811, title: "", slot: .dinner, recipe: recipe))
        // A free-text entry has no recipe to be deleted along with
        context.insert(MealPlanEntry(dayKey: 20260811, title: "User Takeout", slot: .lunch))
        try context.save()

        SeedDataService.wipeAndReseed(context: context)

        let entries = try context.fetch(FetchDescriptor<MealPlanEntry>())
        #expect(!entries.contains { $0.title == "User Takeout" })
        #expect(!entries.contains { $0.recipe == nil && $0.title.isEmpty })
        // Reseeding actually happened rather than being skipped
        #expect(entries.count > 1)
        #expect(entries.contains { $0.recipe != nil }, "sample entries should link to sample recipes")
    }
}
