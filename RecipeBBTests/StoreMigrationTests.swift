//
//  StoreMigrationTests.swift
//  RecipeBBTests
//
//  Verifies that a store written by 0.6.0 (the last release before tags,
//  favorites and the PantryCategory delete-rule change) opens under the
//  current schema by lightweight migration, with no data loss and no
//  user action required.
//

import Testing
import Foundation
import SwiftData
@testable import RecipeBB

/// The 0.6.0 model graph, reproduced verbatim from commit fb6ad71 (the last
/// commit shipping MARKETING_VERSION 0.6.0). Nested in an enum so these types
/// don't collide with the current models; SwiftData derives entity names from
/// the simple class name, so the store these produce is byte-compatible with
/// what a real 0.6.0 install wrote.
enum SchemaV060 {

    @Model
    final class Recipe {
        @Attribute(.unique) var id: UUID
        var name: String
        var desc: String
        @Attribute(.externalStorage) var photo: Data?
        @Relationship(deleteRule: .cascade, inverse: \SchemaV060.Ingredient.recipe)
        var ingredients: [SchemaV060.Ingredient]
        @Relationship(deleteRule: .cascade, inverse: \SchemaV060.IngredientHeading.recipe)
        var ingredientHeadings: [SchemaV060.IngredientHeading]
        @Relationship(deleteRule: .cascade, inverse: \SchemaV060.Step.recipe)
        var steps: [SchemaV060.Step]
        var createdAt: Date

        init(name: String, desc: String, photo: Data? = nil) {
            self.id = UUID()
            self.name = name
            self.desc = desc
            self.photo = photo
            self.ingredients = []
            self.ingredientHeadings = []
            self.steps = []
            self.createdAt = Date()
        }
    }

    @Model
    final class Ingredient {
        @Attribute(.unique) var id: UUID
        var name: String
        var quantity: String
        @Attribute(originalName: "index") var sortOrder: Int
        var recipe: SchemaV060.Recipe?

        init(name: String, quantity: String, sortOrder: Int) {
            self.id = UUID()
            self.name = name
            self.quantity = quantity
            self.sortOrder = sortOrder
        }
    }

    @Model
    final class IngredientHeading {
        @Attribute(.unique) var id: UUID
        var name: String
        @Attribute(originalName: "index") var sortOrder: Int
        var recipe: SchemaV060.Recipe?

        init(name: String, sortOrder: Int) {
            self.id = UUID()
            self.name = name
            self.sortOrder = sortOrder
        }
    }

    @Model
    final class Step {
        @Attribute(.unique) var id: UUID
        var value: String
        @Attribute(originalName: "index") var sortOrder: Int
        var recipe: SchemaV060.Recipe?

        init(value: String, sortOrder: Int) {
            self.id = UUID()
            self.value = value
            self.sortOrder = sortOrder
        }
    }

    @Model
    final class PantryItem {
        @Attribute(.unique) var id: UUID
        var name: String
        var quantity: String
        var sortOrder: Int
        var category: SchemaV060.PantryCategory?

        init(name: String, quantity: String = "", sortOrder: Int, category: SchemaV060.PantryCategory? = nil) {
            self.id = UUID()
            self.name = name
            self.quantity = quantity
            self.sortOrder = sortOrder
            self.category = category
        }
    }

    @Model
    final class PantryCategory {
        @Attribute(.unique) var id: UUID
        var name: String
        var sortOrder: Int

        // 0.6.0 shipped .cascade here; 0.7.0 changed it to .nullify
        @Relationship(deleteRule: .cascade, inverse: \SchemaV060.PantryItem.category)
        var items: [SchemaV060.PantryItem]?

        init(name: String, sortOrder: Int = 0) {
            self.id = UUID()
            self.name = name
            self.sortOrder = sortOrder
        }
    }

    static let models: [any PersistentModel.Type] = [
        Recipe.self, Ingredient.self, IngredientHeading.self,
        Step.self, PantryItem.self, PantryCategory.self,
    ]
}

