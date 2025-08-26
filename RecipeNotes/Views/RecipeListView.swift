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
    @Query(sort: \Recipe.createdAt, order: .reverse) private var recipes: [Recipe]

    @State private var showingAddForm = false

    var body: some View {
        NavigationStack {
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
            .navigationTitle(String(localized: "Recipes"))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
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

    private func deleteRecipe(at offsets: IndexSet) {
        for index in offsets {
            context.delete(recipes[index])
        }
    }
}


#Preview {
    RecipeListView()
}
