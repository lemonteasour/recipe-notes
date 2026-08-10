//
//  StoreMigrationTests.swift
//  RecipeBBTests
//
//  Verifies that a store written by any shipped release — 0.5.2, 0.6.0, or
//  0.7.2, each reproduced verbatim below — opens under the current schema by
//  lightweight migration, with no data loss and no user action required.
//
//  0.7.2 is the one on real devices today, so it is the migration that has to
//  hold when the CloudKit-shaped schema ships.
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

/// The 0.7.2 model graph (commit b5ad315, the last *released* version). This is
/// the schema on every real device today, and the one the CloudKit-compatible
/// schema has to migrate away from: 0.8.0 drops the `.unique` id constraints,
/// gives every non-optional attribute a default, and makes the to-many
/// relationships optional, because NSPersistentCloudKitContainer rejects all
/// three. None of that is supposed to alter stored data — this schema exists so
/// the tests can prove it on a populated store rather than assume it.
enum SchemaV072 {

    @Model
    final class Recipe {
        @Attribute(.unique) var id: UUID
        var name: String
        var desc: String
        @Attribute(.externalStorage) var photo: Data?
        @Relationship(deleteRule: .cascade, inverse: \SchemaV072.Ingredient.recipe)
        var ingredients: [SchemaV072.Ingredient]
        @Relationship(deleteRule: .cascade, inverse: \SchemaV072.IngredientHeading.recipe)
        var ingredientHeadings: [SchemaV072.IngredientHeading]
        @Relationship(deleteRule: .cascade, inverse: \SchemaV072.Step.recipe)
        var steps: [SchemaV072.Step]
        @Relationship(deleteRule: .nullify, inverse: \SchemaV072.RecipeTag.recipes)
        var tags: [SchemaV072.RecipeTag] = []
        var isFavorite: Bool = false
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
    final class RecipeTag {
        @Attribute(.unique) var id: UUID
        var name: String
        var createdAt: Date
        var recipes: [SchemaV072.Recipe]?

        init(name: String) {
            self.id = UUID()
            self.name = name
            self.createdAt = Date()
        }
    }

    @Model
    final class Ingredient {
        @Attribute(.unique) var id: UUID
        var name: String
        var quantity: String
        @Attribute(originalName: "index") var sortOrder: Int
        var recipe: SchemaV072.Recipe?

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
        var recipe: SchemaV072.Recipe?

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
        var recipe: SchemaV072.Recipe?

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
        var category: SchemaV072.PantryCategory?

        init(name: String, quantity: String = "", sortOrder: Int, category: SchemaV072.PantryCategory? = nil) {
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

        @Relationship(deleteRule: .nullify, inverse: \SchemaV072.PantryItem.category)
        var items: [SchemaV072.PantryItem]?

        init(name: String, sortOrder: Int = 0) {
            self.id = UUID()
            self.name = name
            self.sortOrder = sortOrder
        }
    }

    static let models: [any PersistentModel.Type] = [
        Recipe.self, RecipeTag.self, Ingredient.self, IngredientHeading.self,
        Step.self, PantryItem.self, PantryCategory.self,
    ]
}

@MainActor
struct StoreMigrationTests {

    /// A fresh on-disk store URL. On-disk (not in-memory) so `.externalStorage`
    /// photos and the real migration path behave as they do on device.
    private func makeStoreURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("StoreMigration-\(UUID().uuidString).store")
    }

    /// A fixed creation date on the seeded 0.7.2 recipe. `createdAt` is the
    /// only attribute that both gained a default in the CloudKit schema and
    /// drives what the user sees — it sorts the recipe list and cuts its month
    /// sections — so a migration that reset it to the default would silently
    /// stack every recipe under today.
    private static let v072CreatedAt = Date(timeIntervalSince1970: 1_700_000_000)

