//
//  MealSlot.swift
//  RecipeBB
//
//  Created by Jay Hui on 12/08/2026.
//

import Foundation
import SwiftUI

/// Which meal an entry belongs to.
///
/// The raw values are the CloudKit wire format and are append-only: never
/// renumber a case, never reuse a number, only append. `unspecified` is 0
/// because 0 is also `MealPlanEntry.slotRaw`'s stored default — a row that
/// arrives without the field has to read as "no slot", not as "breakfast".
enum MealSlot: Int, CaseIterable, Identifiable, Hashable, Sendable {
    case unspecified = 0
    case breakfast = 1
    case lunch = 2
    case dinner = 3

    var id: Self { self }

    /// Reading order for sections and pickers. `unspecified` sorts *last* even
    /// though its raw value is 0, so ordering can't just be `rawValue` — see
    /// `displayRank`.
    static let displayOrder: [MealSlot] = [.breakfast, .lunch, .dinner, .unspecified]

    var displayRank: Int {
        Self.displayOrder.firstIndex(of: self) ?? Self.displayOrder.count
    }

    /// Matches `RecipeSortOption.label`.
    var label: LocalizedStringKey {
        switch self {
        case .breakfast: "Breakfast"
        case .lunch: "Lunch"
        case .dinner: "Dinner"
        case .unspecified: "Other"
        }
    }

    /// For accessibility labels and anywhere a `LocalizedStringKey` can't be
    /// resolved to text.
    var localizedName: String {
        switch self {
        case .breakfast: String(localized: "Breakfast")
        case .lunch: String(localized: "Lunch")
        case .dinner: String(localized: "Dinner")
        case .unspecified: String(localized: "Other")
        }
    }

    var symbolName: String {
        switch self {
        case .breakfast: "sunrise"
        case .lunch: "sun.max"
        case .dinner: "moon.stars"
        case .unspecified: "circle.dashed"
        }
    }
}
