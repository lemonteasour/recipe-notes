//
//  PantryCategorySectionView.swift
//  RecipeNotes
//
//  Created by Jay Hui on 24/10/2025.
//

import SwiftUI

struct PantryCategorySectionView: View {
    let category: PantryCategory?
    let items: [PantryItem]
    let editingItem: PantryItem?
    @Binding var editName: String
    @Binding var editQuantity: String
    let isInputFocused: FocusState<Bool>.Binding
    let viewModel: PantryViewModel
    let onStartEdit: (PantryItem) -> Void
    let onSaveEdit: (PantryItem) -> Void
    let onCancelEdit: () -> Void
    let onDrop: ([String], PantryCategory?) -> Void

    var categoryName: String {
        category?.name ?? "Uncategorized"
    }

    var body: some View {
        Section {
            if items.isEmpty {
                Text("No items")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
            ForEach(items) { item in
                PantryItemRowView(
                    item: item,
                    editingItem: editingItem,
                    editName: $editName,
                    editQuantity: $editQuantity,
                    isInputFocused: isInputFocused,
                    onStartEdit: { onStartEdit(item) },
                    onSaveEdit: { onSaveEdit(item) },
                    onCancelEdit: onCancelEdit
                )
                .draggable(item.id.uuidString)
            }
            .onDelete { offsets in
                viewModel.deleteItems(at: offsets, from: items)
            }
            .onMove { source, destination in
                viewModel.reorderItems(in: category, from: source, to: destination, items: items)
            }
        } header: {
            if let category = category {
                HStack {
                    Text(category.name)
                    Spacer()
                    Button {
                        // TODO: Edit category
                    } label: {
                        Image(systemName: "pencil.circle")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Text("Uncategorized")
            }
        }
        .dropDestination(for: String.self) { droppedIds, _ in
            onDrop(droppedIds, category)
            return true
        }
    }
}