    /// Writes a realistic 0.7.2 store — the shape currently on real devices —
    /// exercising every feature that shipped: an externally-stored photo,
    /// ingredients, a heading, steps, shared tags, a favorite, and a pantry
    /// category holding items alongside an uncategorized one.
    /// Returns the ids it wrote so the reopen can prove identity survived.
    @discardableResult
    private func seedV072Store(at url: URL) throws -> (recipe: UUID, ingredients: [UUID], tag: UUID) {
        let container = try ModelContainer(
            for: Schema(SchemaV072.models),
            configurations: ModelConfiguration(url: url)
        )
        let context = container.mainContext

        let recipe = SchemaV072.Recipe(
            name: "Carbonara",
            desc: "From 0.7.2",
            photo: Data(repeating: 0xAB, count: 2_000_000)
        )
        context.insert(recipe)
        recipe.ingredients = [
            SchemaV072.Ingredient(name: "Guanciale", quantity: "150g", sortOrder: 1),
            SchemaV072.Ingredient(name: "Pecorino", quantity: "50g", sortOrder: 2),
        ]
        recipe.ingredientHeadings = [SchemaV072.IngredientHeading(name: "Sauce", sortOrder: 0)]
        recipe.steps = [
            SchemaV072.Step(value: "Render the guanciale", sortOrder: 0),
            SchemaV072.Step(value: "Toss off the heat", sortOrder: 1),
        ]
        recipe.isFavorite = true
        recipe.createdAt = Self.v072CreatedAt

        // A tag shared by two recipes, so the many-to-many is populated on both sides
        let pasta = SchemaV072.RecipeTag(name: "Pasta")
        context.insert(pasta)
        let second = SchemaV072.Recipe(name: "Cacio e Pepe", desc: "Also pasta")
        context.insert(second)
        recipe.tags = [pasta]
        second.tags = [pasta]

        let category = SchemaV072.PantryCategory(name: "Dairy", sortOrder: 0)
        context.insert(category)
        context.insert(SchemaV072.PantryItem(name: "Butter", quantity: "1", sortOrder: 0, category: category))
        context.insert(SchemaV072.PantryItem(name: "Milk", quantity: "2", sortOrder: 1, category: category))
        context.insert(SchemaV072.PantryItem(name: "Loose Item", quantity: "1", sortOrder: 2))

        try context.save()

        return (
            recipe: recipe.id,
            ingredients: recipe.ingredients.sorted { $0.sortOrder < $1.sortOrder }.map(\.id),
            tag: pasta.id
        )
    }

    /// The headline question for the CloudKit work: does a populated store
    /// written by the shipping release open under the CloudKit-compatible
    /// schema — `.unique` dropped, defaults added, to-many made optional —
    /// with every record intact and no user action required?
    @Test func v072StoreOpensUnderCloudKitSchemaWithDataIntact() throws {
        let url = makeStoreURL()
        let seeded = try seedV072Store(at: url)

        let container = try ModelContainer(
            for: Recipe.self, RecipeTag.self, PantryItem.self, PantryCategory.self,
            configurations: ModelConfiguration(url: url)
        )
        let context = container.mainContext

        let recipes = try context.fetch(FetchDescriptor<Recipe>())
        #expect(recipes.count == 2)

        let carbonara = try #require(recipes.first { $0.name == "Carbonara" })
        #expect(carbonara.desc == "From 0.7.2")
        #expect(carbonara.photo?.count == 2_000_000)
        #expect(carbonara.isFavorite == true)
        // Not the schema default — see `v072CreatedAt`
        #expect(carbonara.createdAt == Self.v072CreatedAt)

        // Relationships survive becoming optional — nil here would mean the
        // migration silently detached the children rather than carrying them.
        #expect(carbonara.ingredients != nil)
        #expect(carbonara.ingredientList.count == 2)
        #expect(carbonara.headingList.count == 1)
        #expect(carbonara.stepList.count == 2)
        #expect(carbonara.sortedIngredientItems.map(\.name) == ["Sauce", "Guanciale", "Pecorino"])
        #expect(carbonara.sortedSteps.map(\.value) == ["Render the guanciale", "Toss off the heat"])

        // Identity survives dropping the uniqueness constraint. The edit flow
        // reconciles children by id, so a reissued id would orphan every child
        // on the first save after updating.
        #expect(carbonara.id == seeded.recipe)
        #expect(carbonara.ingredientList.sorted { $0.sortOrder < $1.sortOrder }.map(\.id) == seeded.ingredients)

        // The shared tag stays shared rather than being split per recipe
        let tags = try context.fetch(FetchDescriptor<RecipeTag>())
        #expect(tags.count == 1)
        let pasta = try #require(tags.first)
        #expect(pasta.id == seeded.tag)
        #expect(pasta.recipeList.count == 2)
        #expect(carbonara.tagList.count == 1)

        let items = try context.fetch(FetchDescriptor<PantryItem>())
        #expect(items.count == 3)
        let categories = try context.fetch(FetchDescriptor<PantryCategory>())
        #expect(categories.first?.itemList.count == 2)
        #expect(items.first { $0.name == "Loose Item" }?.category == nil)
    }

