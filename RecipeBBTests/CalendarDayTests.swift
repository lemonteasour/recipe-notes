//
//  CalendarDayTests.swift
//  RecipeBBTests
//
//  A planner entry's day is stored as a `yyyyMMdd` Int, not a Date, because a
//  Date is an instant and every read has to remember which calendar to use.
//  The failure mode that choice avoids is invisible from JST: an entry stored
//  as GMT midnight reads back as the *previous* day anywhere west of GMT, and
//  as the correct day on the developer's own device. These tests run the
//  conversion across the whole timezone range so that asymmetry can't hide.
//
//  Timezones are injected, never set via `NSTimeZone.default` — swift-testing
//  runs parameterized cases in parallel and a process-global would race.
//

import Testing
import Foundation
import SwiftData
@testable import RecipeBB

/// The full inhabited offset range, UTC+14 down to UTC-11. At file scope
/// because `@Test(arguments:)` evaluates its arguments outside the actor, so a
/// static on the `@MainActor` suite would be isolated away from it.
private let allZoneNames = [
    "Pacific/Kiritimati",   // UTC+14
    "Pacific/Auckland",
    "Asia/Tokyo",           // UTC+9 — where this app is developed
    "Europe/London",
    "America/New_York",
    "America/Los_Angeles",
    "Pacific/Honolulu",
    "Pacific/Pago_Pago",    // UTC-11
]

/// Zones whose DST rules are awkward: Santiago and (historically) São Paulo
/// transition at local midnight, which is why `CalendarDay.date(timeZone:)`
/// reconstructs at noon; Lord Howe shifts by 30 minutes.
private let dstZoneNames = [
    "America/Santiago", "America/Sao_Paulo", "Australia/Lord_Howe",
    "Asia/Tokyo", "America/Los_Angeles", "Europe/London",
]

