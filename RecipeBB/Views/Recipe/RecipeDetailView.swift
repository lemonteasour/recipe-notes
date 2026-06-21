//
//  RecipeDetailView.swift
//  RecipeBB
//
//  Created by Jay Hui on 21/08/2025.
//

import SwiftUI

struct RecipeDetailView: View {
    var recipe: Recipe
    
    @State private var isShowingEdit = false
    @State private var isCookingMode = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isCookingMode {
                RecipeDetailCookingView(recipe: recipe)
            } else {
                List {
                    if let data = recipe.photo, let uiImage = UIImage(data: data) {
                        Section {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 220)
                                .clipped()
                                .listRowInsets(EdgeInsets())
                        }
                    }

                    if !recipe.desc.isEmpty {
                        Section("Details") {
                            Text(recipe.desc)
                        }
                    }
                    
                    Section("Ingredients") {
                        ForEach(recipe.sortedIngredients, id: \.id) { item in
                            IngredientItemRowView(item: item)
                        }
                    }

                    Section("Steps") {
                        ForEach(recipe.sortedSteps, id: \.id) { step in
                            StepRowView(step: step)
                        }
                    }
                }
            }
        }
        .navigationTitle(recipe.name)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                ShareLink(item: RecipeClipboardService.exportRecipeToText(recipe)) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                Button(isCookingMode ? "Normal" : "Cook") {
                    isCookingMode.toggle()
                }
                Button("Edit") {
                    isShowingEdit = true
                }
            }
        }
        .sheet(isPresented: $isShowingEdit) {
            RecipeFormView(recipeToEdit: recipe)
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
