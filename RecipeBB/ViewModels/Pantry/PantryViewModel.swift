//
//  PantryViewModel.swift
//  RecipeBB
//
//  Created by Jay Hui on 16/10/2025.
//

import SwiftUI
import SwiftData

@MainActor
@Observable
class PantryViewModel {
    private let context: ModelContext

    // MARK: - Init
    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Item Management
    func deleteItem(_ item: PantryItem) throws {
        context.delete(item)
        try context.save()
    }

    func addItem(name: String, quantity: String, category: PantryCategory?) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw ValidationError.emptyPantryItemName
        }

        let maxSortOrder = category?.items?.map(\.sortOrder).max() ?? -1
        let item = PantryItem(
            name: trimmedName,
            quantity: quantity,
            sortOrder: maxSortOrder + 1,
            category: category
        )
        context.insert(item)
        try context.save()
    }

    func updateItem(_ item: PantryItem, name: String, quantity: String) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw ValidationError.emptyPantryItemName
        }

        item.name = trimmedName
        item.quantity = quantity
        try context.save()
    }

    func moveItem(_ item: PantryItem, to category: PantryCategory?) throws {
        // Get the highest sort order in the destination category
        let maxSortOrder = category?.items?.map(\.sortOrder).max() ?? -1
        item.category = category
        item.sortOrder = maxSortOrder + 1
        try context.save()
    }

    func reorderItems(in category: PantryCategory?, from source: IndexSet, to destination: Int, items: [PantryItem]) throws {
        var itemsArray = items
        itemsArray.move(fromOffsets: source, toOffset: destination)

        // Update sort order for all items
        for (index, item) in itemsArray.enumerated() {
            item.sortOrder = index
        }
        try context.save()
    }

    // MARK: - Category Management

    func addCategory(name: String) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw ValidationError.emptyCategoryName
        }

        // Get the highest sort order
        var descriptor = FetchDescriptor<PantryCategory>(sortBy: [SortDescriptor(\.sortOrder, order: .reverse)])
        descriptor.fetchLimit = 1
        let maxSortOrder = try context.fetch(descriptor).first?.sortOrder ?? -1

        let category = PantryCategory(name: trimmedName, sortOrder: maxSortOrder + 1)
        context.insert(category)
        try context.save()
    }

    func updateCategory(_ category: PantryCategory, name: String) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw ValidationError.emptyCategoryName
        }

        category.name = trimmedName
        try context.save()
    }

    func deleteCategory(_ category: PantryCategory) throws {
        context.delete(category)
        try context.save()
    }

    func reorderCategories(from source: IndexSet, to destination: Int, categories: [PantryCategory]) throws {
        var categoriesArray = categories
        categoriesArray.move(fromOffsets: source, toOffset: destination)

        // Update sort order for all categories
        for (index, category) in categoriesArray.enumerated() {
            category.sortOrder = index
        }
        try context.save()
    }
}
