//
//  MealPlanEntry.swift
//  RecipeBB
//
//  Created by Jay Hui on 12/08/2026.
//

import Foundation
import SwiftData

/// One dish cooked, or planned to be cooked, on one day.
///
/// Flat — one row per dish, with no `MealPlanDay` container. CloudKit forbids
/// `@Attribute(.unique)` (see the schema rules on `Recipe`), so nothing could
/// stop two offline devices each creating their own "11 August" row; on merge
/// the day would exist twice, each copy holding half the entries, and the app
/// would have to run a reconciliation pass against a store that is still
/// syncing. Flat rows have no such invariant to break: two devices adding to
/// the same day produce two entries on that day, which is the right answer.
/// Grouping is a read-side function of `dayKey`, so it is idempotent and needs
/// no merge logic.
@Model
class MealPlanEntry {
    var id: UUID = UUID()

    /// The calendar day as `yyyyMMdd`. Always go through `day` / `CalendarDay`;
    /// never format or compare this by hand.
    var dayKey: Int = 0

    /// What was cooked. Snapshotted from the recipe's name when one is linked,
    /// so the entry still reads correctly after that recipe is deleted.
    ///
    /// `displayTitle` reads through to the live recipe, so on a linked entry
    /// this drifts once the recipe is renamed — it is a fallback, not a search
    /// key. Don't write a `#Predicate` against it.
    var title: String = ""

    /// `MealSlot.rawValue`. Stored as a bare `Int` rather than the enum so the
    /// CloudKit field is an Int64 that any build can decode: a build predating
    /// a slot added later reads it as `.unspecified` instead of failing to
    /// materialize the row. The literal `0` rather than
    /// `MealSlot.unspecified.rawValue` so renumbering the enum can't silently
    /// rewrite the stored default — `mealSlotRawValuesArePinned` guards that.
    var slotRaw: Int = 0

    var note: String = ""
    var createdAt: Date = Date()

    /// Inverse is declared on `Recipe.mealPlanEntries`. Deleting a recipe only
    /// unlinks it; the entry survives with `recipe == nil` and falls back to
    /// the snapshotted `title`.
    var recipe: Recipe?

    init(
        dayKey: Int,
        title: String,
        slot: MealSlot = .unspecified,
        note: String = "",
        recipe: Recipe? = nil
    ) {
        self.id = UUID()
        self.dayKey = dayKey
        self.title = title
        self.slotRaw = slot.rawValue
        self.note = note
        self.recipe = recipe
        self.createdAt = Date()
    }

    // MARK: - Accessors

    var day: CalendarDay {
        get { CalendarDay(key: dayKey) }
        set { dayKey = newValue.key }
    }

    /// A raw value this build doesn't know reads as `.unspecified` rather than
    /// trapping, so a row written by a later version still shows up. Nothing
    /// writes the coerced value back — only the form does, and only when the
    /// user actually picks a slot.
    var slot: MealSlot {
        get { MealSlot(rawValue: slotRaw) ?? .unspecified }
        set { slotRaw = newValue.rawValue }
    }

    /// The linked recipe's current name, falling back to the snapshot.
    ///
    /// `isLive` because `.nullify` doesn't reliably clear `recipe` in the same
    /// runloop turn as the delete — the same reason `Recipe.sortedTags` filters
    /// and `RecipeListViewModel.deleteTag` unlinks by hand. Reading `.name` off
    /// a destroyed object faults backing data that no longer exists and traps.
    var displayTitle: String {
        if let recipe, recipe.isLive, !recipe.name.isEmpty { return recipe.name }
        return title
    }

    var hasLiveRecipe: Bool { recipe?.isLive == true }
}

extension Array where Element == MealPlanEntry {
    /// Entries in the order a day shows them: by meal slot, then oldest first.
    ///
    /// Ties break on `id` for the same reason `Step.sortedByOrder()` does —
    /// once devices sync, two of them adding entries offline merge field by
    /// field and can land on the same slot with the same `createdAt`; without a
    /// tie-break the list would shuffle between renders.
    func sortedForDisplay() -> [MealPlanEntry] {
        sorted { lhs, rhs in
            if lhs.slot.displayRank != rhs.slot.displayRank {
                return lhs.slot.displayRank < rhs.slot.displayRank
            }
            if lhs.createdAt != rhs.createdAt {
                return lhs.createdAt < rhs.createdAt
            }
            return lhs.id.uuidString < rhs.id.uuidString
        }
    }
}
