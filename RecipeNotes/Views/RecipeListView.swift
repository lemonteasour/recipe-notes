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
    @State private var sortOrder: SortOrder = .reverse

    var body: some View {
        NavigationStack {
            RecipeListContent(
                searchText: searchText,
                sortOrder: sortOrder,
                showingAddForm: $showingAddForm
            )
            .searchable(text: $searchText, prompt: "Search recipes")
            .navigationTitle("Recipes")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Picker("Sort", selection: $sortOrder) {
                            Text("Newest first").tag(SortOrder.reverse)
                            Text("Oldest first").tag(SortOrder.forward)
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddForm) {
                RecipeFormView()
            }
        }
    }
}

private struct RecipeListContent: View {
    @Environment(\.modelContext) private var context

    @Binding var showingAddForm: Bool
    @Query private var recipes: [Recipe]

    init(
        searchText: String,
        sortOrder: SortOrder,
        showingAddForm: Binding<Bool>
    ) {
        _recipes = Query(filter: #Predicate<Recipe> { recipe in
            // Search by name or description
            searchText.isEmpty ||
            recipe.name.localizedStandardContains(searchText) ||
            recipe.desc.localizedStandardContains(searchText)
        }, sort: \.createdAt, order: sortOrder)

        self._showingAddForm = showingAddForm
    }

    var body: some View {
        List {
            ForEach(recipes) { recipe in
                NavigationLink(value: recipe) {
                    Text(recipe.name)
                }
            }
            .onDelete(perform: deleteRecipe)
        }
        .navigationDestination(for: Recipe.self) { recipe in
            RecipeDetailView(recipe: recipe)
        }
    }

    private func deleteRecipe(at offsets: IndexSet) {
        for index in offsets {
            context.delete(recipes[index])
        }
    }
}

#Preview {
    RecipeListView()
}
