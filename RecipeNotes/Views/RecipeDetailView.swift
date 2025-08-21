//
//  RecipeDetailView.swift
//  RecipeNotes
//
//  Created by Jay Hui on 21/08/2025.
//


import SwiftUI

struct RecipeDetailView: View {
    @Bindable var recipe: Recipe
    @State private var cookingMode = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if cookingMode {
                ScrollView {
                    Text("Ingredients")
                        .font(.title2).bold()
                    ForEach(recipe.ingredients, id: \.self) { item in
                        Text("• \(item)")
                    }
                    
                    Text("Steps")
                        .font(.title2).bold()
                        .padding(.top)
                    Text(recipe.steps)
                        .font(.body)
                        .padding(.bottom)
                }
                .padding()
            } else {
                List {
                    Section {
                        Text(recipe.desc)
                    }
                    Section("Ingredients") {
                        ForEach(recipe.ingredients, id: \.self) { item in
                            Text(item)
                        }
                    }
                    
                    Section("Steps") {
                        Text(recipe.steps)
                    }
                }
            }
        }
        .navigationTitle(recipe.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(cookingMode ? "Normal" : "Cook") {
                    cookingMode.toggle()
                }
            }
        }
    }
}

#Preview {
    let recipe = Recipe(
        title: "Title",
        desc: "Desc",
        ingredients: ["Onion", "Chicken"],
        steps: "Steps")
    RecipeDetailView(recipe: recipe)
}