@MainActor
struct CalendarDayTests {

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Recipe.self, RecipeTag.self, PantryItem.self, PantryCategory.self, MealPlanEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        )
    }

    // MARK: - Day identity

    /// 23:30 local on New Year's Eve — the instant most likely to spill across
    /// a day, a month *and* a year boundary if the wrong calendar is used.
    @Test(arguments: allZoneNames)
    func dayKeyMatchesTheLocalCalendarDay(zoneName: String) throws {
        let timeZone = try #require(TimeZone(identifier: zoneName))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let instant = try #require(calendar.date(
            from: DateComponents(year: 2026, month: 12, day: 31, hour: 23, minute: 30)
        ))

        #expect(CalendarDay(instant, timeZone: timeZone).key == 20261231)
    }

    /// The assertion the whole storage decision exists to make true: a day
    /// recorded in Tokyo is the same day when the record is read in California.
    @Test func aDayWrittenInOneZoneReadsTheSameInAnother() throws {
        let tokyo = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let losAngeles = try #require(TimeZone(identifier: "America/Los_Angeles"))

        var tokyoCalendar = Calendar(identifier: .gregorian)
        tokyoCalendar.timeZone = tokyo
        let morningInTokyo = try #require(tokyoCalendar.date(
            from: DateComponents(year: 2026, month: 8, day: 11, hour: 9)
        ))

        let day = CalendarDay(morningInTokyo, timeZone: tokyo)
        #expect(day.key == 20260811)

        // Reconstructed and read on the other side of the Pacific
        var laCalendar = Calendar(identifier: .gregorian)
        laCalendar.timeZone = losAngeles
        let asRead = CalendarDay(key: day.key).date(timeZone: losAngeles)
        #expect(laCalendar.component(.day, from: asRead) == 11)
        #expect(laCalendar.component(.month, from: asRead) == 8)
        #expect(laCalendar.component(.year, from: asRead) == 2026)
    }

    /// Two years of consecutive days, so every DST transition in each zone is
    /// crossed — including the midnight ones (Santiago, historically São Paulo)
    /// that are the reason `date(timeZone:)` reconstructs at noon.
    @Test(arguments: dstZoneNames)
    func roundTripSurvivesEveryTimeZone(zoneName: String) throws {
        let timeZone = try #require(TimeZone(identifier: zoneName))
        var day = CalendarDay(key: 20250101)

        for _ in 0..<730 {
            let rebuilt = CalendarDay(day.date(timeZone: timeZone), timeZone: timeZone)
            #expect(rebuilt == day, "round trip lost \(day.key) in \(zoneName)")
            day = day.adding(days: 1, timeZone: timeZone)
        }

        // 730 days on from 1 Jan 2025 is 1 Jan 2027
        #expect(day.key == 20270101)
    }

    /// `@Query` sorts the raw column, so Int order has to equal calendar order.
    @Test func keysSortChronologically() {
        let days = [
            CalendarDay(key: 20261231), CalendarDay(key: 20260101),
            CalendarDay(key: 20260901), CalendarDay(key: 20251231),
            CalendarDay(key: 20260110),
        ]
        #expect(days.sorted().map(\.key) == [20251231, 20260101, 20260110, 20260901, 20261231])
    }

    @Test func componentAccessorsDecomposeTheKey() {
        let day = CalendarDay(key: 20260811)
        #expect(day.year == 2026)
        #expect(day.month == 8)
        #expect(day.day == 11)
        #expect(day.monthKey == 202608)
    }

    @Test func addingDaysCrossesMonthAndYearBoundaries() {
        #expect(CalendarDay(key: 20260131).adding(days: 1).key == 20260201)
        #expect(CalendarDay(key: 20261231).adding(days: 1).key == 20270101)
        #expect(CalendarDay(key: 20260301).adding(days: -1).key == 20260228)
        // 2028 is a leap year
        #expect(CalendarDay(key: 20280301).adding(days: -1).key == 20280229)
    }

    // MARK: - MealSlot wire format

    /// The raw values are the CloudKit wire format and are append-only once the
    /// production schema is deployed. Renumbering a case would silently
    /// reinterpret every stored row.
    @Test func mealSlotRawValuesArePinned() {
        #expect(MealSlot.unspecified.rawValue == 0)
        #expect(MealSlot.breakfast.rawValue == 1)
        #expect(MealSlot.lunch.rawValue == 2)
        #expect(MealSlot.dinner.rawValue == 3)
        #expect(MealSlot.displayOrder == [.breakfast, .lunch, .dinner, .unspecified])
        // `unspecified` sorts last despite being raw value 0
        #expect(MealSlot.unspecified.displayRank == 3)
        #expect(MealSlot.breakfast.displayRank == 0)
    }

    /// A row written by a future version with a 4th slot must still materialize
    /// on this build rather than trapping.
    @Test func unknownSlotRawValueReadsAsUnspecified() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let entry = MealPlanEntry(dayKey: 20260811, title: "From the future")
        entry.slotRaw = 99
        context.insert(entry)
        try context.save()

        let fetched = try #require(try context.fetch(FetchDescriptor<MealPlanEntry>()).first)
        #expect(fetched.slotRaw == 99)
        #expect(fetched.slot == .unspecified)
    }

    // MARK: - CloudKit schema shape

    /// Mirrors `newObjectsOnCloudKitSchemaGetDistinctIDs` for the new entity:
    /// `var id: UUID = UUID()` must not collapse every row onto one default.
    @Test func newEntriesGetDistinctIDs() throws {
        let container = try makeContainer()
        let context = container.mainContext

        for index in 0..<5 {
            context.insert(MealPlanEntry(dayKey: 20260810 + index, title: "Dish \(index)"))
        }
        try context.save()

        let entries = try context.fetch(FetchDescriptor<MealPlanEntry>())
        #expect(entries.count == 5)
        #expect(Set(entries.map(\.id)).count == 5)
    }

    /// The behavioural guarantee the whole feature rests on: a recipe can be
    /// deleted without erasing the record that it was cooked.
    @Test func deletingALinkedRecipeKeepsTheEntryAndItsTitle() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let viewModel = RecipeListViewModel(context: context)

        let recipe = Recipe(name: "Carbonara", desc: "")
        context.insert(recipe)
        let entry = MealPlanEntry(dayKey: 20260811, title: recipe.name, slot: .dinner, recipe: recipe)
        context.insert(entry)
        try context.save()

        #expect(entry.displayTitle == "Carbonara")
        #expect(entry.hasLiveRecipe)

        try viewModel.deleteRecipe(recipe)

        let survivors = try context.fetch(FetchDescriptor<MealPlanEntry>())
        #expect(survivors.count == 1)
        #expect(survivors[0].recipe == nil)
        #expect(!survivors[0].hasLiveRecipe)
        #expect(survivors[0].displayTitle == "Carbonara")
    }

    /// `displayTitle` reads through to the live recipe, so a typo fix in the
    /// Recipes tab shows up in the planner rather than leaving it stale.
    @Test func renamingALinkedRecipeUpdatesTheEntryTitle() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let recipe = Recipe(name: "Spahetti Bolgnese", desc: "")
        context.insert(recipe)
        let entry = MealPlanEntry(dayKey: 20260811, title: recipe.name, recipe: recipe)
        context.insert(entry)
        try context.save()

        recipe.name = "Spaghetti Bolognese"
        try context.save()

        #expect(entry.displayTitle == "Spaghetti Bolognese")
    }

    @Test func entriesSortByMealSlotThenAgeWithAnIDTieBreak() {
        let sameInstant = Date(timeIntervalSince1970: 1_700_000_000)

        let dinner = MealPlanEntry(dayKey: 20260811, title: "Curry", slot: .dinner)
        let breakfast = MealPlanEntry(dayKey: 20260811, title: "Toast", slot: .breakfast)
        let other = MealPlanEntry(dayKey: 20260811, title: "Snack", slot: .unspecified)
        let lunch = MealPlanEntry(dayKey: 20260811, title: "Soup", slot: .lunch)
        for entry in [dinner, breakfast, other, lunch] { entry.createdAt = sameInstant }

        let sorted = [dinner, breakfast, other, lunch].sortedForDisplay()
        #expect(sorted.map(\.title) == ["Toast", "Soup", "Curry", "Snack"])

        // Same slot and same createdAt: the id tie-break has to make the order
        // stable, or the list reshuffles between renders once devices sync.
        let a = MealPlanEntry(dayKey: 20260811, title: "A", slot: .dinner)
        let b = MealPlanEntry(dayKey: 20260811, title: "B", slot: .dinner)
        a.createdAt = sameInstant
        b.createdAt = sameInstant
        let firstPass = [a, b].sortedForDisplay().map(\.title)
        let secondPass = [b, a].sortedForDisplay().map(\.title)
        #expect(firstPass == secondPass)
    }
}
