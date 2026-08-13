//
//  PantryItemRowView.swift
//  RecipeBB
//
//  Created by Jay Hui on 24/10/2025.
//

import SwiftUI

struct PantryItemRowView: View {
    let item: PantryItem
    let editingItem: PantryItem?
    @Binding var editName: String
    @Binding var editQuantity: String
    let isInputFocused: FocusState<Bool>.Binding
    let onStartEdit: () -> Void
    let onSaveEdit: () -> Void
    let onCancelEdit: () -> Void

    var body: some View {
        if editingItem?.id == item.id {
            // Edit mode
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Ingredient name", text: $editName)
                        .focused(isInputFocused)

                    TextField("Quantity", text: $editQuantity)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .focused(isInputFocused)
                }

                Button(action: onSaveEdit) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Save")

                Button(action: onCancelEdit) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Cancel")
            }
        } else {
            // Display mode
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.body)
                    if !item.quantity.isEmpty {
                        Text(item.quantity)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityElement(children: .combine)

                Spacer()
                Button(action: onStartEdit) {
                    Image(systemName: "pencil")
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit")
            }
        }
    }
}
