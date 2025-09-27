//
//  IngredientFilterView.swift
//  RecipeNotes
//
//  Created by Jay Hui on 05/09/2025.
//

import SwiftUI
import SwiftData

struct IngredientFilterView: View {
    @EnvironmentObject private var viewModel: RecipeListViewModel

    @Query(sort: \Recipe.createdAt, order: .reverse)
    private var allRecipes: [Recipe]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Search ingredients", text: $viewModel.ingredientSearch)
                }

                Section("Ingredients") {
                    ForEach(viewModel.filteredIngredients(from: allRecipes), id: \.self) { ingredient in
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
    }
}

#Preview {
    let container = PreviewData.containerWithSamples()
    let viewModel = RecipeListViewModel(context: container.mainContext)

    return IngredientFilterView()
        .environmentObject(viewModel)
        .modelContainer(container)
}
