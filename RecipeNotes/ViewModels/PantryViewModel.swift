//
//  PantryViewModel.swift
//  RecipeNotes
//
//  Created by Jay Hui on 16/10/2025.
//

import SwiftUI
import SwiftData

@MainActor
class PantryViewModel: ObservableObject {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func deleteItems(at offsets: IndexSet, from items: [PantryItem]) {
        for index in offsets {
            context.delete(items[index])
        }
    }

    func addItem(name: String, quantity: String) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw PantryError.emptyName
        }

        let item = PantryItem(name: trimmedName, quantity: quantity)
        context.insert(item)
        try context.save()
    }

    func updateItem(_ item: PantryItem, name: String, quantity: String) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw PantryError.emptyName
        }

        item.name = trimmedName
        item.quantity = quantity
        try context.save()
    }
}
