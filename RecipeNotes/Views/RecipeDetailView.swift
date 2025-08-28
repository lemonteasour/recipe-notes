//
//  RecipeDetailView.swift
//  RecipeNotes
//
//  Created by Jay Hui on 21/08/2025.
//


import SwiftUI

struct RecipeDetailView: View {
    @Bindable var recipe: Recipe

    @State private var showEdit = false
    @State private var cookingMode = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if cookingMode {
                ScrollView {
                    Text("Ingredients")
                        .font(.title2).bold()

                    ForEach(recipe.ingredients) { ingredient in
                        HStack {
                            Text(ingredient.name)
                            Spacer()
                            Text(ingredient.quantity)
                                .foregroundColor(.secondary)
                        }
                        .font(.body)
                    }

                    Text("Steps")
                        .font(.title2).bold()

                    ForEach(recipe.steps.indices, id: \.self) { index in
                        HStack(alignment: .top) {
                            Text("\(index + 1).")
                                .foregroundStyle(.secondary)
                                .frame(width: 24)

                            Text(recipe.steps[index].value)
                        }
                    }
                }

            } else {
                List {
                    if !recipe.desc.isEmpty {
                        Section("Details") {
                            Text(recipe.desc)
                        }
                    }

                    Section("Ingredients") {
                        ForEach(recipe.ingredients) { ingredient in
                            HStack {
                                Text(ingredient.name)
                                Spacer()
                                Text(ingredient.quantity)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Section("Steps") {
                        ForEach(recipe.steps.indices, id: \.self) { index in
                            HStack(alignment: .top) {
                                Text("\(index + 1).")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 24)

                                Text(recipe.steps[index].value)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(recipe.name)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(
                    cookingMode ? "Normal" : "Cook"
                ) {
                    cookingMode.toggle()
                }
                Button("Edit") {
                    showEdit = true
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            RecipeFormView(recipeToEdit: recipe)
        }
    }
}

#Preview {
    let recipe = Recipe(
        name: "Oyakodon",
        desc: "Desc",
        ingredients: [
            Ingredient(name: "Onion", quantity: "1"),
            Ingredient(name: "Chicken", quantity: "2")
        ],
        steps: [Step(value: "Step")])
    RecipeDetailView(recipe: recipe)
}
