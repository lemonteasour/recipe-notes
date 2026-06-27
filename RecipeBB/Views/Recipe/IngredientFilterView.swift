//
//  IngredientFilterView.swift
//  RecipeBB
//
//  Created by Jay Hui on 05/09/2025.
//

import SwiftUI

struct IngredientFilterView: View {
    @Environment(RecipeListViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    /// All unique ingredient names, supplied by the owning list view.
    let ingredients: [String]

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            List {
                Section {
                    TextField("Search ingredients", text: $viewModel.ingredientSearch)
                }

                Section("Ingredients") {
                    ForEach(viewModel.filteredIngredients(from: ingredients), id: \.self) { ingredient in
                        IngredientRow(
                            ingredient: ingredient,
                            isSelected: viewModel.selectedIngredients.contains(ingredient)
                        ) {
                            viewModel.toggleIngredient(ingredient)
                        }
                    }
                }

                if !viewModel.selectedIngredients.isEmpty {
                    Section {
                        Button("Clear filters") {
                            viewModel.selectedIngredients.removeAll()
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
        }
    }
}

private struct IngredientRow: View {
    let ingredient: String
    let isSelected: Bool
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            HStack {
                Text(ingredient)
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
    let container = PreviewData.containerWithSamples()
    let viewModel = RecipeListViewModel(context: container.mainContext)

    return IngredientFilterView(ingredients: ["Flour", "Sugar", "Eggs", "Butter"])
        .environment(viewModel)
}
