//
//  PlannerViewModel.swift
//  RecipeBB
//
//  Created by Jay Hui on 12/08/2026.
//

import SwiftUI
import SwiftData

/// One cell of the month grid.
struct MonthGridDay: Identifiable, Hashable {
    /// The `CalendarDay` key. Unique across the whole grid *including* the days
    /// borrowed from the neighbouring months, which is why the id can't be the
    /// day number — a grid routinely shows "1" twice (Jan 29–31, Feb 1–28,
    /// Mar 1–2) and duplicate `ForEach` ids silently drop cells.
    var id: Int { day.key }
    let day: CalendarDay
    /// From `Calendar.current`, so a non-Gregorian device shows its own numbering.
    let number: Int
    let isInMonth: Bool
    /// Full localized date, for the cell's accessibility label. Built from the
    /// cell's `Date` via `Calendar.current`, never from `day.year/month/day`.
    let accessibilityDate: String
}

struct MonthGrid {
    let title: String            // "August 2026" / "2026年8月"
    let weekdaySymbols: [String] // rotated for Calendar.current.firstWeekday
    let days: [MonthGridDay]     // always a multiple of 7
}

/// What a day cell draws under its number.
struct DayMarks: Equatable {
    var count: Int = 0
    var slots: Set<MealSlot> = []
}

/// One meal-slot group within the selected day.
struct DaySlotSection: Identifiable {
    var id: MealSlot { slot }
    let slot: MealSlot
    let entries: [MealPlanEntry]
}

@MainActor
@Observable
final class PlannerViewModel {
    private let context: ModelContext

    /// Any date inside the displayed month. Carried as a `Date` rather than a
    /// (year, month) pair so all month arithmetic stays inside `Calendar`: no
    /// leap years, eras or non-Gregorian month lengths to special-case.
    var monthAnchor: Date = Date()
    var selected: CalendarDay = .today()

    var showingEntryForm = false
    var editingEntry: MealPlanEntry?

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Month navigation

    func step(_ value: Int) {
        let calendar = Calendar.current
        guard let next = calendar.date(byAdding: .month, value: value, to: monthAnchor) else { return }
        monthAnchor = next

        // Keep the selection inside the visible month, or the entries list
        // below would still be showing a day the user can no longer see.
        guard !calendar.isDate(selected.date(), equalTo: next, toGranularity: .month) else { return }
        selected = calendar.isDate(Date(), equalTo: next, toGranularity: .month)
            ? .today()
            : CalendarDay(calendar.dateInterval(of: .month, for: next)?.start ?? next)
    }

    func goToToday() {
        monthAnchor = Date()
        selected = .today()
    }

    var isShowingCurrentMonth: Bool {
        Calendar.current.isDate(monthAnchor, equalTo: Date(), toGranularity: .month)
    }

    // MARK: - Grid

    /// Builds the 7-column month matrix for the month containing `anchor`.
    ///
    /// Not cached: writing a cache property during `body` would re-invalidate
    /// the view and loop. It's ~42 formatter calls per rebuild, and `body` only
    /// re-runs on month step, day selection and entry CRUD.
    func monthGrid(for anchor: Date, calendar: Calendar = .current) -> MonthGrid {
        guard let interval = calendar.dateInterval(of: .month, for: anchor),
              let dayCount = calendar.range(of: .day, in: .month, for: anchor)?.count
        else { return MonthGrid(title: "", weekdaySymbols: [], days: []) }

        // Cells of the previous month shown before the 1st. `firstWeekday` is
        // 1 in en_US (Sunday) and 2 in most of Europe; the modulo handles both.
        let weekdayOfFirst = calendar.component(.weekday, from: interval.start)
        let leading = (weekdayOfFirst - calendar.firstWeekday + 7) % 7

        // Whole weeks only: 4 rows (a 28-day February starting in column 1)
        // through 6.
        let rows = Int(ceil(Double(leading + dayCount) / 7.0))

        var days: [MonthGridDay] = []
        days.reserveCapacity(rows * 7)
        for offset in 0..<(rows * 7) {
            // `date(byAdding: .day:)`, never `addingTimeInterval(86_400 * n)` —
            // a DST transition inside the month would slide every later cell by
            // an hour and eventually across a day boundary.
            guard let date = calendar.date(
                byAdding: .day, value: offset - leading, to: interval.start
            ) else { continue }

            days.append(MonthGridDay(
                day: CalendarDay(date, timeZone: calendar.timeZone),
                number: calendar.component(.day, from: date),
                isInMonth: calendar.isDate(date, equalTo: anchor, toGranularity: .month),
                accessibilityDate: Self.fullDateFormatter.string(from: date)
            ))
        }

        // `veryShortWeekdaySymbols` is always indexed from Sunday, whatever
        // `firstWeekday` is, so it has to be rotated by hand.
        let symbols = calendar.veryShortWeekdaySymbols
        return MonthGrid(
            title: Self.monthYearFormatter.string(from: interval.start),
            weekdaySymbols: (0..<7).map { symbols[(calendar.firstWeekday - 1 + $0) % 7] },
            days: days
        )
    }

