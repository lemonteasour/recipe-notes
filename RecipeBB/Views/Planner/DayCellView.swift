//
//  DayCellView.swift
//  RecipeBB
//
//  Created by Jay Hui on 12/08/2026.
//

import SwiftUI

/// One day in the month grid.
///
/// Takes only value types — `MonthGridDay` is `Hashable` and `DayMarks` is
/// `Equatable` — so SwiftUI can skip cells that haven't changed. Never hand it
/// `[MealPlanEntry]`: searching the array per cell would be 42 linear scans of
/// the whole store on every render.
struct DayCellView: View {
    let day: MonthGridDay
    let marks: DayMarks
    let isSelected: Bool
    let isToday: Bool
    let onSelect: () -> Void
    /// Owned by `MonthGridView` so the selected day's fill can travel between
    /// cells instead of blinking out of one and into another.
    let selectionNamespace: Namespace.ID

    private var dotCount: Int { min(marks.count, 3) }

    /// Capped at the 44pt tap target: seven of these share the screen width, so
    /// past that the grid stops fitting rather than getting more legible.
    @ScaledMetric(relativeTo: .callout) private var circleDiameter: CGFloat = 34

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 3) {
                // A plain number rather than `.dateTime.day()`, which would
                // render "11日" in ja and wreck the column widths. Digits still
                // localize.
                Text(day.number, format: .number.grouping(.never))
                    .font(.callout)
                    .monospacedDigit()
                    .foregroundStyle(numberColor)
                    .frame(width: min(circleDiameter, 44), height: min(circleDiameter, 44))
                    .background {
                        if isSelected {
                            // Only the fill is matched, and exactly one cell is
                            // selected, so this is always the single source for
                            // the id. The today ring deliberately isn't matched:
                            // it marks a fixed date, and sharing the id would
                            // have the two trading places.
                            //
                            // Whether the move animates is decided by the caller
                            // mutating `selected` inside `withAnimation` or not,
                            // which is where Reduce Motion is honoured.
                            Circle()
                                .fill(Color.accentColor)
                                .matchedGeometryEffect(id: "selectedDay", in: selectionNamespace)
                        } else if isToday {
                            Circle().strokeBorder(Color.accentColor, lineWidth: 1.5)
                        }
                    }

                // Fixed-height strip so day numbers keep one baseline whether
                // or not the day has entries.
                HStack(spacing: 3) {
                    ForEach(0..<dotCount, id: \.self) { _ in
                        Circle().frame(width: 4, height: 4)
                    }
                }
                .frame(height: 4)
                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
            }
            // The circle starts at 34pt; the tap target has to clear 44.
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isToday ? Text("Today, \(day.accessibilityDate)") : Text(day.accessibilityDate))
        // Automatic grammar agreement rather than a hand-written plural
        // variations block: English inflects entry/entries on its own, and
        // ja / zh-Hant need only the one counted form.
        .accessibilityValue(marks.count == 0 ? Text("No entries") : Text("^[\(marks.count) entries](inflect: true)"))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    /// Today and selected at once: the fill wins, and today-ness is carried by
    /// the accessibility label rather than by stacking a ring inside the fill.
    private var numberColor: Color {
        if isSelected { return Color(.appBackgroundElevated) }
        if isToday { return .accentColor }
        return day.isInMonth ? .primary : Color.secondary.opacity(0.5)
    }
}

#Preview {
    @Previewable @Namespace var selection
    let today = CalendarDay.today()

    return HStack(spacing: 0) {
        DayCellView(
            day: MonthGridDay(day: today, number: 11, isInMonth: true, accessibilityDate: "Tuesday 11 August 2026"),
            marks: DayMarks(count: 2, slots: [.dinner]),
            isSelected: true, isToday: true, onSelect: {}, selectionNamespace: selection
        )
        DayCellView(
            day: MonthGridDay(day: today.adding(days: 1), number: 12, isInMonth: true, accessibilityDate: "Wednesday 12 August 2026"),
            marks: DayMarks(count: 5, slots: [.breakfast, .dinner]),
            isSelected: false, isToday: true, onSelect: {}, selectionNamespace: selection
        )
        DayCellView(
            day: MonthGridDay(day: today.adding(days: 2), number: 13, isInMonth: true, accessibilityDate: "Thursday 13 August 2026"),
            marks: DayMarks(),
            isSelected: false, isToday: false, onSelect: {}, selectionNamespace: selection
        )
        DayCellView(
            day: MonthGridDay(day: today.adding(days: 3), number: 1, isInMonth: false, accessibilityDate: "Friday 1 September 2026"),
            marks: DayMarks(),
            isSelected: false, isToday: false, onSelect: {}, selectionNamespace: selection
        )
    }
    .padding()
}