/// The 0.5.2 model graph (commit 9ca1474, when the app was still "RecipeNotes").
/// Only the parts that differ from 0.6.0 matter: `Recipe` has no `photo`, and
/// `PantryCategory` still has the `createdAt` that 0.6.0 dropped. A user who
/// skipped 0.6.0 entirely migrates straight from here to the current schema,
/// which is a different hop than the 0.6.0 one.
enum SchemaV052 {

    @Model
    final class Recipe {
        @Attribute(.unique) var id: UUID
        var name: String
        var desc: String
        @Relationship(deleteRule: .cascade, inverse: \SchemaV052.Ingredient.recipe)
        var ingredients: [SchemaV052.Ingredient]
        @Relationship(deleteRule: .cascade, inverse: \SchemaV052.IngredientHeading.recipe)
        var ingredientHeadings: [SchemaV052.IngredientHeading]
        @Relationship(deleteRule: .cascade, inverse: \SchemaV052.Step.recipe)
        var steps: [SchemaV052.Step]
        var createdAt: Date

        init(name: String, desc: String) {
            self.id = UUID()
            self.name = name
            self.desc = desc
            self.ingredients = []
            self.ingredientHeadings = []
            self.steps = []
            self.createdAt = Date()
        }
    }

    @Model
    final class Ingredient {
        @Attribute(.unique) var id: UUID
        var name: String
        var quantity: String
        @Attribute(originalName: "index") var sortOrder: Int
        var recipe: SchemaV052.Recipe?

        init(name: String, quantity: String, sortOrder: Int) {
            self.id = UUID()
            self.name = name
            self.quantity = quantity
            self.sortOrder = sortOrder
        }
    }

    @Model
    final class IngredientHeading {
        @Attribute(.unique) var id: UUID
        var name: String
        @Attribute(originalName: "index") var sortOrder: Int
        var recipe: SchemaV052.Recipe?

        init(name: String, sortOrder: Int) {
            self.id = UUID()
            self.name = name
            self.sortOrder = sortOrder
        }
    }

    @Model
    final class Step {
        @Attribute(.unique) var id: UUID
        var value: String
        @Attribute(originalName: "index") var sortOrder: Int
        var recipe: SchemaV052.Recipe?

        init(value: String, sortOrder: Int) {
            self.id = UUID()
            self.value = value
            self.sortOrder = sortOrder
        }
    }

    @Model
    final class PantryItem {
        @Attribute(.unique) var id: UUID
        var name: String
        var quantity: String
        var sortOrder: Int
        var category: SchemaV052.PantryCategory?

        init(name: String, quantity: String = "", sortOrder: Int, category: SchemaV052.PantryCategory? = nil) {
            self.id = UUID()
            self.name = name
            self.quantity = quantity
            self.sortOrder = sortOrder
            self.category = category
        }
    }

    @Model
    final class PantryCategory {
        @Attribute(.unique) var id: UUID
        var name: String
        var sortOrder: Int
        var createdAt: Date

        @Relationship(deleteRule: .cascade, inverse: \SchemaV052.PantryItem.category)
        var items: [SchemaV052.PantryItem]?

        init(name: String, sortOrder: Int = 0) {
            self.id = UUID()
            self.name = name
            self.sortOrder = sortOrder
            self.createdAt = Date()
        }
    }

    static let models: [any PersistentModel.Type] = [
        Recipe.self, Ingredient.self, IngredientHeading.self,
        Step.self, PantryItem.self, PantryCategory.self,
    ]
}

@MainActor
struct StoreMigrationTests {

