//
//  DayEntriesSectionView.swift
//  RecipeBB
//
//  Created by Jay Hui on 12/08/2026.
//

import SwiftUI
import SwiftData

/// The selected day's entries, grouped into meal slots.
struct DayEntriesSectionView: View {
    let day: CalendarDay
    let sections: [DaySlotSection]
    let onAdd: () -> Void
    let onEdit: (MealPlanEntry) -> Void
    let onOpenRecipe: (Recipe) -> Void
    let onDelete: (MealPlanEntry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(PlannerViewModel.fullDateFormatter.string(from: day.date()))
                    .font(.footnote)
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                Button(action: onAdd) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add to Planner")
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 6)

            if sections.isEmpty {
                ContentUnavailableView(
                    "Nothing Planned",
                    systemImage: "calendar.badge.plus",
                    description: Text("Add what you cooked, or plan ahead with the + button.")
                )
                .padding(.top, 24)
            } else {
                ForEach(sections) { section in
                    slotSection(section)
                }
            }
        }
    }

    @ViewBuilder
    private func slotSection(_ section: DaySlotSection) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // `unspecified` gets no header — an entry the user didn't slot
            // shouldn't be filed under a label they never chose.
            if section.slot != .unspecified {
                Label(section.slot.label, systemImage: section.slot.symbolName)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 6)
                    .accessibilityAddTraits(.isHeader)
            } else {
                Spacer().frame(height: 12)
            }

            VStack(spacing: 0) {
                ForEach(Array(section.entries.enumerated()), id: \.element.id) { index, entry in
                    if index > 0 {
                        Divider().padding(.leading, 20)
                    }
                    entryRow(entry)
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(28)
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private func entryRow(_ entry: MealPlanEntry) -> some View {
        // A deleted entry can outlive the delete in a @Query array; reading an
        // attribute off it would trap.
        if entry.isLive {
            let hasRecipe = entry.hasLiveRecipe

            Button {
                if hasRecipe, let recipe = entry.recipe {
                    onOpenRecipe(recipe)
                } else {
                    onEdit(entry)
                }
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.displayTitle)
                            .foregroundStyle(.primary)
                        if !entry.note.isEmpty {
                            Text(entry.note)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }

                    Spacer()

                    if hasRecipe {
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(hasRecipe ? Text("Opens the linked recipe") : Text("Edit Entry"))
            .contextMenu {
                Button("Edit") { onEdit(entry) }
                Button("Delete", systemImage: "trash", role: .destructive) { onDelete(entry) }
            }
        }
    }
}

#Preview {
    let container = PreviewData.containerWithSamples()
    let viewModel = PlannerViewModel(context: container.mainContext)
    let entries = (try? container.mainContext.fetch(FetchDescriptor<MealPlanEntry>())) ?? []
    let day = entries.first?.day ?? .today()

    return ScrollView {
        DayEntriesSectionView(
            day: day,
            sections: viewModel.slotSections(from: entries, on: day),
            onAdd: {}, onEdit: { _ in }, onOpenRecipe: { _ in }, onDelete: { _ in }
        )
    }
    .background(Color(.systemGroupedBackground))
    .modelContainer(container)
}
