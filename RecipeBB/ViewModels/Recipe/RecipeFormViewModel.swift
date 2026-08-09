//
//  RecipeFormViewModel.swift
//  RecipeBB
//
//  Created by Jay Hui on 27/09/2025.
//

import SwiftUI
import SwiftData
import PhotosUI

@MainActor
@Observable
class RecipeFormViewModel {
    private let context: ModelContext
    let recipeToEdit: Recipe?

    // MARK: - Form state
    var name = ""
    var desc = ""
    var photo: Data?
    var ingredients: [Ingredient] = []
    var allIngredientNames: [String] = []
    var ingredientHeadings: [IngredientHeading] = []
    var steps: [Step] = []
    var allTags: [RecipeTag] = []
    var selectedTagIDs: Set<UUID> = []
    var newTagName = ""

    // Tags created in this form session. They are only inserted into the
    // context on save (and only if still selected), so cancelling leaks nothing.
    private var pendingNewTags: [RecipeTag] = []

    // MARK: - Computed
    var combinedIngredientItems: [any IngredientItem] {
        mergedIngredientItems(ingredients, ingredientHeadings)
    }

    var sortedSteps: [Step] {
        steps.sortedByOrder()
    }

    // MARK: - Init
    init(context: ModelContext, recipeToEdit: Recipe? = nil) {
        self.context = context
        self.recipeToEdit = recipeToEdit
        loadRecipe()
        self.allIngredientNames = IngredientCatalog.uniqueNames(in: context)
        let descriptor = FetchDescriptor<RecipeTag>(sortBy: [SortDescriptor(\.name)])
        self.allTags = (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Tags
    func isTagSelected(_ tag: RecipeTag) -> Bool {
        selectedTagIDs.contains(tag.id)
    }

    func toggleTag(_ tag: RecipeTag) {
        if selectedTagIDs.contains(tag.id) {
            selectedTagIDs.remove(tag.id)
        } else {
            selectedTagIDs.insert(tag.id)
        }
    }

    /// Create (or reuse, matching case-insensitively) a tag from `newTagName` and select it.
    func addTag() {
        let trimmed = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        newTagName = ""

        if let existing = allTags.first(where: {
            $0.name.compare(trimmed, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }) {
            selectedTagIDs.insert(existing.id)
            return
        }

        let tag = RecipeTag(name: trimmed)
        pendingNewTags.append(tag)
        allTags.append(tag)
        allTags.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        selectedTagIDs.insert(tag.id)
    }

    // MARK: - Bindings
    func binding(for ingredient: Ingredient) -> Binding<Ingredient>? {
        binding(for: ingredient, in: \.ingredients)
    }

    func binding(for heading: IngredientHeading) -> Binding<IngredientHeading>? {
        binding(for: heading, in: \.ingredientHeadings)
    }

    func binding(for step: Step) -> Binding<Step>? {
        binding(for: step, in: \.steps)
    }

    /// A two-way binding to the array element matching `element`'s id, or nil if it's no longer present.
    private func binding<T: Identifiable>(
        for element: T,
        in arrayKeyPath: ReferenceWritableKeyPath<RecipeFormViewModel, [T]>
    ) -> Binding<T>? where T.ID == UUID {
        guard self[keyPath: arrayKeyPath].contains(where: { $0.id == element.id }) else { return nil }
        return Binding(
            get: { self[keyPath: arrayKeyPath].first(where: { $0.id == element.id }) ?? element },
            set: { newValue in
                guard let idx = self[keyPath: arrayKeyPath].firstIndex(where: { $0.id == element.id }) else { return }
                self[keyPath: arrayKeyPath][idx] = newValue
            }
        )
    }

    // MARK: - Photo
    func updatePhoto(from item: PhotosPickerItem) async {
        guard
            let data = try? await item.loadTransferable(type: Data.self),
            let image = UIImage(data: data),
            let jpeg = image.jpegData(compressionQuality: 0.8)
        else { return }
        photo = jpeg
    }

    // MARK: - Ingredient Items
    func addIngredient() {
        let newIndex = combinedIngredientItems.count
        ingredients.append(Ingredient(name: "", quantity: "", sortOrder: newIndex))
    }

    func addHeading() {
        let newIndex = combinedIngredientItems.count
        ingredientHeadings.append(IngredientHeading(name: "", sortOrder: newIndex))
    }

    func reindexIngredientItems(using ordered: [any IngredientItem]) {
        for (i, item) in ordered.enumerated() {
            if let ing = item as? Ingredient,
               let idx = ingredients.firstIndex(where: { $0.id == ing.id }) {
                ingredients[idx].sortOrder = i
            } else if let heading = item as? IngredientHeading,
                      let idx = ingredientHeadings.firstIndex(where: { $0.id == heading.id }) {
                ingredientHeadings[idx].sortOrder = i
            }
        }
    }

    func deleteIngredientItems(at offsets: IndexSet) {
        var all = combinedIngredientItems
        all.remove(atOffsets: offsets)
        ingredients = all.compactMap { $0 as? Ingredient }
        ingredientHeadings = all.compactMap { $0 as? IngredientHeading }
        reindexIngredientItems(using: all)
    }

    func moveIngredientItems(from indices: IndexSet, to newOffset: Int) {
        var all = combinedIngredientItems
        all.move(fromOffsets: indices, toOffset: newOffset)
        ingredients = all.compactMap { $0 as? Ingredient }
        ingredientHeadings = all.compactMap { $0 as? IngredientHeading }
        reindexIngredientItems(using: all)
    }

    // MARK: - Steps
    func addStep() {
        steps.append(Step(value: "", sortOrder: steps.count))
    }

    private func reindexSteps() {
        for (i, step) in steps.enumerated() {
            step.sortOrder = i
        }
    }

    func deleteSteps(at offsets: IndexSet) {
        steps.remove(atOffsets: offsets)
        reindexSteps()
    }

    func moveSteps(from indices: IndexSet, to newOffset: Int) {
        steps.move(fromOffsets: indices, toOffset: newOffset)
        reindexSteps()
    }

    // MARK: - Persistence
    func loadRecipe() {
        guard let recipe = recipeToEdit else { return }
        name = recipe.name
        desc = recipe.desc
        photo = recipe.photo
        selectedTagIDs = Set(recipe.sortedTags.map(\.id))

        // Create detached copies so we don't mutate the originals until Save is pressed.
        // Copies keep the originals' ids so they can be matched back up on save.
        ingredients = recipe.ingredientList.sorted { $0.sortOrder < $1.sortOrder }.map {
            let copy = Ingredient(name: $0.name, quantity: $0.quantity, sortOrder: $0.sortOrder)
            copy.id = $0.id
            return copy
        }
        ingredientHeadings = recipe.headingList.sorted { $0.sortOrder < $1.sortOrder }.map {
            let copy = IngredientHeading(name: $0.name, sortOrder: $0.sortOrder)
            copy.id = $0.id
            return copy
        }
        steps = recipe.stepList.sorted { $0.sortOrder < $1.sortOrder }.map {
            let copy = Step(value: $0.value, sortOrder: $0.sortOrder)
            copy.id = $0.id
            return copy
        }
    }

    /// Reconciles a recipe's stored children against the edited copies, matching by id:
    /// survivors are updated in place, missing ones are deleted, and brand-new ones are inserted.
    private func reconcileChildren<Model>(
        existing: [Model],
        edited: [Model],
        update: (_ original: Model, _ edited: Model) -> Void,
        attach: (Model) -> Void
    ) where Model: PersistentModel, Model: Identifiable, Model.ID == UUID {
        let existingByID = Dictionary(existing.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let editedIDs = Set(edited.map(\.id))

        for original in existing where !editedIDs.contains(original.id) {
            context.delete(original)
        }

        for copy in edited {
            if let original = existingByID[copy.id] {
                update(original, copy)
            } else {
                attach(copy)
                context.insert(copy)
            }
        }
    }

    func saveRecipe() throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw ValidationError.emptyRecipeName
        }

        // Normalize indices. Steps carry their own index space, so they need
        // the same treatment: two devices reordering offline merge into
        // duplicate sortOrders, and only a save that renormalizes clears them
        // rather than leaving the list leaning on the id tie-break forever.
        let all = combinedIngredientItems
        reindexIngredientItems(using: all)
        steps = sortedSteps
        reindexSteps()

        // Only tags still selected at save time get persisted
        for tag in pendingNewTags where selectedTagIDs.contains(tag.id) {
            context.insert(tag)
        }
        let selectedTags = allTags.filter { selectedTagIDs.contains($0.id) }

        if let recipe = recipeToEdit {
            recipe.name = trimmedName
            recipe.desc = desc
            recipe.photo = photo
            recipe.tags = selectedTags

            // Reconcile children in place: update survivors, delete removed, insert new.
            // This preserves object identity instead of churning the whole graph on every save.
            reconcileChildren(
                existing: recipe.ingredientList,
                edited: ingredients,
                update: { original, copy in
                    original.name = copy.name
                    original.quantity = copy.quantity
                    original.sortOrder = copy.sortOrder
                },
                attach: { $0.recipe = recipe }
            )
            reconcileChildren(
                existing: recipe.headingList,
                edited: ingredientHeadings,
                update: { original, copy in
                    original.name = copy.name
                    original.sortOrder = copy.sortOrder
                },
                attach: { $0.recipe = recipe }
            )
            reconcileChildren(
                existing: recipe.stepList,
                edited: steps,
                update: { original, copy in
                    original.value = copy.value
                    original.sortOrder = copy.sortOrder
                },
                attach: { $0.recipe = recipe }
            )
        } else {
            let newRecipe = Recipe(
                name: trimmedName,
                desc: desc,
                photo: photo,
                ingredients: ingredients,
                ingredientHeadings: ingredientHeadings,
                steps: steps
            )
            context.insert(newRecipe)
            newRecipe.tags = selectedTags
        }

        try context.save()
    }
}
