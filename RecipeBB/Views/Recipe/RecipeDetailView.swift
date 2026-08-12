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
    @State private var feedback: FeedbackSignal?

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
                        ForEach(Array(recipe.sortedSteps.enumerated()), id: \.element.id) { index, step in
                            StepRowView(step: step, number: index + 1)
                        }
                    }
                }
            }
        }
        .navigationTitle(recipe.name)
        // Long recipe names otherwise take two lines of large title, which is a
        // lot of chrome above a view you read while cooking.
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Cook is the only action in the bar — it's what you open a
                // recipe to do, and everything else can cost a tap. Favorite
                // leads the menu to match the recipe list's context menu.
                Button(isCookingMode ? "Normal" : "Cook") {
                    isCookingMode.toggle()
                }

                Menu {
                    Button(recipe.isFavorite ? "Unfavorite" : "Favorite",
                           systemImage: recipe.isFavorite ? "heart.slash" : "heart") {
                        toggleFavorite()
                    }
                    Button("Edit", systemImage: "pencil") {
                        isShowingEdit = true
                    }
                    ShareLink(item: RecipeClipboardService.exportRecipeToText(recipe)) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Label("More", systemImage: "ellipsis")
                }
            }
        }
        .sheet(isPresented: $isShowingEdit) {
            RecipeFormView(context: context, recipeToEdit: recipe)
        }
        .errorAlert($errorMessage)
        .sensoryFeedback(signal: feedback)
        .onChange(of: isCookingMode) {
            UIApplication.shared.isIdleTimerDisabled = isCookingMode
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    private func toggleFavorite() {
        recipe.isFavorite.toggle()
        do {
            try context.save()
            // Fired from the action, not from `recipe.isFavorite` — once sync
            // lands, keying off the model would buzz on remote changes too.
            feedback = .toggled
        } catch {
            errorMessage = "Failed to update recipe: \(error.localizedDescription)"
        }
    }
}

#Preview {
    RecipeDetailView(recipe: PreviewData.sampleRecipeEnglish)
}
