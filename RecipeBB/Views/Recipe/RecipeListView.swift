//
//  RecipeListView.swift
//  RecipeBB
//
//  Created by Jay Hui on 21/08/2025.
//

import SwiftUI
import SwiftData
import UIKit

struct RecipeListView: View {
    @Environment(\.modelContext) private var context
    @Environment(RecipeListViewModel.self) private var viewModel

    @Query(sort: \Recipe.createdAt, order: .reverse)
    private var allRecipes: [Recipe]

    @State private var path: [Recipe] = []
    @State private var showImportError = false
    @State private var errorMessage: String?
    @State private var feedback: FeedbackSignal?
    /// The recipe the "Add to Planner" context-menu action was invoked on.
    @State private var plannerRecipe: Recipe?

    var body: some View {
        @Bindable var viewModel = viewModel
        let sections = viewModel.sections(from: allRecipes)
        NavigationStack(path: $path) {
            // The empty state sits outside the `ignoresSafeArea`, so it centres
            // in the visible area rather than behind the tab bar.
            ZStack {
                RecipeIndexedListView(
                    sections: sections,
                    onSelect: { recipe in
                        path.append(recipe)
                    },
                    onToggleFavorite: { recipe in
                        do {
                            try viewModel.toggleFavorite(recipe)
                            feedback = .toggled
                        } catch {
                            errorMessage = "Failed to update recipe: \(error.localizedDescription)"
                        }
                    },
                    onDelete: { recipe in
                        do {
                            try viewModel.deleteRecipe(recipe)
                            feedback = .deleted
                        } catch {
                            errorMessage = "Failed to delete recipe: \(error.localizedDescription)"
                        }
                    },
                    // Presents the form here rather than switching to the
                    // Planner tab — the two tabs are independent navigation
                    // stacks and being yanked across is disorienting.
                    onAddToPlanner: { recipe in
                        plannerRecipe = recipe
                    }
                )
                .ignoresSafeArea(edges: .bottom)

                if sections.isEmpty {
                    emptyState
                }
            }
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe)
            }
            .navigationTitle("Recipes")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showingAddForm = true
                    } label: {
                        Label("New Recipe", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        viewModel.showingFilterSheet = true
                    } label: {
                        Label("Filter", systemImage: viewModel.hasActiveFilters
                              ? "line.3.horizontal.decrease.circle.fill"
                              : "line.3.horizontal.decrease")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Picker("Sort", selection: $viewModel.sortOption) {
                            ForEach(RecipeSortOption.allCases) { option in
                                Text(option.label).tag(option)
                            }
                        }
                        Divider()
                        Toggle(isOn: $viewModel.favoritesOnTop) {
                            Label("Favorites on top", systemImage: "heart")
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        importRecipeFromClipboard()
                    } label: {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddForm) {
                RecipeFormView(context: context)
            }
            .sheet(isPresented: $viewModel.showingFilterSheet) {
                RecipeFilterView(ingredients: viewModel.allIngredients(from: allRecipes))
                    .environment(viewModel)
            }
            .sheet(item: $plannerRecipe) { recipe in
                MealPlanEntryFormView(
                    viewModel: PlannerViewModel(context: context),
                    day: .today(),
                    prefilledRecipe: recipe
                )
            }
            .searchable(text: $viewModel.searchText, prompt: "Search recipes")
            .alert("Import Error", isPresented: $showImportError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Could not import recipe. Please make sure you have copied valid recipe text.")
            }
            // Its own alert rather than `errorAlert`, so it needs its own hook.
            .sensoryFeedback(trigger: showImportError) { _, shown in shown ? .error : nil }
            .errorAlert($errorMessage)
            .sensoryFeedback(signal: feedback)
        }
    }

    /// Why the list is blank: an unmatched search, filters that exclude
    /// everything, or no recipes at all.
    ///
    /// The last two offer the way out as a button rather than describing where
    /// the toolbar button is — the old copy ("with the + button") was the app
    /// narrating its own chrome, and it needed re-translating every time the
    /// toolbar moved.
    @ViewBuilder
    private var emptyState: some View {
        if !viewModel.searchText.isEmpty {
            ContentUnavailableView.search(text: viewModel.searchText)
        } else if viewModel.hasActiveFilters {
            ContentUnavailableView {
                // Icon tinted, title left alone: amber is legible as a glyph but
                // not as body-weight text on the warm background.
                Label {
                    Text("Nothing Matches")
                } icon: {
                    Image(systemName: "line.3.horizontal.decrease")
                        .foregroundStyle(Color.accentColor)
                }
            } description: {
                Text("No recipes match the filters you've chosen.")
            } actions: {
                Button("Clear filters") {
                    viewModel.selectedIngredients.removeAll()
                    viewModel.selectedTagIDs.removeAll()
                }
                .buttonStyle(.borderedProminent)
            }
        } else {
            ContentUnavailableView {
                Label {
                    Text("Nothing Cooking Yet")
                } icon: {
                    Image(systemName: "book.closed")
                        .foregroundStyle(Color.accentColor)
                }
            } description: {
                Text("Write down a recipe you make often, or paste one you've copied from somewhere else.")
            } actions: {
                Button("New Recipe") { viewModel.showingAddForm = true }
                    .buttonStyle(.borderedProminent)
                Button("Paste a recipe") { importRecipeFromClipboard() }
            }
        }
    }

    private func importRecipeFromClipboard() {
        guard let clipboardText = UIPasteboard.general.string else {
            showImportError = true
            return
        }

        guard let imported = RecipeTextFormat.importRecipeFromText(clipboardText) else {
            showImportError = true
            return
        }

        context.insert(imported.recipe)
        do {
            imported.recipe.tags = try viewModel.tags(named: imported.tagNames)
            try context.save()
            feedback = .added
        } catch {
            errorMessage = "Failed to save recipe: \(error.localizedDescription)"
        }
    }
}

#Preview {
    let container = SeedDataService.containerWithSamples()
    let viewModel = RecipeListViewModel(context: container.mainContext)

    return RecipeListView()
        .environment(viewModel)
        .modelContainer(container)
}
