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

    /// Ingredients and steps ticked off in cooking mode. Owned here rather than
    /// inside `RecipeDetailCookingView` so that flipping back to the normal
    /// layout and returning doesn't lose your place; leaving the screen
    /// entirely does, which is the point — see that view's note on why this is
    /// never persisted.
    @State private var doneWhileCooking: Set<UUID> = []

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Taller than the 220 it replaced, now that it carries the name too.
    private let heroHeight: CGFloat = 280

    /// Nil when no live tags remain, so a recipe whose tags were just deleted
    /// doesn't show an empty label (or an empty Details section).
    private var tagLine: String? {
        let names = recipe.sortedTags.map(\.name)
        return names.isEmpty ? nil : names.joined(separator: " · ")
    }

    var body: some View {
        // Every line below reads the recipe, and reading a destroyed object
        // traps. The screen can outlive its recipe: a bulk delete behind it
        // today, a delete arriving from another device now that sync is on.
        // Same guard as `RecipeRowView`, one screen up.
        if recipe.isLive {
            content
        } else {
            ContentUnavailableView(
                "Recipe Deleted",
                systemImage: "trash",
                description: Text("This recipe was deleted.")
            )
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    /// The photo, with the recipe's name and tags laid over it.
    ///
    /// Stretches rather than stays put when the list is pulled down — the
    /// `.visualEffect` reads this row's own frame in scroll-view space, so no
    /// `GeometryReader` wrapper and no offset preference key is involved. Only
    /// downward pull grows it; scrolling up leaves it to slide away normally.
    ///
    /// The name is repeated here even though it's already the (inline)
    /// navigation title. Over a photo it reads as a caption rather than a
    /// duplicate, and a recipe long enough to scroll still has the title in the
    /// bar once the hero is gone.
    private func photoHero(_ uiImage: UIImage) -> some View {
        Image(uiImage: uiImage)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: heroHeight)
            .clipped()
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.name)
                        .font(.title2.bold())
                    if let tagLine {
                        Text(tagLine)
                            .font(.caption)
                            .opacity(0.85)
                    }
                }
                .foregroundStyle(.white)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    // Bottom-up scrim so light photos don't swallow the text.
                    LinearGradient(
                        colors: [.black.opacity(0.7), .clear],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .padding(.top, -48)
                }
            }
            // Combined: the name is already the navigation title, so VoiceOver
            // reading it again as a separate element is noise.
            .accessibilityElement(children: .combine)
            // `heroHeight` is captured by value rather than through `self`: the
            // effect closure outlives the call, and `self` holds a SwiftData
            // model that isn't Sendable.
            .visualEffect { [heroHeight] view, proxy in
                let pull = proxy.frame(in: .scrollView).minY
                return view.scaleEffect(
                    pull > 0 ? (heroHeight + pull) / heroHeight : 1,
                    anchor: .bottom
                )
            }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isCookingMode {
                RecipeDetailCookingView(recipe: recipe, done: $doneWhileCooking)
                    .transition(.opacity)
            } else {
                List {
                    if let data = recipe.photo, let uiImage = UIImage(data: data) {
                        Section {
                            photoHero(uiImage)
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
                .listAppBackground()
                .transition(.opacity)
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
                    // The two layouts share nothing structurally, so they hard-
                    // cut without this. A crossfade is enough to say "same
                    // recipe, different view" without pretending the elements
                    // move.
                    withAnimation(reduceMotion ? nil : .smooth(duration: 0.3)) {
                        isCookingMode.toggle()
                    }
                }
                .contentTransition(.opacity)

                Menu {
                    // No symbol effect on this one: menu contents are handed to
                    // UIKit as a `UIMenu`, so SwiftUI animations never run on
                    // them. The `.toggled` haptic and the badge back on the list
                    // row are what confirm the tap.
                    Button(recipe.isFavorite ? "Unfavorite" : "Favorite",
                           systemImage: recipe.isFavorite ? "heart.slash" : "heart") {
                        toggleFavorite()
                    }
                    Button("Edit", systemImage: "pencil") {
                        isShowingEdit = true
                    }
                    ShareLink(item: RecipeTextFormat.exportRecipeToText(recipe)) {
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
    RecipeDetailView(recipe: SeedDataService.sampleRecipeEnglish)
}
