//
//  CalendarDay.swift
//  RecipeBB
//
//  Created by Jay Hui on 12/08/2026.
//

import Foundation

/// A calendar day with no time and no timezone — "11 August 2026", not an
/// instant. Encoded as `yyyyMMdd` (20260811) so it sorts chronologically as an
/// `Int` and can never be shifted by a formatter.
///
/// Why not a `Date` pinned to GMT midnight: a `Date` is an instant, so every
/// read has to remember to use a GMT calendar. One `Text(entry.date, ...)` or
/// `Calendar.current.isDateInToday(entry.date)` that forgets shows the wrong
/// day for every user west of GMT — and the *right* day in JST, where this app
/// is developed and tested, so the bug would never surface locally. Here that
/// mistake is a type error instead: there is no `Date` to hand a formatter.
///
/// The rule that falls out: **identity always from `key`, display always from
/// `date(timeZone:)` via `Calendar.current`.** Never build a user-visible string
/// out of `year` / `month` / `day` — on an Islamic or Hebrew calendar device
/// that would announce the Gregorian date while the cell shows a different one.
///
/// Every entry point takes an explicit `TimeZone` defaulting to `.current`, so
/// tests inject one instead of mutating `NSTimeZone.default` — swift-testing
/// runs cases in parallel and a process-global would race.
struct CalendarDay: Hashable, Comparable, Codable, Identifiable, Sendable {
    /// `yyyyMMdd`. Always Gregorian — see `calendar(in:)`.
    let key: Int

    var id: Int { key }

    init(key: Int) {
        self.key = key
    }

    init(_ date: Date, timeZone: TimeZone = .current) {
        let components = Self.calendar(in: timeZone)
            .dateComponents([.year, .month, .day], from: date)
        self.key = (components.year ?? 1) * 10_000
            + (components.month ?? 1) * 100
            + (components.day ?? 1)
    }

    static func today(timeZone: TimeZone = .current) -> CalendarDay {
        CalendarDay(Date(), timeZone: timeZone)
    }

    var year: Int { key / 10_000 }
    var month: Int { (key / 100) % 100 }
    var day: Int { key % 100 }

    /// `yyyyMM`, for grouping a list by month without building a `Date`.
    var monthKey: Int { key / 100 }

    /// An instant inside this day, for formatting only. Never store this.
    ///
    /// Noon, not midnight: in zones that spring forward at midnight (Santiago,
    /// historically São Paulo) local midnight doesn't exist on the transition
    /// day and `date(from:)` slides to 01:00 or to the previous day. Noon
    /// exists in every zone on every day.
    func date(timeZone: TimeZone = .current) -> Date {
        Self.calendar(in: timeZone).date(
            from: DateComponents(year: year, month: month, day: day, hour: 12)
        ) ?? Date(timeIntervalSince1970: 0)
    }

    func adding(days: Int, timeZone: TimeZone = .current) -> CalendarDay {
        let calendar = Self.calendar(in: timeZone)
        guard let shifted = calendar.date(
            byAdding: .day, value: days, to: date(timeZone: timeZone)
        ) else { return self }
        return CalendarDay(shifted, timeZone: timeZone)
    }

    static func < (lhs: CalendarDay, rhs: CalendarDay) -> Bool { lhs.key < rhs.key }

    /// Gregorian is pinned deliberately. `Calendar.current` may be Buddhist or
    /// Japanese-imperial, and taking `.year` from those would key the same day
    /// as 25690811 on one device and 20260811 on another — two rows that never
    /// group together once they sync. Only the *key* is Gregorian; the month
    /// grid and every displayed string still go through `Calendar.current`, so
    /// a user on a non-Gregorian calendar sees their own calendar.
    private static func calendar(in timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }
}
