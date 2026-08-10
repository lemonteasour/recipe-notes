//
//  RecipeFormViewModel.swift
//  RecipeBB
//
//  Created by Jay Hui on 27/09/2025.
//

import SwiftUI
import SwiftData
import PhotosUI

// MARK: - Drafts
//
// The form edits value types and only touches the models on save. It used to
// hold detached `@Model` copies, but mutating a property on one of those leaves
// the array holding it unchanged, so SwiftUI never re-rendered the row —
// renumbering after a drag stayed invisible until the recipe was saved.

/// A row of the form's ingredient list: an ingredient, or a heading that groups
/// the rows under it. Both kinds share one list because the user reorders them
/// together.
struct IngredientDraft: Identifiable, Hashable {
    enum Kind: Hashable {
        case ingredient
        case heading
    }

    var id = UUID()
    var kind: Kind
    var name: String = ""
    /// Unused by headings.
    var quantity: String = ""
    var sortOrder: Int
}

struct StepDraft: Identifiable, Hashable {
    var id = UUID()
    var value: String = ""
    var sortOrder: Int
}

@MainActor
@Observable
class RecipeFormViewModel {
    private let context: ModelContext
    let recipeToEdit: Recipe?

    // MARK: - Form state
    var name = ""
    var desc = ""
    var photo: Data?
    var ingredientItems: [IngredientDraft] = []
    var steps: [StepDraft] = []
    var allIngredientNames: [String] = []
    var allTags: [RecipeTag] = []
    var selectedTagIDs: Set<UUID> = []
    var newTagName = ""

    // Tags created in this form session. They are only inserted into the
    // context on save (and only if still selected), so cancelling leaks nothing.
    private var pendingNewTags: [RecipeTag] = []

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

    // MARK: - Photo
    func updatePhoto(from item: PhotosPickerItem) async {
        guard
            let data = try? await item.loadTransferable(type: Data.self),
            let image = UIImage(data: data),
            let jpeg = image.jpegData(compressionQuality: 0.8)
        else { return }
        photo = jpeg
    }

    // MARK: - Rows

    /// The add methods return the new row so the form can move focus into it.
    @discardableResult
    func addIngredient() -> IngredientDraft {
        let draft = IngredientDraft(kind: .ingredient, sortOrder: ingredientItems.count)
        ingredientItems.append(draft)
        return draft
    }

    @discardableResult
    func addHeading() -> IngredientDraft {
        let draft = IngredientDraft(kind: .heading, sortOrder: ingredientItems.count)
        ingredientItems.append(draft)
        return draft
    }

    @discardableResult
    func addStep() -> StepDraft {
        let draft = StepDraft(sortOrder: steps.count)
        steps.append(draft)
        return draft
    }

    func deleteIngredientItems(at offsets: IndexSet) {
        ingredientItems.remove(atOffsets: offsets)
        renumber()
    }

    func moveIngredientItems(from indices: IndexSet, to newOffset: Int) {
        ingredientItems.move(fromOffsets: indices, toOffset: newOffset)
        renumber()
    }

    func deleteSteps(at offsets: IndexSet) {
        steps.remove(atOffsets: offsets)
        renumber()
    }

    func moveSteps(from indices: IndexSet, to newOffset: Int) {
        steps.move(fromOffsets: indices, toOffset: newOffset)
        renumber()
    }

    /// Position in the array is the order; `sortOrder` mirrors it, which is what
    /// the rows display and what lands on the models at save.
    private func renumber() {
        for index in ingredientItems.indices {
            ingredientItems[index].sortOrder = index
        }
        for index in steps.indices {
            steps[index].sortOrder = index
        }
    }