    /// A fresh on-disk store URL. On-disk (not in-memory) so `.externalStorage`
    /// photos and the real migration path behave as they do on device.
    private func makeStoreURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("Migration060-\(UUID().uuidString).store")
    }

    /// Writes a realistic 0.6.0 store: a recipe with an externally-stored photo,
    /// ingredients, a heading and steps, plus a pantry category holding items.
    private func seedV060Store(at url: URL) throws {
        let container = try ModelContainer(
            for: Schema(SchemaV060.models),
            configurations: ModelConfiguration(url: url)
        )
        let context = container.mainContext

        let recipe = SchemaV060.Recipe(
            name: "Carbonara",
            desc: "From 0.6.0",
            photo: Data(repeating: 0xAB, count: 2_000_000)
        )
        context.insert(recipe)
        recipe.ingredients = [
            SchemaV060.Ingredient(name: "Guanciale", quantity: "150g", sortOrder: 1),
            SchemaV060.Ingredient(name: "Pecorino", quantity: "50g", sortOrder: 2),
        ]
        recipe.ingredientHeadings = [SchemaV060.IngredientHeading(name: "Sauce", sortOrder: 0)]
        recipe.steps = [
            SchemaV060.Step(value: "Render the guanciale", sortOrder: 0),
            SchemaV060.Step(value: "Toss off the heat", sortOrder: 1),
        ]

        let second = SchemaV060.Recipe(name: "Toast", desc: "Simple")
        context.insert(second)

        let category = SchemaV060.PantryCategory(name: "Dairy", sortOrder: 0)
        context.insert(category)
        context.insert(SchemaV060.PantryItem(name: "Butter", quantity: "1", sortOrder: 0, category: category))
        context.insert(SchemaV060.PantryItem(name: "Milk", quantity: "2", sortOrder: 1, category: category))
        context.insert(SchemaV060.PantryItem(name: "Loose Item", quantity: "1", sortOrder: 2))

        try context.save()
    }

    /// The core question: does a populated 0.6.0 store open under the current
    /// schema without throwing, and with every record intact?
    @Test func v060StoreOpensUnderCurrentSchemaWithDataIntact() throws {
        let url = makeStoreURL()
        try seedV060Store(at: url)

        // Reopen the same file with the shipping model list — exactly what
        // RecipeBBApp does at launch after the user updates.
        let container = try ModelContainer(
            for: Recipe.self, RecipeTag.self, PantryItem.self, PantryCategory.self,
            configurations: ModelConfiguration(url: url)
        )
        let context = container.mainContext

        let recipes = try context.fetch(FetchDescriptor<Recipe>())
        #expect(recipes.count == 2)

        let carbonara = try #require(recipes.first { $0.name == "Carbonara" })
        #expect(carbonara.desc == "From 0.6.0")
        #expect(carbonara.photo?.count == 2_000_000)
        #expect(carbonara.ingredients.count == 2)
        #expect(carbonara.ingredientHeadings.count == 1)
        #expect(carbonara.steps.count == 2)
        #expect(carbonara.sortedIngredientItems.map(\.name) == ["Sauce", "Guanciale", "Pecorino"])
        #expect(carbonara.sortedSteps.map(\.value) == ["Render the guanciale", "Toss off the heat"])

        // New properties must arrive at their defaults, not as a migration failure
        #expect(carbonara.tags.isEmpty)
        #expect(carbonara.isFavorite == false)

        // Pantry survives, including the item that had no category
        let items = try context.fetch(FetchDescriptor<PantryItem>())
        #expect(items.count == 3)
        let categories = try context.fetch(FetchDescriptor<PantryCategory>())
        #expect(categories.count == 1)
        #expect(categories.first?.items?.count == 2)
        #expect(items.first { $0.name == "Loose Item" }?.category == nil)

        // The brand-new entity is usable straight after migration
        #expect(try context.fetch(FetchDescriptor<RecipeTag>()).isEmpty)
    }

    /// A migrated store must support the 0.7.x features end to end — tagging a
    /// pre-existing recipe writes to a relationship that didn't exist in 0.6.0.
    @Test func migratedStoreAcceptsTagsAndFavorites() throws {
        let url = makeStoreURL()
        try seedV060Store(at: url)

        let container = try ModelContainer(
            for: Recipe.self, RecipeTag.self, PantryItem.self, PantryCategory.self,
            configurations: ModelConfiguration(url: url)
        )
        let context = container.mainContext

        let recipe = try #require(try context.fetch(FetchDescriptor<Recipe>()).first { $0.name == "Carbonara" })
        let tag = RecipeTag(name: "Pasta")
        context.insert(tag)
        recipe.tags = [tag]
        recipe.isFavorite = true
        try context.save()

        let viewModel = RecipeListViewModel(context: context)
        let all = try context.fetch(FetchDescriptor<Recipe>())
        #expect(!viewModel.sections(from: all).isEmpty)

        // And deleting that tag leaves the migrated recipe readable
        try viewModel.deleteTag(tag)
        #expect(recipe.sortedTags.isEmpty)
        #expect(!viewModel.sections(from: try context.fetch(FetchDescriptor<Recipe>())).isEmpty)
    }

    /// Anyone who skipped 0.6.0 jumps two schema versions at once: they gain
    /// `Recipe.photo` *and* lose `PantryCategory.createdAt` in the same hop as
    /// the tags/favorites additions.
    @Test func v052StoreOpensUnderCurrentSchemaWithDataIntact() throws {
        let url = makeStoreURL()

        // Seed a 0.5.2-shaped store
        do {
            let container = try ModelContainer(
                for: Schema(SchemaV052.models),
                configurations: ModelConfiguration(url: url)
            )
            let context = container.mainContext

            let recipe = SchemaV052.Recipe(name: "Old Recipe", desc: "From 0.5.2")
            context.insert(recipe)
            recipe.ingredients = [SchemaV052.Ingredient(name: "Flour", quantity: "200g", sortOrder: 0)]
            recipe.steps = [SchemaV052.Step(value: "Mix", sortOrder: 0)]

            let category = SchemaV052.PantryCategory(name: "Baking", sortOrder: 0)
            context.insert(category)
            context.insert(SchemaV052.PantryItem(name: "Yeast", quantity: "1", sortOrder: 0, category: category))

            try context.save()
        }

        let container = try ModelContainer(
            for: Recipe.self, RecipeTag.self, PantryItem.self, PantryCategory.self,
            configurations: ModelConfiguration(url: url)
        )
        let context = container.mainContext

        let recipe = try #require(try context.fetch(FetchDescriptor<Recipe>()).first)
        #expect(recipe.name == "Old Recipe")
        #expect(recipe.ingredients.count == 1)
        #expect(recipe.steps.count == 1)
        // Gained in 0.6.0, so it must arrive nil rather than failing to migrate
        #expect(recipe.photo == nil)
        #expect(recipe.tags.isEmpty)
        #expect(recipe.isFavorite == false)

        #expect(try context.fetch(FetchDescriptor<PantryItem>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<PantryCategory>()).first?.items?.count == 1)
    }

    /// The delete-rule change (.cascade -> .nullify) is the one edit made
    /// without a migration, on the assumption it isn't part of the schema
    /// version hash. If that assumption is wrong the reopen above throws;
    /// this pins the resulting *behavior* on a migrated store.
    @Test func deletingCategoryOnMigratedStoreOrphansItemsRatherThanDeletingThem() throws {
        let url = makeStoreURL()
        try seedV060Store(at: url)

        let container = try ModelContainer(
            for: Recipe.self, RecipeTag.self, PantryItem.self, PantryCategory.self,
            configurations: ModelConfiguration(url: url)
        )
        let context = container.mainContext

        let category = try #require(try context.fetch(FetchDescriptor<PantryCategory>()).first)
        context.delete(category)
        try context.save()

        // 0.6.0's .cascade would have taken Butter and Milk with it
        let items = try context.fetch(FetchDescriptor<PantryItem>())
        #expect(items.count == 3)
        #expect(items.allSatisfy { $0.category == nil })
    }
}
