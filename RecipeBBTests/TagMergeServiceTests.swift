//
//  TagMergeServiceTests.swift
//  RecipeBBTests
//
//  The duplicate tags sync creates are semantic, not keyed: two offline devices
//  each adding "Pasta" write two rows with two perfectly valid UUIDs, so no
//  store constraint would have caught them even if CloudKit allowed one.
//  These pin the repair — and, just as importantly, that both devices repair it
//  the same way, since each runs the pass over its own copy of the merge.
//

import Testing
import Foundation
import SwiftData
@testable import RecipeBB

@MainActor
struct TagMergeServiceTests {

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Recipe.self, RecipeTag.self, PantryItem.self, PantryCategory.self, MealPlanEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        )
    }

    /// `createdAt` decides which tag survives, so tests set it explicitly rather
    /// than racing the clock.
    @discardableResult
    private func insertTag(_ name: String, secondsAgo: TimeInterval, in context: ModelContext) -> RecipeTag {
        let tag = RecipeTag(name: name)
        tag.createdAt = Date(timeIntervalSince1970: 1_700_000_000 - secondsAgo)
        context.insert(tag)
        return tag
    }

    @discardableResult
    private func insertRecipe(_ name: String, tags: [RecipeTag], in context: ModelContext) -> Recipe {
        let recipe = Recipe(name: name, desc: "")
        context.insert(recipe)
        recipe.tags = tags
        return recipe
    }

    /// The case the user actually sees: the same chip twice in the filter sheet,
    /// with their recipes split across the two.
    @Test func mergesTagsThatDifferOnlyByCaseAndRepointsTheirRecipes() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let older = insertTag("Pasta", secondsAgo: 100, in: context)
        let newer = insertTag("pasta", secondsAgo: 0, in: context)
        let fromThisDevice = insertRecipe("Carbonara", tags: [older], in: context)
        let fromTheOtherDevice = insertRecipe("Amatriciana", tags: [newer], in: context)
        try context.save()

        let deleted = TagMergeService.mergeDuplicates(in: context)

        #expect(deleted == 1)
        let remaining = try context.fetch(FetchDescriptor<RecipeTag>())
        #expect(remaining.count == 1)
        #expect(remaining.first?.name == "Pasta", "the older tag survives, and keeps its own spelling")
        #expect(fromThisDevice.sortedTags.map(\.name) == ["Pasta"])
        #expect(fromTheOtherDevice.sortedTags.map(\.name) == ["Pasta"])
    }

    /// The merge unlinks by hand rather than trusting the `.nullify` rule to
    /// have run by the next render — a stale entry in `Recipe.tags` is a
    /// destroyed object, and reading its name traps.
    @Test func mergedRecipesHoldNoDeletedTags() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let older = insertTag("Pasta", secondsAgo: 100, in: context)
        let newer = insertTag("PASTA", secondsAgo: 0, in: context)
        let recipe = insertRecipe("Carbonara", tags: [older], in: context)
        try context.save()

        TagMergeService.mergeDuplicates(in: context)

        let holdsOnlyLiveTags = recipe.tagList.allSatisfy(\.isLive)
        #expect(holdsOnlyLiveTags)
        // `isLive`, not `isDeleted`: once the delete is saved the object is
        // detached rather than flagged, which is the whole reason the app has
        // the helper.
        #expect(!newer.isLive)
    }

    /// A recipe that carried both spellings ends up with one tag, not two
    /// entries pointing at the same survivor.
    @Test func aRecipeCarryingBothDuplicatesEndsWithOneTag() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let older = insertTag("Pasta", secondsAgo: 100, in: context)
        let newer = insertTag("pasta", secondsAgo: 0, in: context)
        let recipe = insertRecipe("Carbonara", tags: [older, newer], in: context)
        try context.save()

        TagMergeService.mergeDuplicates(in: context)

        #expect(recipe.tagList.count == 1)
        #expect(recipe.sortedTags.map(\.name) == ["Pasta"])
    }

    /// Accents and stray whitespace are matched the same way `addTag` matches
    /// them, so the merge never reunites less than the form already would.
    @Test func mergesAcrossAccentsAndSurroundingWhitespace() throws {
        let container = try makeContainer()
        let context = container.mainContext

        insertTag("Café", secondsAgo: 100, in: context)
        insertTag(" cafe ", secondsAgo: 0, in: context)
        try context.save()

        #expect(TagMergeService.mergeDuplicates(in: context) == 1)
        let remaining = try context.fetch(FetchDescriptor<RecipeTag>())
        #expect(remaining.map(\.name) == ["Café"])
    }

    /// The pass runs after every import, so leaving distinct tags — and their
    /// recipes — untouched is the common case, not an edge one.
    @Test func leavesDistinctTagsAlone() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let pasta = insertTag("Pasta", secondsAgo: 100, in: context)
        let pastry = insertTag("Pastry", secondsAgo: 50, in: context)
        let recipe = insertRecipe("Carbonara", tags: [pasta, pastry], in: context)
        try context.save()

        #expect(TagMergeService.mergeDuplicates(in: context) == 0)
        let remaining = try context.fetch(FetchDescriptor<RecipeTag>())
        #expect(remaining.count == 2)
        #expect(recipe.tagList.count == 2)
    }

    /// Both devices run this pass over their own copy of the merge. If they
    /// disagreed about which row to keep, each would delete the other's and the
    /// tag would vanish — so identical timestamps have to break to the same
    /// side everywhere.
    @Test func identicalTimestampsBreakTowardsTheLowerID() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let first = insertTag("Pasta", secondsAgo: 0, in: context)
        let second = insertTag("pasta", secondsAgo: 0, in: context)
        try context.save()

        // Read before the merge: the loser is destroyed by then.
        let expectedSurvivor = min(first.id.uuidString, second.id.uuidString)

        TagMergeService.mergeDuplicates(in: context)

        let remaining = try context.fetch(FetchDescriptor<RecipeTag>())
        #expect(remaining.map { $0.id.uuidString } == [expectedSurvivor])
    }

    /// Three copies of the same tag collapse in one pass, not one per run.
    @Test func collapsesMoreThanTwoCopiesInASinglePass() throws {
        let container = try makeContainer()
        let context = container.mainContext

        insertTag("Pasta", secondsAgo: 100, in: context)
        insertTag("pasta", secondsAgo: 50, in: context)
        insertTag("PASTA", secondsAgo: 0, in: context)
        try context.save()

        #expect(TagMergeService.mergeDuplicates(in: context) == 2)
        let remaining = try context.fetch(FetchDescriptor<RecipeTag>())
        #expect(remaining.count == 1)
        // Idempotent: the next import's pass finds nothing left to do.
        #expect(TagMergeService.mergeDuplicates(in: context) == 0)
    }
}