    /// Migrating must leave the store writable, not just readable — the new
    /// defaults and optional relationships have to accept a normal edit.
    @Test func v072MigratedStoreAcceptsEdits() throws {
        let url = makeStoreURL()
        try seedV072Store(at: url)

        let container = try ModelContainer(
            for: Recipe.self, RecipeTag.self, PantryItem.self, PantryCategory.self,
            configurations: ModelConfiguration(url: url)
        )
        let context = container.mainContext

        let recipe = try #require(try context.fetch(FetchDescriptor<Recipe>()).first { $0.name == "Carbonara" })

        // Edit through the real form view model, the way the app does
        let form = RecipeFormViewModel(context: context, recipeToEdit: recipe)
        form.name = "Carbonara (updated)"
        form.addIngredient()
        form.ingredientItems[form.ingredientItems.count - 1].name = "Egg yolk"
        form.ingredientItems[form.ingredientItems.count - 1].quantity = "4"
        form.addStep()
        form.steps[form.steps.count - 1].value = "Serve"
        try form.saveRecipe()

        #expect(recipe.name == "Carbonara (updated)")
        #expect(recipe.ingredientList.count == 3)
        #expect(recipe.stepList.count == 3)
        #expect(recipe.ingredientList.contains { $0.name == "Egg yolk" })

        // Saving overwrites `tags` wholesale, so tags the migration failed to
        // carry would be destroyed by the first edit rather than just hidden.
        #expect(recipe.tagList.map(\.name) == ["Pasta"])

        // And a brand-new recipe still works on the migrated store
        let fresh = Recipe(name: "New", desc: "")
        context.insert(fresh)
        fresh.ingredients = [Ingredient(name: "Salt", quantity: "1tsp", sortOrder: 0)]
        try context.save()
        #expect(try context.fetch(FetchDescriptor<Recipe>()).count == 3)
    }

    /// A recipe created fresh on the migrated schema must get its own id, not
    /// the model's default value. `id` needs a default to satisfy CloudKit, and
    /// a default that stuck would collapse every new object onto one id.
    @Test func newObjectsOnCloudKitSchemaGetDistinctIDs() throws {
        let url = makeStoreURL()
        try seedV072Store(at: url)

        let container = try ModelContainer(
            for: Recipe.self, RecipeTag.self, PantryItem.self, PantryCategory.self,
            configurations: ModelConfiguration(url: url)
        )
        let context = container.mainContext

        for index in 0..<5 {
            context.insert(Recipe(name: "Recipe \(index)", desc: ""))
            context.insert(RecipeTag(name: "Tag \(index)"))
            context.insert(PantryItem(name: "Item \(index)", sortOrder: index))
        }
        try context.save()

        let recipeIDs = try context.fetch(FetchDescriptor<Recipe>()).map(\.id)
        #expect(Set(recipeIDs).count == recipeIDs.count)
        let tagIDs = try context.fetch(FetchDescriptor<RecipeTag>()).map(\.id)
        #expect(Set(tagIDs).count == tagIDs.count)
        let itemIDs = try context.fetch(FetchDescriptor<PantryItem>()).map(\.id)
        #expect(Set(itemIDs).count == itemIDs.count)
    }

    /// Cascade delete has to keep working once the relationship is optional —
    /// if it silently stopped, orphaned children would accumulate forever and
    /// then sync themselves to every device.
    @Test func deletingRecipeOnMigratedStoreStillCascadesToChildren() throws {
        let url = makeStoreURL()
        try seedV072Store(at: url)

        let container = try ModelContainer(
            for: Recipe.self, RecipeTag.self, PantryItem.self, PantryCategory.self,
            configurations: ModelConfiguration(url: url)
        )
        let context = container.mainContext

        let carbonara = try #require(try context.fetch(FetchDescriptor<Recipe>()).first { $0.name == "Carbonara" })
        context.delete(carbonara)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<Ingredient>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<IngredientHeading>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<Step>()).isEmpty)
        // The shared tag is nullified, not deleted, and its other recipe survives
        #expect(try context.fetch(FetchDescriptor<RecipeTag>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<Recipe>()).count == 1)
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
        #expect(carbonara.ingredientList.count == 2)
        #expect(carbonara.headingList.count == 1)
        #expect(carbonara.stepList.count == 2)
        #expect(carbonara.sortedIngredientItems.map(\.name) == ["Sauce", "Guanciale", "Pecorino"])
        #expect(carbonara.sortedSteps.map(\.value) == ["Render the guanciale", "Toss off the heat"])

        // New properties must arrive at their defaults, not as a migration failure
        #expect(carbonara.tagList.isEmpty)
        #expect(carbonara.isFavorite == false)

        // Pantry survives, including the item that had no category
        let items = try context.fetch(FetchDescriptor<PantryItem>())
        #expect(items.count == 3)
        let categories = try context.fetch(FetchDescriptor<PantryCategory>())
        #expect(categories.count == 1)
        #expect(categories.first?.itemList.count == 2)
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
        #expect(recipe.ingredientList.count == 1)
        #expect(recipe.stepList.count == 1)
        // Gained in 0.6.0, so it must arrive nil rather than failing to migrate
        #expect(recipe.photo == nil)
        #expect(recipe.tagList.isEmpty)
        #expect(recipe.isFavorite == false)

        #expect(try context.fetch(FetchDescriptor<PantryItem>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<PantryCategory>()).first?.itemList.count == 1)
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
