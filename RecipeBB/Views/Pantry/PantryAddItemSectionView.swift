//
//  PantryAddItemSectionView.swift
//  RecipeBB
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

    /// Bumped on every tap purely to drive the bounce. The item itself lands in
    /// a list further down the screen, so the button is the only thing the user
    /// is still looking at when the add succeeds — same reasoning as the
    /// `.added` haptic it fires alongside.
    @State private var addPulse = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
                    Button {
                        addPulse += 1
                        onAdd()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.accentColor)
                            // Freezing the value rather than branching the
                            // modifier: Reduce Motion then has nothing to
                            // animate, and the view stays one expression.
                            .symbolEffect(.bounce, value: reduceMotion ? 0 : addPulse)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add to Pantry")
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
