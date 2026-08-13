//
//  MonthGridView.swift
//  RecipeBB
//
//  Created by Jay Hui on 12/08/2026.
//

import SwiftUI

/// The month calendar: ‹ title › header, weekday row, and a 7-column grid.
struct MonthGridView: View {
    let grid: MonthGrid
    let marks: [Int: DayMarks]
    let selected: CalendarDay
    let onSelect: (CalendarDay) -> Void
    let onStep: (Int) -> Void

    /// Chevrons only, no swipe: a horizontal `DragGesture` on the grid fights
    /// the enclosing `ScrollView`, and doing it properly means a paged
    /// `TabView`. "Today" in the toolbar covers the long jump.
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    private var today: CalendarDay { .today() }

    var body: some View {
        VStack(spacing: 8) {
            header
            weekdayHeader
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(grid.days) { day in
                    DayCellView(
                        day: day,
                        marks: marks[day.day.key] ?? DayMarks(),
                        isSelected: day.day == selected,
                        isToday: day.day == today,
                        onSelect: { onSelect(day.day) }
                    )
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(28)
        .padding(.horizontal, 16)
    }

    private var header: some View {
        HStack {
            Button { onStep(-1) } label: {
                Image(systemName: "chevron.left").frame(width: 44, height: 44)
            }
            .accessibilityLabel("Previous month")

            Spacer()
            Text(grid.title)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            Spacer()

            Button { onStep(1) } label: {
                Image(systemName: "chevron.right").frame(width: 44, height: 44)
            }
            .accessibilityLabel("Next month")
        }
        .padding(.horizontal, 8)
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(Array(grid.weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        // "S M T W T F S" read one letter at a time is noise; every day cell
        // already announces its own weekday in full.
        .accessibilityHidden(true)
    }
}

#Preview {
    let container = SeedDataService.containerWithSamples()
    let viewModel = PlannerViewModel(context: container.mainContext)
    return MonthGridView(
        grid: viewModel.monthGrid(for: Date()),
        marks: [CalendarDay.today().key: DayMarks(count: 2, slots: [.dinner])],
        selected: .today(),
        onSelect: { _ in },
        onStep: { _ in }
    )
    .padding(.vertical)
    .background(Color(.systemGroupedBackground))
    .modelContainer(container)
}
