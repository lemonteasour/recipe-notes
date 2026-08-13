//
//  PantryView.swift
//  RecipeBB
//
//  Created by Jay Hui on 11/10/2025.
//

import SwiftUI
import SwiftData

struct PantryView: View {
    @State private var viewModel: PantryViewModel

    @Query(sort: [SortDescriptor(\PantryCategory.sortOrder)])
    private var categories: [PantryCategory]

    // Configured in init: uncategorized items sorted by sortOrder
    @Query private var uncategorizedItems: [PantryItem]

    @State private var newItemName = ""
    @State private var newItemQuantity = ""
    @State private var selectedCategory: PantryCategory?
    @State private var editingItem: PantryItem?
    @State private var editName = ""
    @State private var editQuantity = ""
    @FocusState private var isInputFocused: Bool

    @State private var errorMessage: String?
    @State private var showingCategorySheet = false
    @State private var feedback: FeedbackSignal?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(context: ModelContext) {
        _viewModel = State(initialValue: PantryViewModel(context: context))

        let predicate = #Predicate<PantryItem> { item in
            item.category == nil
        }
        _uncategorizedItems = Query(filter: predicate, sort: [SortDescriptor(\PantryItem.sortOrder)])
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Add new item section
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Add to Pantry")
                            .font(.footnote)
                            .textCase(.uppercase)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .padding(.bottom, 6)

                        PantryAddItemSectionView(
                            newItemName: $newItemName,
                            newItemQuantity: $newItemQuantity,
                            selectedCategory: $selectedCategory,
                            isInputFocused: $isInputFocused,
                            categories: categories,
                            onAdd: addNewItem
                        )
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(28)
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 16)

                    // Nothing at all yet — the per-category "No items" line
                    // can't speak for a pantry with no categories either.
                    if categories.isEmpty, uncategorizedItems.isEmpty {
                        ContentUnavailableView(
                            "Pantry Is Empty",
                            systemImage: "cabinet",
                            description: Text("Add what you have on hand above, or make a category with the folder button.")
                        )
                        .padding(.top, 40)
                    }

                    // Display items by category
                    ForEach(categories) { category in
                        let items = category.itemList.sorted(by: { $0.sortOrder < $1.sortOrder })
                        PantryCategorySectionView(
                            category: category,
                            items: items,
                            editingItem: editingItem,
                            editName: $editName,
                            editQuantity: $editQuantity,
                            isInputFocused: $isInputFocused,
                            onStartEdit: startEditing,
                            onSaveEdit: saveEdit,
                            onCancelEdit: { editingItem = nil },
                            onDrop: handleDrop,
                            onDelete: deleteItem
                        )
                    }

                    // Uncategorized items
                    if !uncategorizedItems.isEmpty {
                        PantryCategorySectionView(
                            category: nil,
                            items: uncategorizedItems,
                            editingItem: editingItem,
                            editName: $editName,
                            editQuantity: $editQuantity,
                            isInputFocused: $isInputFocused,
                            onStartEdit: startEditing,
                            onSaveEdit: saveEdit,
                            onCancelEdit: { editingItem = nil },
                            onDrop: handleDrop,
                            onDelete: deleteItem
                        )
                    }
                }
                // Sections are driven by `@Query`, which lands its change on a
                // later tick — `withAnimation` around the mutation wouldn't
                // catch it, so animate on the value instead.
                .animation(reduceMotion ? nil : .default, value: categories.map(\.id))
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCategorySheet = true
                    } label: {
                        Image(systemName: "folder.badge.plus")
                    }
                }
            }
            .errorAlert($errorMessage)
            .sensoryFeedback(signal: feedback)
            .sheet(isPresented: $showingCategorySheet) {
                PantryCategoryManagementView(viewModel: viewModel, categories: categories)
            }
            .navigationTitle("Pantry")
        }
    }

    private func addNewItem() {
        guard !newItemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            isInputFocused = false
            return
        }

        do {
            try viewModel.addItem(name: newItemName, quantity: newItemQuantity, category: selectedCategory)
            newItemName = ""
            newItemQuantity = ""
            isInputFocused = false
            feedback = .added
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteItem(_ item: PantryItem) {
        do {
            try viewModel.deleteItem(item)
            feedback = .deleted
        } catch {
            errorMessage = "Failed to delete item: \(error.localizedDescription)"
        }
    }

    private func startEditing(_ item: PantryItem) {
        editingItem = item
        editName = item.name
        editQuantity = item.quantity
    }

    private func saveEdit(_ item: PantryItem) {
        do {
            try viewModel.updateItem(item, name: editName, quantity: editQuantity)
            editingItem = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func handleDrop(droppedIds: [UUID], to category: PantryCategory?) {
        for droppedId in droppedIds {
            // Find the item by ID in all categories and uncategorized items
            var foundItem: PantryItem?

            // Search in all categories
            for cat in categories {
                if let item = cat.itemList.first(where: { $0.id == droppedId }) {
                    foundItem = item
                    break
                }
            }

            // If not found, search in uncategorized items
            if foundItem == nil {
                foundItem = uncategorizedItems.first(where: { $0.id == droppedId })
            }

            // Move the item to the target category
            if let item = foundItem {
                do {
                    try viewModel.moveItem(item, to: category)
                } catch {
                    errorMessage = "Failed to move item: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    let container = SeedDataService.containerWithSamples()
    return PantryView(context: container.mainContext)
        .modelContainer(container)
}
