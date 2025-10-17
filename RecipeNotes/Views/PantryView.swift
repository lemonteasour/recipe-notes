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

    @Query(sort: \PantryItem.name, order: .forward)
    private var pantryItems: [PantryItem]

    @State private var newItemName = ""
    @State private var newItemQuantity = ""
    @State private var editingItem: PantryItem?
    @State private var editName = ""
    @State private var editQuantity = ""
    @FocusState private var isInputFocused: Bool

    @State private var showingError = false
    @State private var errorMessage = ""

    init(context: ModelContext) {
        _viewModel = State(initialValue: PantryViewModel(context: context))
    }

    var body: some View {
        NavigationStack {
            List {
                // Add new item section
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            TextField("Ingredient name", text: $newItemName)
                                .textFieldStyle(.plain)
                                .focused($isInputFocused)
                                .onSubmit {
                                    addNewItem()
                                }
                            TextField("Quantity", text: $newItemQuantity)
                                .textFieldStyle(.plain)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .onSubmit {
                                    addNewItem()
                                }
                        }

                        if !newItemName.isEmpty {
                            Button {
                                addNewItem()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.green)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text("Add to Pantry")
                }

                // Pantry Items
                Section {
                    if pantryItems.isEmpty {
                        Text("No items in pantry yet.")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                    ForEach(pantryItems) { item in
                        if editingItem?.id == item.id {
                            // Edit mode
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    TextField("Ingredient name", text: $editName)
                                    TextField("Quantity", text: $editQuantity)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Button {
                                    saveEdit(item)
                                } label: {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                                .buttonStyle(.plain)

                                Button {
                                    editingItem = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
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
                                Spacer()
                                Button {
                                    startEditing(item)
                                } label: {
                                    Image(systemName: "pencil")
                                        .foregroundStyle(.blue)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .onDelete { offsets in
                        viewModel.deleteItems(at: offsets, from: pantryItems)
                    }
                } header: {
                    Text("Pantry Items")
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isInputFocused = false
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .navigationTitle("Pantry")
        }
    }

    private func addNewItem() {
        do {
            try viewModel.addItem(name: newItemName, quantity: newItemQuantity)
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
}

#Preview {
    let container = PreviewData.containerWithSamples()
    return PantryView(context: container.mainContext)
        .modelContainer(container)
}
