//
//  RecipeFilterView.swift
//  RecipeBB
//
//  Created by Jay Hui on 05/09/2025.
//

import SwiftUI
import SwiftData

struct RecipeFilterView: View {
    @Environment(RecipeListViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    /// All unique ingredient names, supplied by the owning list view.
    let ingredients: [String]

    @Query(sort: \RecipeTag.name)
    private var allTags: [RecipeTag]

    @State private var errorMessage: String?

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            List {
                if !allTags.isEmpty {
                    Section("Tags") {
                        ForEach(allTags) { tag in
                            FilterRow(
                                title: tag.name,
                                isSelected: viewModel.selectedTagIDs.contains(tag.id)
                            ) {
                                viewModel.toggleTag(tag)
                            }
                        }
                        .onDelete { offsets in
                            // Resolve every offset up front: deleting saves,
                            // which can shrink the @Query array mid-loop and
                            // leave the remaining offsets out of range.
                            let doomed = offsets.compactMap { index in
                                allTags.indices.contains(index) ? allTags[index] : nil
                            }
                            do {
                                for tag in doomed {
                                    try viewModel.deleteTag(tag)
                                }
                            } catch {
                                errorMessage = "Failed to delete tag: \(error.localizedDescription)"
                            }
                        }
                    }
                }

                Section {
                    TextField("Search ingredients", text: $viewModel.ingredientSearch)
                }

                Section("Ingredients") {
                    ForEach(viewModel.filteredIngredients(from: ingredients), id: \.self) { ingredient in
                        FilterRow(
                            title: ingredient,
                            isSelected: viewModel.selectedIngredients.contains(ingredient)
                        ) {
                            viewModel.toggleIngredient(ingredient)
                        }
                    }
                }

                if viewModel.hasActiveFilters {
                    Section {
                        Button("Clear filters") {
                            viewModel.selectedIngredients.removeAll()
                            viewModel.selectedTagIDs.removeAll()
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Filter")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .errorAlert($errorMessage)
        }
    }
}

private struct FilterRow: View {
    let title: String
    let isSelected: Bool
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            HStack {
                Text(title)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let container = SeedDataService.containerWithSamples()
    let viewModel = RecipeListViewModel(context: container.mainContext)

    return RecipeFilterView(ingredients: ["Flour", "Sugar", "Eggs", "Butter"])
        .environment(viewModel)
        .modelContainer(container)
}