    // MARK: - Persistence
    func loadRecipe() {
        guard let recipe = recipeToEdit else { return }
        name = recipe.name
        desc = recipe.desc
        photo = recipe.photo
        selectedTagIDs = Set(recipe.sortedTags.map(\.id))

        // Loaded in the order the user was shown, which is the tie-broken one.
        // Numbering from that order is what clears duplicate sortOrders on save.
        ingredientItems = recipe.sortedIngredientItems.enumerated().map { index, item in
            if let ingredient = item as? Ingredient {
                return IngredientDraft(
                    id: ingredient.id,
                    kind: .ingredient,
                    name: ingredient.name,
                    quantity: ingredient.quantity,
                    sortOrder: index
                )
            }
            return IngredientDraft(id: item.id, kind: .heading, name: item.name, sortOrder: index)
        }
        steps = recipe.sortedSteps.enumerated().map { index, step in
            StepDraft(id: step.id, value: step.value, sortOrder: index)
        }
    }

    /// Reconciles a recipe's stored children against the edited drafts, matching
    /// by id: survivors are updated in place, missing ones are deleted, and
    /// brand-new ones are built and inserted.
    private func reconcileChildren<Model, Draft>(
        existing: [Model],
        edited: [Draft],
        update: (_ model: Model, _ draft: Draft) -> Void,
        make: (_ draft: Draft) -> Model
    ) where Model: PersistentModel, Model: Identifiable, Model.ID == UUID,
            Draft: Identifiable, Draft.ID == UUID {
        let existingByID = Dictionary(existing.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let editedIDs = Set(edited.map(\.id))

        for original in existing where !editedIDs.contains(original.id) {
            context.delete(original)
        }

        for draft in edited {
            if let original = existingByID[draft.id] {
                update(original, draft)
            } else {
                context.insert(make(draft))
            }
        }
    }

    func saveRecipe() throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw ValidationError.emptyRecipeName
        }

        // Normalize indices. Ingredients and steps carry separate index spaces,
        // and both need it: two devices reordering offline merge into duplicate
        // sortOrders, and only a save that renormalizes clears them rather than
        // leaving the list leaning on the id tie-break forever.
        renumber()

        let ingredientDrafts = ingredientItems.filter { $0.kind == .ingredient }
        let headingDrafts = ingredientItems.filter { $0.kind == .heading }

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
                edited: ingredientDrafts,
                update: { model, draft in
                    model.name = draft.name
                    model.quantity = draft.quantity
                    model.sortOrder = draft.sortOrder
                },
                make: { draft in
                    let model = Ingredient(name: draft.name, quantity: draft.quantity, sortOrder: draft.sortOrder)
                    model.id = draft.id
                    model.recipe = recipe
                    return model
                }
            )
            reconcileChildren(
                existing: recipe.headingList,
                edited: headingDrafts,
                update: { model, draft in
                    model.name = draft.name
                    model.sortOrder = draft.sortOrder
                },
                make: { draft in
                    let model = IngredientHeading(name: draft.name, sortOrder: draft.sortOrder)
                    model.id = draft.id
                    model.recipe = recipe
                    return model
                }
            )
            reconcileChildren(
                existing: recipe.stepList,
                edited: steps,
                update: { model, draft in
                    model.value = draft.value
                    model.sortOrder = draft.sortOrder
                },
                make: { draft in
                    let model = Step(value: draft.value, sortOrder: draft.sortOrder)
                    model.id = draft.id
                    model.recipe = recipe
                    return model
                }
            )
        } else {
            let newRecipe = Recipe(
                name: trimmedName,
                desc: desc,
                photo: photo,
                ingredients: ingredientDrafts.map {
                    Ingredient(name: $0.name, quantity: $0.quantity, sortOrder: $0.sortOrder)
                },
                ingredientHeadings: headingDrafts.map {
                    IngredientHeading(name: $0.name, sortOrder: $0.sortOrder)
                },
                steps: steps.map {
                    Step(value: $0.value, sortOrder: $0.sortOrder)
                }
            )
            context.insert(newRecipe)
            newRecipe.tags = selectedTags
        }

        try context.save()
    }
}
