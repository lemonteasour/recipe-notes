//
//  RecipeDetailView.swift
//  RecipeNotes
//
//  Created by Jay Hui on 21/08/2025.
//

import SwiftUI

struct RecipeDetailView: View {
    var recipe: Recipe
    
    @State private var isShowingEdit = false
    @State private var isCookingMode = false
    
    var body: some View {
        @Environment(\.modelContext) var context
        
        VStack(alignment: .leading, spacing: 16) {
            if isCookingMode {
                RecipeDetailCookingView(recipe: recipe)
            } else {
                List {
                    if !recipe.desc.isEmpty {
                        Section("Details") {
                            Text(recipe.desc)
                        }
                    }
                    
                    Section("Ingredients") {
                        ForEach(recipe.sortedIngredients, id: \.id) { ingredientItem in
                            if let ingredient = ingredientItem as? Ingredient {
                                HStack {
                                    Text(ingredient.name)
                                    Spacer()
                                    Text(ingredient.quantity)
                                        .foregroundColor(.secondary)
                                }
                            } else if let heading = ingredientItem as? IngredientHeading {
                                Text(heading.name)
                                    .font(.headline)
                            }
                        }
                    }
                    
                    
                    Section("Steps") {
                        ForEach(recipe.sortedSteps, id: \.id) { step in
                            HStack(alignment: .top) {
                                Text("\(step.index + 1).")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 24)
                                
                                Text(step.value)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(recipe.name)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(isCookingMode ? "Normal" : "Cook") {
                    isCookingMode.toggle()
                }
                Button("Edit") {
                    isShowingEdit = true
                }
            }
        }
        .sheet(isPresented: $isShowingEdit) {
            RecipeFormView(context: context, recipeToEdit: recipe)
        }
        .onChange(of: isCookingMode) {
            UIApplication.shared.isIdleTimerDisabled = isCookingMode
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
}

#Preview {
    RecipeDetailView(recipe: PreviewData.sampleRecipeEnglish)
}
