//
//  RecipePreviewView.swift
//  RecipeBB
//
//  Created by Jay Hui on 07/08/2026.
//

import SwiftUI

/// Read-only summary of a recipe, shown as the context menu preview when a
/// row in the recipe list is long-pressed. Deliberately not `RecipeDetailView`:
/// a preview has no toolbar, must not present sheets, and is hosted outside the
/// view hierarchy that supplies the model context.
struct RecipePreviewView: View {
    let recipe: Recipe

    var body: some View {
        ScrollView {
            RecipePreviewContent(recipe: recipe)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    /// Height the preview wants at `width`. The context menu sizes itself to
    /// this so short recipes get no dead space, and long ones are capped by the
    /// caller and scroll instead.
    @MainActor
    static func idealHeight(for recipe: Recipe, width: CGFloat) -> CGFloat {
        let sizer = UIHostingController(rootView: RecipePreviewContent(recipe: recipe))
        let fitted = sizer.sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude))
        return fitted.height.isFinite ? fitted.height : 0
    }
}

/// The preview body without the scroll view, so it can be measured on its own.
private struct RecipePreviewContent: View {
    let recipe: Recipe

    /// Nil when no live tags remain, matching the list row and detail view.
    private var tagLine: String? {
        let names = recipe.sortedTags.map(\.name)
        return names.isEmpty ? nil : names.joined(separator: " · ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let data = recipe.photo, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .clipped()
            }

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(recipe.name)
                        .font(.title3.bold())
                    if let tagLine {
                        Label(tagLine, systemImage: "tag")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if !recipe.desc.isEmpty {
                        Text(recipe.desc)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                if !recipe.sortedIngredientItems.isEmpty {
                    section("Ingredients") {
                        ForEach(recipe.sortedIngredientItems, id: \.id) { item in
                            IngredientItemRowView(item: item)
                                .font(.subheadline)
                        }
                    }
                }

                if !recipe.sortedSteps.isEmpty {
                    section("Steps") {
                        ForEach(Array(recipe.sortedSteps.enumerated()), id: \.element.id) { index, step in
                            StepRowView(step: step, number: index + 1)
                                .font(.subheadline)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, recipe.photo == nil ? 16 : 0)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        // Both the hosted preview and `idealHeight`'s sizer are built outside
        // the app's view hierarchy, so neither inherits `RecipeBBApp`'s
        // `.fontDesign(.rounded)`. It belongs here, on the shared content,
        // rather than on the two call sites — measuring in one font and
        // rendering in another would size the menu wrong.
        .fontDesign(.rounded)
    }

    private func section<Content: View>(
        _ title: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .sectionHeaderStyle()
            content()
        }
    }
}

#Preview {
    RecipePreviewView(recipe: SeedDataService.sampleRecipeEnglish)
}
