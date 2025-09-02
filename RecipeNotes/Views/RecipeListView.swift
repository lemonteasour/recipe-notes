//
//  RecipeListView.swift
//  RecipeNotes
//
//  Created by Jay Hui on 21/08/2025.
//

import SwiftUI
import SwiftData

struct RecipeListView: View {
    @Environment(\.modelContext) private var context

    @State private var showingAddForm = false
    @State private var searchText = ""
    @State private var selectedIngredients: Set<String> = []
    @State private var ingredientSearch = ""
    @State private var showingFilterSheet = false

    @Query(sort: \Recipe.createdAt, order: .reverse)
    private var allRecipes: [Recipe]

    private var allIngredients: [String] {
        let names = allRecipes.flatMap { recipe in
            recipe.ingredients.map { $0.name }
        }
        return Array(Set(names)).sorted()
    }

    private var filteredIngredients: [String] {
        if ingredientSearch.isEmpty { return allIngredients }
        return allIngredients.filter { $0.localizedStandardContains(ingredientSearch) }
    }

    private var filteredRecipes: [Recipe] {
        allRecipes.filter { recipe in
            let matchesNameOrDesc =
                searchText.isEmpty ||
                recipe.name.localizedStandardContains(searchText) ||
                recipe.desc.localizedStandardContains(searchText)

            let matchesIngredients =
                selectedIngredients.isEmpty ||
                recipe.ingredients.contains { selectedIngredients.contains($0.name) }

            return matchesNameOrDesc && matchesIngredients
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredRecipes) { recipe in
                    NavigationLink(value: recipe) {
                        Text(recipe.name)
                    }
                }
                .onDelete(perform: deleteRecipe)
            }
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe)
            }
            .navigationTitle("Recipes")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingFilterSheet = true
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showingAddForm) {
                RecipeFormView()
            }
            .sheet(isPresented: $showingFilterSheet) {
                NavigationStack {
                    List {
                        Section {
                            TextField("Search ingredients", text: $ingredientSearch)
                        }

                        Section("Ingredients") {
                            ForEach(filteredIngredients, id: \.self) { ingredient in
                                IngredientRow(
                                    ingredient: ingredient,
                                    isSelected: selectedIngredients.contains(ingredient)
                                ) {
                                    toggleIngredient(ingredient)
                                }
                            }
                        }

                        if !selectedIngredients.isEmpty {
                            Section {
                                Button("Clear filters") {
                                    selectedIngredients.removeAll()
                                }
                                .foregroundStyle(.red)
                            }
                        }
                    }
                    .navigationTitle("Filter")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") {
                                showingFilterSheet = false
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search recipes")
        }
    }

    private func deleteRecipe(at offsets: IndexSet) {
        for index in offsets {
            context.delete(allRecipes[index])
        }
    }

    private func toggleIngredient(_ ingredient: String) {
        if selectedIngredients.contains(ingredient) {
            selectedIngredients.remove(ingredient)
        } else {
            selectedIngredients.insert(ingredient)
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
    RecipeListView()
}
