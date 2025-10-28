//
//  PantryView.swift
//  RecipeNotes
//
//  Created by Jay Hui on 11/10/2025.
//

import SwiftUI
import SwiftData

struct PantryView: View {
    @Environment(\.modelContext) private var context
    @State private var viewModel: PantryViewModel

    @Query(sort: [SortDescriptor(\PantryCategory.sortOrder)])
    private var categories: [PantryCategory]

    @Query(sort: [SortDescriptor(\PantryItem.sortOrder)])
    private var uncategorizedItems: [PantryItem]

    @State private var newItemName = ""
    @State private var newItemQuantity = ""
    @State private var selectedCategory: PantryCategory?
    @State private var editingItem: PantryItem?
    @State private var editName = ""
    @State private var editQuantity = ""
    @FocusState private var isInputFocused: Bool

    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingCategorySheet = false

    init(context: ModelContext) {
        _viewModel = State(initialValue: PantryViewModel(context: context))

        // Filter uncategorized items
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

                    // Display items by category
                    ForEach(categories) { category in
                        let items = (category.items ?? []).sorted(by: { $0.sortOrder < $1.sortOrder })
                        PantryCategorySectionView(
                            category: category,
                            items: items,
                            editingItem: editingItem,
                            editName: $editName,
                            editQuantity: $editQuantity,
                            isInputFocused: $isInputFocused,
                            viewModel: viewModel,
                            onStartEdit: startEditing,
                            onSaveEdit: saveEdit,
                            onCancelEdit: { editingItem = nil },
                            onDrop: handleDrop
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
                            viewModel: viewModel,
                            onStartEdit: startEditing,
                            onSaveEdit: saveEdit,
                            onCancelEdit: { editingItem = nil },
                            onDrop: handleDrop
                        )
                    }
                }
            }
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
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
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
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
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
            showingError = true
        }
    }

    private func handleDrop(droppedIds: [UUID], to category: PantryCategory?) {
        for droppedId in droppedIds {
            // Find the item by ID in all categories and uncategorized items
            var foundItem: PantryItem?

            // Search in all categories
            for cat in categories {
                if let item = cat.items?.first(where: { $0.id == droppedId }) {
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
                viewModel.moveItem(item, to: category)
            }
        }
    }
}

#Preview {
    let container = PreviewData.containerWithSamples()
    return PantryView(context: container.mainContext)
        .modelContainer(container)
}
