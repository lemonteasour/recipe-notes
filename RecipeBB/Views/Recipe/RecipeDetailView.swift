//
//  RecipeDetailView.swift
//  RecipeBB
//
//  Created by Jay Hui on 21/08/2025.
//

import SwiftUI

struct RecipeDetailView: View {
    @Environment(\.modelContext) private var context

    var recipe: Recipe

    @State private var isShowingEdit = false
    @State private var isCookingMode = false
    @State private var errorMessage: String?

    /// Nil when no live tags remain, so a recipe whose tags were just deleted
    /// doesn't show an empty label (or an empty Details section).
    private var tagLine: String? {
        let names = recipe.sortedTags.map(\.name)
        return names.isEmpty ? nil : names.joined(separator: " · ")
    }

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

                    if !recipe.desc.isEmpty || tagLine != nil {
                        Section("Details") {
                            if !recipe.desc.isEmpty {
                                Text(recipe.desc)
                            }
                            if let tagLine {
                                Label(tagLine, systemImage: "tag")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    Section("Ingredients") {
                        ForEach(recipe.sortedIngredientItems, id: \.id) { item in
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
                Button {
                    recipe.isFavorite.toggle()
                    do {
                        try context.save()
                    } catch {
                        errorMessage = "Failed to update recipe: \(error.localizedDescription)"
                    }
                } label: {
                    Label(recipe.isFavorite ? "Unfavorite" : "Favorite",
                          systemImage: recipe.isFavorite ? "heart.fill" : "heart")
                }
                .tint(.pink)
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
            RecipeFormView(context: context, recipeToEdit: recipe)
        }
        .errorAlert($errorMessage)
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
