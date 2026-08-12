//
//  PlannerViewModelTests.swift
//  RecipeBBTests
//
//  The month grid is pure arithmetic over `Calendar`, and every one of its
//  edge cases is a date the developer is unlikely to be looking at when the
//  code is written: a month that needs six rows, a leap February, a locale
//  that starts the week on Monday, and the duplicate day *numbers* a grid
//  shows whenever it borrows cells from the neighbouring months.
//

import Testing
import Foundation
import SwiftData
@testable import RecipeBB

@MainActor
struct PlannerViewModelTests {

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Recipe.self, RecipeTag.self, PantryItem.self, PantryCategory.self, MealPlanEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func makeViewModel(_ container: ModelContainer) -> PlannerViewModel {
        PlannerViewModel(context: container.mainContext)
    }

    /// Gregorian, GMT, Sunday-first — a fixed baseline so grid assertions don't
    /// depend on the machine running the tests.
    private func gridCalendar(firstWeekday: Int = 1) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "GMT")!
        calendar.locale = Locale(identifier: "en_US")
        calendar.firstWeekday = firstWeekday
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, in calendar: Calendar) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12)))
    }

    // MARK: - Grid shape

    /// Every month across five years: whole weeks, the right number of in-month
    /// days, starting at 1 and strictly consecutive throughout.
    @Test func gridFillsWholeWeeksForEveryMonth() throws {
        let container = try makeContainer()
        let viewModel = makeViewModel(container)
        let calendar = gridCalendar()

        for year in 2024...2028 {
            for month in 1...12 {
                let anchor = try date(year, month, 1, in: calendar)
                let grid = viewModel.monthGrid(for: anchor, calendar: calendar)

                #expect(grid.days.count % 7 == 0, "\(year)-\(month) is not whole weeks")
                #expect(grid.days.count >= 28 && grid.days.count <= 42)

                let inMonth = grid.days.filter(\.isInMonth)
                let expected = try #require(calendar.range(of: .day, in: .month, for: anchor)?.count)
                #expect(inMonth.count == expected, "\(year)-\(month) day count")
                #expect(inMonth.first?.number == 1)
                #expect(inMonth.last?.number == expected)

                // Cells are strictly consecutive days across the whole grid
                for (previous, next) in zip(grid.days, grid.days.dropFirst()) {
                    #expect(previous.day.adding(days: 1) == next.day)
                }
            }
        }

        withExtendedLifetime(container) {}
    }

    /// A grid routinely shows the same day *number* twice — Jan 2026 borrows
    /// Feb 1 while showing Jan 1. Ids must be day keys, or `ForEach` silently
    /// drops the duplicate cell.
    @Test func gridCellIDsAreUnique() throws {
        let container = try makeContainer()
        let viewModel = makeViewModel(container)
        let calendar = gridCalendar()

        for year in 2024...2028 {
            for month in 1...12 {
                let grid = viewModel.monthGrid(for: try date(year, month, 1, in: calendar), calendar: calendar)
                #expect(Set(grid.days.map(\.id)).count == grid.days.count, "duplicate ids in \(year)-\(month)")
            }
        }

        // And the situation itself really does occur: August 2026 starts on a
        // Saturday, so it needs six rows and borrows 1–5 September into the
        // last one — the grid shows a cell numbered "1" twice.
        let august = viewModel.monthGrid(for: try date(2026, 8, 1, in: calendar), calendar: calendar)
        #expect(august.days.count == 42)
        #expect(august.days.filter { $0.number == 1 }.count == 2)

        withExtendedLifetime(container) {}
    }

    @Test func gridRespectsFirstWeekday() throws {
        let container = try makeContainer()
        let viewModel = makeViewModel(container)

        // 1 August 2026 is a Saturday.
        let sundayFirst = gridCalendar(firstWeekday: 1)
        let sundayGrid = viewModel.monthGrid(
            for: try date(2026, 8, 1, in: sundayFirst), calendar: sundayFirst
        )
        #expect(sundayGrid.weekdaySymbols.first == "S")   // Sunday
        // Saturday is the 7th column when the week starts on Sunday
        #expect(sundayGrid.days.firstIndex(where: \.isInMonth) == 6)

        let mondayFirst = gridCalendar(firstWeekday: 2)
        let mondayGrid = viewModel.monthGrid(
            for: try date(2026, 8, 1, in: mondayFirst), calendar: mondayFirst
        )
        #expect(mondayGrid.weekdaySymbols.first == "M")   // Monday
        // Saturday is the 6th column when the week starts on Monday
        #expect(mondayGrid.days.firstIndex(where: \.isInMonth) == 5)

        #expect(sundayGrid.weekdaySymbols.count == 7)
        #expect(Set(mondayGrid.weekdaySymbols).count == Set(sundayGrid.weekdaySymbols).count)

        withExtendedLifetime(container) {}
    }

    @Test func gridHandlesLeapFebruary() throws {
        let container = try makeContainer()
        let viewModel = makeViewModel(container)
        let calendar = gridCalendar()

        let leap = viewModel.monthGrid(for: try date(2028, 2, 1, in: calendar), calendar: calendar)
        #expect(leap.days.filter(\.isInMonth).count == 29)

        let common = viewModel.monthGrid(for: try date(2026, 2, 1, in: calendar), calendar: calendar)
        #expect(common.days.filter(\.isInMonth).count == 28)

        withExtendedLifetime(container) {}
    }

    // MARK: - Marks and sections

    @Test func marksCountEntriesPerDay() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let viewModel = makeViewModel(container)

        try viewModel.addEntry(on: CalendarDay(key: 20260811), title: "Toast", slot: .breakfast)
        try viewModel.addEntry(on: CalendarDay(key: 20260811), title: "Curry", slot: .dinner)
        try viewModel.addEntry(on: CalendarDay(key: 20260811), title: "Snack")
        try viewModel.addEntry(on: CalendarDay(key: 20260812), title: "Ramen", slot: .lunch)

        let all = try context.fetch(FetchDescriptor<MealPlanEntry>())
        let marks = viewModel.marks(from: all)

        #expect(marks.count == 2)
        #expect(marks[20260811]?.count == 3)
        #expect(marks[20260811]?.slots == [.breakfast, .dinner, .unspecified])
        #expect(marks[20260812]?.count == 1)
        #expect(marks[20260813] == nil)

        withExtendedLifetime(container) {}
    }

    @Test func slotSectionsOrderBreakfastLunchDinnerThenOther() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let viewModel = makeViewModel(container)

        let day = CalendarDay(key: 20260811)
        // Inserted deliberately out of order
        try viewModel.addEntry(on: day, title: "Snack", slot: .unspecified)
        try viewModel.addEntry(on: day, title: "Curry", slot: .dinner)
        try viewModel.addEntry(on: day, title: "Toast", slot: .breakfast)
        try viewModel.addEntry(on: day, title: "Ramen", slot: .lunch)
        // A different day must not leak into the sections
        try viewModel.addEntry(on: CalendarDay(key: 20260812), title: "Elsewhere", slot: .breakfast)

        let all = try context.fetch(FetchDescriptor<MealPlanEntry>())
        let sections = viewModel.slotSections(from: all, on: day)

        #expect(sections.map(\.slot) == [.breakfast, .lunch, .dinner, .unspecified])
        #expect(sections.flatMap { $0.entries.map(\.displayTitle) } == ["Toast", "Ramen", "Curry", "Snack"])

        // Empty slots are skipped rather than rendered as blank headers
        let otherDay = viewModel.slotSections(from: all, on: CalendarDay(key: 20260812))
        #expect(otherDay.map(\.slot) == [.breakfast])

        withExtendedLifetime(container) {}
    }

    // MARK: - Mutations

    @Test func addEntryRejectsAnEmptyTitleWithNoRecipe() throws {
        let container = try makeContainer()
        let viewModel = makeViewModel(container)

        #expect(throws: ValidationError.emptyMealPlanTitle) {
            try viewModel.addEntry(on: CalendarDay(key: 20260811), title: "   ")
        }

        withExtendedLifetime(container) {}
    }

    @Test func addEntryFallsBackToTheRecipeNameWhenTheTitleIsBlank() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let viewModel = makeViewModel(container)

        let recipe = Recipe(name: "Katsu Curry", desc: "")
        context.insert(recipe)

        let entry = try viewModel.addEntry(on: CalendarDay(key: 20260811), title: "", recipe: recipe)
        #expect(entry.title == "Katsu Curry")
        #expect(entry.displayTitle == "Katsu Curry")

        // An explicit title wins over the recipe's name
        let renamed = try viewModel.addEntry(
            on: CalendarDay(key: 20260811), title: "Curry, half batch", recipe: recipe
        )
        #expect(renamed.title == "Curry, half batch")
        // ...though displayTitle still reads through to the live recipe
        #expect(renamed.displayTitle == "Katsu Curry")

        withExtendedLifetime(container) {}
    }

    @Test func entriesWithoutARecipeAreFullySupported() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let viewModel = makeViewModel(container)

        let entry = try viewModel.addEntry(
            on: CalendarDay(key: 20260811), title: "Takeout", slot: .dinner, note: "Ramen place by the station"
        )
        #expect(entry.recipe == nil)
        #expect(!entry.hasLiveRecipe)
        #expect(entry.displayTitle == "Takeout")
        #expect(entry.note == "Ramen place by the station")

        let all = try context.fetch(FetchDescriptor<MealPlanEntry>())
        #expect(viewModel.marks(from: all)[20260811]?.count == 1)

        withExtendedLifetime(container) {}
    }

    @Test func updateEntryChangesEveryFieldIncludingTheDay() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let viewModel = makeViewModel(container)

        let recipe = Recipe(name: "Gyoza", desc: "")
        context.insert(recipe)
        let entry = try viewModel.addEntry(on: CalendarDay(key: 20260811), title: "Placeholder")

        try viewModel.updateEntry(
            entry,
            day: CalendarDay(key: 20260815),
            title: "",
            slot: .lunch,
            note: "  froze half  ",
            recipe: recipe
        )

        #expect(entry.dayKey == 20260815)
        #expect(entry.slot == .lunch)
        #expect(entry.note == "froze half")
        #expect(entry.displayTitle == "Gyoza")

        withExtendedLifetime(container) {}
    }

    @Test func movingAnEntryChangesOnlyItsDay() throws {
        let container = try makeContainer()
        let viewModel = makeViewModel(container)

        let entry = try viewModel.addEntry(
            on: CalendarDay(key: 20260811), title: "Curry", slot: .dinner, note: "keep"
        )
        try viewModel.move(entry, to: CalendarDay(key: 20260901))

        #expect(entry.dayKey == 20260901)
        #expect(entry.slot == .dinner)
        #expect(entry.title == "Curry")
        #expect(entry.note == "keep")

        withExtendedLifetime(container) {}
    }

    @Test func deleteEntryRemovesItWithoutTouchingTheRecipe() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let viewModel = makeViewModel(container)

        let recipe = Recipe(name: "Ramen", desc: "")
        context.insert(recipe)
        let entry = try viewModel.addEntry(on: CalendarDay(key: 20260811), title: "", recipe: recipe)

        try viewModel.deleteEntry(entry)

        #expect(try context.fetch(FetchDescriptor<MealPlanEntry>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<Recipe>()).count == 1)

        withExtendedLifetime(container) {}
    }

    /// The whole path the storage decision protects, in one test: build the
    /// grid in a zone west of GMT, add an entry on the day the user tapped, and
    /// confirm it comes back on *that* cell — not the one before it.
    ///
    /// Runs in Los Angeles and Tokyo. The Tokyo case is the control: it passes
    /// under a naive implementation too, which is exactly why it can't be the
    /// only zone this is ever checked in.
    @Test(arguments: ["America/Los_Angeles", "Asia/Tokyo", "Pacific/Kiritimati"])
    func tappingADayFilesTheEntryOnThatSameCell(zoneName: String) throws {
        let container = try makeContainer()
        let context = container.mainContext
        let viewModel = makeViewModel(container)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: zoneName))
        calendar.locale = Locale(identifier: "en_US")

        let anchor = try date(2026, 8, 11, in: calendar)
        let grid = viewModel.monthGrid(for: anchor, calendar: calendar)

        // The cell the user taps: 11 August, as the grid itself labels it
        let tapped = try #require(grid.days.first { $0.isInMonth && $0.number == 11 })
        #expect(tapped.day.key == 20260811)

        try viewModel.addEntry(on: tapped.day, title: "Curry", slot: .dinner)

        let all = try context.fetch(FetchDescriptor<MealPlanEntry>())
        let marks = viewModel.marks(from: all)

        // The dot lands on the tapped cell and on no other
        #expect(marks[tapped.day.key]?.count == 1)
        for other in grid.days where other.id != tapped.id {
            #expect(marks[other.day.key] == nil, "entry leaked onto \(other.number) in \(zoneName)")
        }

        // And the day's own section shows it
        let sections = viewModel.slotSections(from: all, on: tapped.day)
        #expect(sections.flatMap { $0.entries.map(\.displayTitle) } == ["Curry"])

        withExtendedLifetime(container) {}
    }

    // MARK: - Month navigation

    @Test func steppingMonthsKeepsTheSelectionVisible() throws {
        let container = try makeContainer()
        let viewModel = makeViewModel(container)
        let calendar = Calendar.current

        viewModel.goToToday()
        let today = CalendarDay.today()
        #expect(viewModel.selected == today)

        // Stepping away moves the selection to the 1st of the new month
        viewModel.step(1)
        #expect(calendar.isDate(viewModel.selected.date(), equalTo: viewModel.monthAnchor, toGranularity: .month))
        #expect(viewModel.selected.day == 1)
        #expect(!viewModel.isShowingCurrentMonth)

        // Stepping back into the current month lands on today, not the 1st
        viewModel.step(-1)
        #expect(viewModel.selected == today)
        #expect(viewModel.isShowingCurrentMonth)

        withExtendedLifetime(container) {}
    }
}