    /// One pass over every entry, producing the per-day marks the grid draws.
    ///
    /// Built once per render and handed to each cell as a plain value, so a
    /// cell never searches the entry array — a per-cell `entries(on:)` would be
    /// 42 linear scans of the whole store on every render.
    ///
    /// Deliberately never touches `entry.recipe`: faulting one `Recipe` per
    /// entry just to draw a dot would pull the photo-bearing recipe rows into
    /// memory behind the calendar.
    func marks(from entries: [MealPlanEntry]) -> [Int: DayMarks] {
        var marks: [Int: DayMarks] = [:]
        // Drop deleted entries before anything reads their attributes — this
        // runs on every render over a live @Query array. Same reason as
        // `RecipeListViewModel.sections(from:)`.
        for entry in entries where entry.isLive {
            var mark = marks[entry.dayKey] ?? DayMarks()
            mark.count += 1
            mark.slots.insert(entry.slot)
            marks[entry.dayKey] = mark
        }
        return marks
    }

    func entries(from all: [MealPlanEntry], on day: CalendarDay) -> [MealPlanEntry] {
        all.filter { $0.isLive && $0.dayKey == day.key }.sortedForDisplay()
    }

    /// The selected day's entries grouped into meal slots, in reading order,
    /// skipping slots with nothing in them.
    func slotSections(from all: [MealPlanEntry], on day: CalendarDay) -> [DaySlotSection] {
        let dayEntries = entries(from: all, on: day)
        return MealSlot.displayOrder.compactMap { slot in
            let matching = dayEntries.filter { $0.slot == slot }
            return matching.isEmpty ? nil : DaySlotSection(slot: slot, entries: matching)
        }
    }

    // MARK: - Mutations

    /// A blank title falls back to the linked recipe's name, so linking a
    /// recipe is enough on its own; an entry with neither is rejected.
    @discardableResult
    func addEntry(
        on day: CalendarDay,
        title: String,
        slot: MealSlot = .unspecified,
        note: String = "",
        recipe: Recipe? = nil
    ) throws -> MealPlanEntry {
        let resolvedTitle = try resolveTitle(title, recipe: recipe)

        let entry = MealPlanEntry(
            dayKey: day.key,
            title: resolvedTitle,
            slot: slot,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            recipe: recipe
        )
        context.insert(entry)
        try context.save()
        return entry
    }

    func updateEntry(
        _ entry: MealPlanEntry,
        day: CalendarDay,
        title: String,
        slot: MealSlot,
        note: String,
        recipe: Recipe?
    ) throws {
        let resolvedTitle = try resolveTitle(title, recipe: recipe)

        entry.dayKey = day.key
        entry.title = resolvedTitle
        entry.slot = slot
        entry.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.recipe = recipe
        try context.save()
    }

    func deleteEntry(_ entry: MealPlanEntry) throws {
        context.delete(entry)
        try context.save()
    }

    func move(_ entry: MealPlanEntry, to day: CalendarDay) throws {
        entry.dayKey = day.key
        try context.save()
    }

    private func resolveTitle(_ title: String, recipe: Recipe?) throws -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        // Snapshot the recipe's name so the entry still reads correctly after
        // that recipe is deleted
        if let recipe, recipe.isLive, !recipe.name.isEmpty { return recipe.name }
        throw ValidationError.emptyMealPlanTitle
    }

    // MARK: - Formatters

    /// "August 2026" / "2026年8月" — same idiom as
    /// `RecipeListViewModel.monthYearFormatter`.
    private static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("yMMMM")
        return formatter
    }()

    /// "Tuesday 11 August 2026" / "2026年8月11日火曜日" — the day cells'
    /// accessibility label and the selected-day section header.
    static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("yMMMMEEEEd")
        return formatter
    }()
}
