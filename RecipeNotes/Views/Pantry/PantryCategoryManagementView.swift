//
//  PantryCategoryManagementView.swift
//  RecipeNotes
//
//  Created by Jay Hui on 23/10/2025.
//

import SwiftUI
import SwiftData

struct PantryCategoryManagementView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: PantryViewModel
    let categories: [PantryCategory]

    @State private var newCategoryName = ""
    @State private var editingCategory: PantryCategory?
    @State private var editName = ""
    @FocusState private var isInputFocused: Bool

    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            List {
                // Add new category section
                Section {
                    HStack {
                        TextField("Category name", text: $newCategoryName)
                            .textFieldStyle(.plain)
                            .focused($isInputFocused)
                            .onSubmit {
                                addNewCategory()
                            }

                        if !newCategoryName.isEmpty {
                            Button {
                                addNewCategory()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.green)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text("Add Category")
                }

                // Existing categories
                Section {
                    if categories.isEmpty {
                        Text("No categories yet.")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                    ForEach(categories) { category in
                        if editingCategory?.id == category.id {
                            // Edit mode
                            HStack {
                                TextField("Category name", text: $editName)
                                    .focused($isInputFocused)

                                Button {
                                    saveEdit(category)
                                } label: {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                                .buttonStyle(.plain)

                                Button {
                                    editingCategory = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        } else {
                            // Display mode
                            HStack {
                                Text(category.name)
                                    .font(.body)
                                Spacer()
                                Button {
                                    startEditing(category)
                                } label: {
                                    Image(systemName: "pencil")
                                        .foregroundStyle(.blue)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            do {
                                try viewModel.deleteCategory(categories[index])
                            } catch {
                                errorMessage = "Failed to delete category: \(error.localizedDescription)"
                                showingError = true
                            }
                        }
                    }
                    .onMove { source, destination in
                        do {
                            try viewModel.reorderCategories(from: source, to: destination, categories: categories)
                        } catch {
                            errorMessage = "Failed to reorder categories: \(error.localizedDescription)"
                            showingError = true
                        }
                    }
                } header: {
                    Text("Categories")
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                isInputFocused = false
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .navigationTitle("Manage Categories")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func addNewCategory() {
        guard !newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            isInputFocused = false
            return
        }

        do {
            try viewModel.addCategory(name: newCategoryName)
            newCategoryName = ""
            isInputFocused = false
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    private func startEditing(_ category: PantryCategory) {
        editingCategory = category
        editName = category.name
    }

    private func saveEdit(_ category: PantryCategory) {
        do {
            try viewModel.updateCategory(category, name: editName)
            editingCategory = nil
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}
