//
//  RecipeFormViewModelTests.swift
//  RecipeBBTests
//
//  Saving a recipe renormalizes the sortOrder index spaces. Under sync, two
//  devices reordering the same recipe offline merge field-by-field and can land
//  on duplicate sortOrders; the tie-breaks in `sortedByOrder()` and
//  `mergedIngredientItems` keep the list from reshuffling between renders, but
//  only a save that reassigns the indices clears the duplicates instead of
//  syncing them onward.
//

import Testing
import Foundation
import SwiftData
@testable import RecipeBB

@MainActor
struct RecipeFormViewModelTests {

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Recipe.self, RecipeTag.self, PantryItem.self, PantryCategory.self, MealPlanEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    @Test func savingRenormalizesDuplicateSortOrders() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let recipe = Recipe(
            name: "Merged",
            desc: "",
            ingredients: [
                Ingredient(name: "Flour", quantity: "200g", sortOrder: 0),
                Ingredient(name: "Sugar", quantity: "50g", sortOrder: 0),
            ],
            ingredientHeadings: [IngredientHeading(name: "Base", sortOrder: 0)],
            steps: [
                Step(value: "Mix", sortOrder: 0),
                Step(value: "Bake", sortOrder: 0),
                Step(value: "Cool", sortOrder: 0),
            ]
        )
        context.insert(recipe)
        try context.save()

        let form = RecipeFormViewModel(context: context, recipeToEdit: recipe)
        form.name = "Merged (edited)"
        try form.saveRecipe()

        #expect(recipe.sortedIngredientItems.map(\.sortOrder) == [0, 1, 2])
        #expect(recipe.stepList.map(\.sortOrder).sorted() == [0, 1, 2])
    }

    /// Renormalizing must follow the order the user was actually shown, which is
    /// the tie-broken one — not the arbitrary order the relationship handed back.
    @Test func renormalizingPreservesTheDisplayedOrder() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let recipe = Recipe(
            name: "Ordered",
            desc: "",
            steps: [
                Step(value: "First", sortOrder: 0),
                Step(value: "Tied A", sortOrder: 1),
                Step(value: "Tied B", sortOrder: 1),
            ]
        )
        context.insert(recipe)
        try context.save()

        let displayed = recipe.sortedSteps.map(\.value)

        let form = RecipeFormViewModel(context: context, recipeToEdit: recipe)
        form.name = "Ordered (edited)"
        try form.saveRecipe()

        #expect(recipe.sortedSteps.map(\.value) == displayed)
        #expect(recipe.sortedSteps.map(\.sortOrder) == [0, 1, 2])
    }

    /// The form renumbers as the drag lands, not at save. The row's number comes
    /// from its draft, so a move that left `sortOrder` alone would show stale
    /// numbers until the recipe was saved.
    @Test func movingAStepRenumbersBeforeSave() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let recipe = Recipe(
            name: "Ordered",
            desc: "",
            steps: [
                Step(value: "Mix", sortOrder: 0),
                Step(value: "Bake", sortOrder: 1),
                Step(value: "Cool", sortOrder: 2),
            ]
        )
        context.insert(recipe)
        try context.save()

        let form = RecipeFormViewModel(context: context, recipeToEdit: recipe)
        form.moveSteps(from: IndexSet(integer: 2), to: 0)

        #expect(form.steps.map(\.value) == ["Cool", "Mix", "Bake"])
        #expect(form.steps.map(\.sortOrder) == [0, 1, 2])
    }

    /// Ingredients and headings share one editable list, and are split back into
    /// their two relationships on save. The order the user left them in has to
    /// survive that round trip.
    @Test func reorderingAcrossIngredientsAndHeadingsSurvivesSave() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let recipe = Recipe(
            name: "Grouped",
            desc: "",
            ingredients: [
                Ingredient(name: "Flour", quantity: "200g", sortOrder: 0),
                Ingredient(name: "Sugar", quantity: "50g", sortOrder: 2),
            ],
            ingredientHeadings: [IngredientHeading(name: "Base", sortOrder: 1)]
        )
        context.insert(recipe)
        try context.save()

        let form = RecipeFormViewModel(context: context, recipeToEdit: recipe)
        #expect(form.ingredientItems.map(\.name) == ["Flour", "Base", "Sugar"])

        form.moveIngredientItems(from: IndexSet(integer: 2), to: 0)
        #expect(form.ingredientItems.map(\.name) == ["Sugar", "Flour", "Base"])

        try form.saveRecipe()

        #expect(recipe.sortedIngredientItems.map { $0.name } == ["Sugar", "Flour", "Base"])
        #expect(recipe.sortedIngredientItems.map { $0.sortOrder } == [0, 1, 2])
    }

    /// A recipe whose indices are already clean comes through untouched —
    /// renormalizing is a repair, not a reshuffle.
    @Test func savingLeavesWellOrderedRecipesAlone() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let recipe = Recipe(
            name: "Clean",
            desc: "",
            steps: [
                Step(value: "One", sortOrder: 0),
                Step(value: "Two", sortOrder: 1),
                Step(value: "Three", sortOrder: 2),
            ]
        )
        context.insert(recipe)
        try context.save()

        let form = RecipeFormViewModel(context: context, recipeToEdit: recipe)
        form.name = "Clean (edited)"
        try form.saveRecipe()

        #expect(recipe.sortedSteps.map(\.value) == ["One", "Two", "Three"])
        #expect(recipe.sortedSteps.map(\.sortOrder) == [0, 1, 2])
    }
}
