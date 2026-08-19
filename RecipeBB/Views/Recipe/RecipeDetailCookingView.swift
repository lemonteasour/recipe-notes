//
//  RecipeDetailCookingView.swift
//  RecipeBB
//
//  Created by Jay Hui on 05/09/2025.
//

import SwiftUI

/// Read-while-you-cook layout: larger type and looser spacing than the detail
/// list, so the recipe stays legible with the phone propped up on the counter.
///
/// Ingredients and steps can be ticked off as you go. That state is deliberately
/// **not** persisted: it belongs to one session at the stove, not to the recipe,
/// and the SwiftData schema is shaped for CloudKit — adding a field to it is a
/// migration, not a design change. Leaving the screen forgets it, which is the
/// right answer for "did I already add the salt" three days later.
struct RecipeDetailCookingView: View {
    var recipe: Recipe

    /// Ids of the ingredients and steps ticked off so far. One set for both:
    /// the ids are UUIDs and can't collide, and every read is a membership test.
    @Binding var done: Set<UUID>

    @ScaledMetric(relativeTo: .title3) private var stepNumberColumn: CGFloat = 32
    @ScaledMetric(relativeTo: .title3) private var stepMarkerDiameter: CGFloat = 32

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let ingredientItems = recipe.sortedIngredientItems
        let steps = recipe.sortedSteps

        if ingredientItems.isEmpty, steps.isEmpty {
            ContentUnavailableView {
                Label {
                    Text("Nothing to Cook")
                } icon: {
                    Image(systemName: "list.bullet.rectangle")
                        .foregroundStyle(Color.accentColor)
                }
            } description: {
                Text("This recipe has no ingredients or steps yet.")
            }
        } else {
            content(ingredientItems: ingredientItems, steps: steps)
        }
    }

    /// Marked so there is always exactly one "you are here" on screen. Nil once
    /// everything is done, rather than pointing at the last step.
    private func currentStepID(in steps: [Step]) -> UUID? {
        steps.first { !done.contains($0.id) }?.id
    }

    /// Steps only — `done` also holds ticked ingredients, and counting those
    /// into "3 of 7 steps" would be nonsense.
    private func doneStepCount(of steps: [Step]) -> Int {
        steps.count(where: { done.contains($0.id) })
    }

    private func toggle(_ id: UUID) {
        withAnimation(reduceMotion ? nil : .snappy(duration: 0.2)) {
            if done.contains(id) {
                done.remove(id)
            } else {
                done.insert(id)
            }
        }
    }

    private func content(ingredientItems: [any IngredientItem], steps: [Step]) -> some View {
        let currentStep = currentStepID(in: steps)

        return ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                if !ingredientItems.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Ingredients")
                            .font(.title2).bold()
                            .accessibilityAddTraits(.isHeader)

                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(ingredientItems.enumerated()), id: \.element.id) { index, item in
                                if let heading = item as? IngredientHeading {
                                    Text(heading.name)
                                        .font(.title3).bold()
                                        .accessibilityAddTraits(.isHeader)
                                        .padding(.top, index == 0 ? 0 : 16)
                                        .padding(.bottom, 8)
                                } else if let ingredient = item as? Ingredient {
                                    if index > 0, !(ingredientItems[index - 1] is IngredientHeading) {
                                        Divider()
                                            .opacity(0.6)
                                            .padding(.horizontal, 16)
                                    }

                                    ingredientRow(ingredient)
                                }
                            }
                        }
                    }
                }

                if !steps.isEmpty {
                    VStack(alignment: .leading, spacing: 20) {
                        // Progress sits beside the heading rather than in the
                        // toolbar: the bar already carries Cook plus a menu, and
                        // a third item doesn't fit on a small phone in Japanese
                        // (the same constraint noted in `RecipeIndexedListView`).
                        HStack(alignment: .firstTextBaseline) {
                            Text("Steps")
                                .font(.title2).bold()
                                .accessibilityAddTraits(.isHeader)

                            Spacer()

                            Text("\(doneStepCount(of: steps)) of \(steps.count)")
                                .font(.subheadline)
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                                .contentTransition(.numericText())
                        }

                        // Numbered by position rather than `sortOrder`, so steps
                        // that land on a duplicate order after a sync merge still
                        // read 1, 2, 3.
                        ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                            stepRow(step, number: index + 1, isCurrent: step.id == currentStep)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
    }

    private func ingredientRow(_ ingredient: Ingredient) -> some View {
        let isDone = done.contains(ingredient.id)

        return Button {
            toggle(ingredient.id)
        } label: {
            HStack(alignment: .firstTextBaseline) {
                Text(ingredient.name)
                Spacer(minLength: 16)
                Text(ingredient.quantity)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }
            .font(.title3)
            .foregroundStyle(isDone ? Color.secondary : Color.primary)
            .opacity(isDone ? 0.5 : 1)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            // The whole row, including the gap between name and quantity — this
            // is tapped with wet hands and half an eye on a pan.
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isDone ? [.isButton, .isSelected] : .isButton)
    }

    private func stepRow(_ step: Step, number: Int, isCurrent: Bool) -> some View {
        let isDone = done.contains(step.id)

        return Button {
            toggle(step.id)
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                stepMarker(number: number, isCurrent: isCurrent, isDone: isDone)

                Text(step.value)
                    .font(.title3)
                    .lineSpacing(4)
                    .foregroundStyle(isDone ? Color.secondary : Color.primary)
                    .opacity(isDone ? 0.5 : 1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isDone ? [.isButton, .isSelected] : .isButton)
    }

    /// The frame is the same filled or not, so the text column never shifts as
    /// the marker moves down the list, and the circle is drawn in the background
    /// so the digit keeps the `.firstTextBaseline` alignment the row is built on.
    private func stepMarker(number: Int, isCurrent: Bool, isDone: Bool) -> some View {
        Text(number, format: .number)
            .font(.title3).bold()
            .monospacedDigit()
            .foregroundStyle(markerForeground(isCurrent: isCurrent, isDone: isDone))
            .frame(width: stepNumberColumn, alignment: .center)
            .background {
                if isCurrent {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: stepMarkerDiameter, height: stepMarkerDiameter)
                }
            }
    }

    private func markerForeground(isCurrent: Bool, isDone: Bool) -> Color {
        if isCurrent { return Color(.appBackgroundElevated) }
        return isDone ? Color.secondary.opacity(0.5) : .secondary
    }
}

#Preview {
    @Previewable @State var done: Set<UUID> = []
    RecipeDetailCookingView(recipe: SeedDataService.sampleRecipeEnglish, done: $done)
}
