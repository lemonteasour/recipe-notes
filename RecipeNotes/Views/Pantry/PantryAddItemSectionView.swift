//
//  PantryAddItemSectionView.swift
//  RecipeNotes
//
//  Created by Jay Hui on 24/10/2025.
//

import SwiftUI

struct PantryAddItemSectionView: View {
    @Binding var newItemName: String
    @Binding var newItemQuantity: String
    @Binding var selectedCategory: PantryCategory?
    let isInputFocused: FocusState<Bool>.Binding
    let categories: [PantryCategory]
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Ingredient name", text: $newItemName)
                        .textFieldStyle(.plain)
                        .focused(isInputFocused)
                        .onSubmit(onAdd)

                    TextField("Quantity", text: $newItemQuantity)
                        .textFieldStyle(.plain)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .focused(isInputFocused)
                        .onSubmit(onAdd)
                }

                if !newItemName.isEmpty {
                    Button(action: onAdd) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.green)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)

            Divider()
                .padding(.leading, 16)

            // Category picker
            HStack {
                Text("Category")
                Spacer()
                Picker("Category", selection: $selectedCategory) {
                    Text("None").tag(nil as PantryCategory?)
                    ForEach(categories) { category in
                        Text(category.name).tag(category as PantryCategory?)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
        }
    }
}
