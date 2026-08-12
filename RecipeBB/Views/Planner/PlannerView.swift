//
//  PlannerView.swift
//  RecipeBB
//
//  Created by Jay Hui on 12/08/2026.
//

import SwiftUI
import SwiftData

/// The Planner tab: a month calendar over the selected day's entries.
struct PlannerView: View {
    @State private var viewModel: PlannerViewModel

    /// Every entry, grouped in memory — the same shape as `RecipeListView`
    /// loading all recipes and calling `viewModel.sections(from:)`. A
    /// month-scoped `#Predicate` is captured when `Query` is built in `init`
    /// and can't follow month navigation without rebuilding the subtree on
    /// every step. Comfortable to ~10,000 entries (≈9 years at 3 meals/day).
    @Query(sort: [SortDescriptor(\MealPlanEntry.dayKey)])
    private var allEntries: [MealPlanEntry]

    @State private var path: [Recipe] = []
    @State private var errorMessage: String?

    init(context: ModelContext) {
        _viewModel = State(initialValue: PlannerViewModel(context: context))
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    MonthGridView(
                        grid: viewModel.monthGrid(for: viewModel.monthAnchor),
                        marks: viewModel.marks(from: allEntries),
                        selected: viewModel.selected,
                        onSelect: { viewModel.selected = $0 },
                        onStep: { direction in
                            withAnimation(.easeInOut(duration: 0.2)) { viewModel.step(direction) }
                        }
                    )
                    .padding(.top, 8)

                    DayEntriesSectionView(
                        day: viewModel.selected,
                        sections: viewModel.slotSections(from: allEntries, on: viewModel.selected),
                        onAdd: { present(nil) },
                        onEdit: { present($0) },
                        onOpenRecipe: { path.append($0) },
                        onDelete: delete
                    )

                    Spacer(minLength: 24)
                }
            }
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Today") { withAnimation(.easeInOut(duration: 0.2)) { viewModel.goToToday() } }
                        .disabled(viewModel.isShowingCurrentMonth && viewModel.selected == .today())
                }
            }
            .navigationDestination(for: Recipe.self) { RecipeDetailView(recipe: $0) }
            .errorAlert($errorMessage)
            .sheet(isPresented: $viewModel.showingEntryForm) {
                MealPlanEntryFormView(
                    viewModel: viewModel,
                    day: viewModel.selected,
                    entryToEdit: viewModel.editingEntry
                )
            }
            .navigationTitle("Planner")
        }
    }

    private func present(_ entry: MealPlanEntry?) {
        viewModel.editingEntry = entry
        viewModel.showingEntryForm = true
    }

    private func delete(_ entry: MealPlanEntry) {
        do {
            try viewModel.deleteEntry(entry)
        } catch {
            errorMessage = "Failed to delete entry: \(error.localizedDescription)"
        }
    }
}

#Preview {
    let container = PreviewData.containerWithSamples()
    return PlannerView(context: container.mainContext)
        .modelContainer(container)
}
