//
//  RecipeListViewModel.swift
//  RecipeBB
//
//  Created by Jay Hui on 05/09/2025.
//


import SwiftUI
import SwiftData
import UIKit

enum RecipeSortOption: String, CaseIterable, Identifiable {
    case newestFirst
    case oldestFirst
    case nameAscending
    case nameDescending

    var id: Self { self }

    var label: LocalizedStringKey {
        switch self {
        case .newestFirst: "Newest first"
        case .oldestFirst: "Oldest first"
        case .nameAscending: "Name (A–Z)"
        case .nameDescending: "Name (Z–A)"
        }
    }
}

/// One section of the recipe list. `indexTitles` are the entries this section
/// contributes to the scrubber bar on the right — usually one, but a section
/// that starts a new year contributes both the year marker and its month.
struct RecipeListSection: Identifiable {
    let id: String
    let title: String
    let indexTitles: [String]
    let recipes: [Recipe]
}

/// UILocalizedIndexedCollation needs an Objective-C selector to read the
/// string it collates on, so recipe names get wrapped in this.
private final class CollationTarget: NSObject {
    @objc let collationName: String

    init(_ name: String) {
        self.collationName = name
    }
}

@MainActor
@Observable
final class RecipeListViewModel {
    private static let sortOptionKey = "recipeSortOption"
    private static let favoritesOnTopKey = "recipeFavoritesOnTop"

    private let context: ModelContext

    var searchText = ""
    var selectedIngredients: Set<String> = []
    var selectedTagIDs: Set<UUID> = []
    var ingredientSearch = ""
    var showingAddForm = false
    var showingFilterSheet = false

    var sortOption: RecipeSortOption {
        didSet { UserDefaults.standard.set(sortOption.rawValue, forKey: Self.sortOptionKey) }
    }

    var favoritesOnTop: Bool {
        didSet { UserDefaults.standard.set(favoritesOnTop, forKey: Self.favoritesOnTopKey) }
    }

    init(context: ModelContext) {
        self.context = context
        let stored = UserDefaults.standard.string(forKey: Self.sortOptionKey)
        self.sortOption = stored.flatMap(RecipeSortOption.init(rawValue:)) ?? .newestFirst
        // Defaults to on for anyone who hasn't touched the toggle
        self.favoritesOnTop = UserDefaults.standard.object(forKey: Self.favoritesOnTopKey) as? Bool ?? true
    }

    /// Return recipes filtered by search text, tags and selected ingredients,
    /// grouped into sections matching the current sort option: letter sections
    /// for name sorts, month sections for date sorts, plus an optional
    /// favorites section pinned to the top.
    func sections(from allRecipes: [Recipe]) -> [RecipeListSection] {
        // Drop deleted recipes before anything reads their attributes. This
        // runs on every render over a live @Query array, so a swipe- or bulk
        // delete can otherwise land mid-computation and fault destroyed data.
        var recipes = allRecipes
            .filter { $0.isLive && matchesFilters($0) }
            .sorted(by: isOrderedBySortOption)

        var sections: [RecipeListSection] = []
        if favoritesOnTop {
            let favorites = recipes.filter(\.isFavorite)
            if !favorites.isEmpty {
                recipes.removeAll(where: \.isFavorite)
                sections.append(RecipeListSection(
                    id: "favorites",
                    title: String(localized: "Favorites"),
                    indexTitles: ["♥"],
                    recipes: favorites
                ))
            }
        }

        switch sortOption {
        case .nameAscending, .nameDescending:
            sections += nameSections(for: recipes)
        case .newestFirst, .oldestFirst:
            sections += dateSections(for: recipes)
        }
        return sections
    }

    private func matchesFilters(_ recipe: Recipe) -> Bool {
        let matchesNameOrDesc =
            searchText.isEmpty ||
            recipe.name.localizedStandardContains(searchText) ||
            recipe.desc.localizedStandardContains(searchText)

        let matchesTags =
            selectedTagIDs.isEmpty ||
            recipe.tagList.contains { $0.isLive && selectedTagIDs.contains($0.id) }

        let matchesIngredients =
            selectedIngredients.isEmpty ||
            recipe.ingredientList.contains { selectedIngredients.contains($0.name) }

        return matchesNameOrDesc && matchesTags && matchesIngredients
    }

    private func isOrderedBySortOption(_ a: Recipe, _ b: Recipe) -> Bool {
        switch sortOption {
        case .newestFirst:
            a.createdAt > b.createdAt
        case .oldestFirst:
            a.createdAt < b.createdAt
        case .nameAscending:
            a.name.localizedStandardCompare(b.name) == .orderedAscending
        case .nameDescending:
            a.name.localizedStandardCompare(b.name) == .orderedDescending
        }
    }

    /// Contacts-style letter sections using the locale's collation
    /// (A–Z# in English, kana rows in Japanese, …).
    private func nameSections(for recipes: [Recipe]) -> [RecipeListSection] {
        let collation = UILocalizedIndexedCollation.current()
        let titles = collation.sectionTitles

        var buckets = Array(repeating: [Recipe](), count: titles.count)
        for recipe in recipes {
            let index = collation.section(
                for: CollationTarget(recipe.name),
                collationStringSelector: #selector(getter: CollationTarget.collationName)
            )
            guard buckets.indices.contains(index) else { continue }
            buckets[index].append(recipe)
        }

        var order = Array(titles.indices)
        if sortOption == .nameDescending { order.reverse() }

        return order.compactMap { index in
            guard !buckets[index].isEmpty else { return nil }
            return RecipeListSection(
                id: "name-\(titles[index])",
                title: titles[index],
                indexTitles: [titles[index]],
                recipes: buckets[index]
            )
        }
    }

    /// Month sections for the date sorts. The scrubber shows a tappable "•"
    /// per month with year markers wherever the year changes (the leading year
    /// is implied). A year spanning more than 4 month sections also gets its
    /// middle month named as a mid-year landmark, reading like
    /// "• • • Mar • • • 2025 • • 2024 …".
    private func dateSections(for recipes: [Recipe]) -> [RecipeListSection] {
        let calendar = Calendar.current

        var grouped: [(key: DateComponents, recipes: [Recipe])] = []
        for recipe in recipes {
            let key = calendar.dateComponents([.year, .month], from: recipe.createdAt)
            if grouped.last?.key == key {
                grouped[grouped.count - 1].recipes.append(recipe)
            } else {
                grouped.append((key, [recipe]))
            }
        }

        // Walk the contiguous run of sections belonging to each year
        var indexTitlesPerSection = Array(repeating: [String](), count: grouped.count)
        var start = 0
        while start < grouped.count {
            let year = grouped[start].key.year
            var end = start
            while end < grouped.count, grouped[end].key.year == year { end += 1 }

            if start > 0 {
                indexTitlesPerSection[start].append("\(year ?? 0)")
            }
            let labeled = (end - start) > 4 ? start + (end - start) / 2 : nil
            for position in start..<end {
                if position == labeled,
                   let month = grouped[position].key.month,
                   Self.shortMonthSymbols.indices.contains(month - 1) {
                    indexTitlesPerSection[position].append(Self.shortMonthSymbols[month - 1])
                } else {
                    indexTitlesPerSection[position].append(Self.monthDotTitle)
                }
            }
            start = end
        }

        return grouped.enumerated().map { position, group in
            let (key, recipes) = group
            return RecipeListSection(
                id: "date-\(key.year ?? 0)-\(key.month ?? 0)",
                title: Self.monthYearFormatter.string(from: recipes[0].createdAt),
                indexTitles: indexTitlesPerSection[position],
                recipes: recipes
            )
        }
    }

    /// The unnamed-month marker in the scrubber: a bullet carrying a text
    /// variation selector. UIKit reserves a *bare* U+2022 as its own elision
    /// marker in the section index, strips those entries when measuring, then
    /// reads element 0 of what's left — so an index of nothing but bare
    /// bullets (2–4 months in one year, no favorites section) crashes
    /// -[UITableViewIndex _displayTitles] on the first layout pass. The
    /// selector renders identically and keeps us out of that path.
    static let monthDotTitle = "\u{2022}\u{FE0E}"

    /// Localized abbreviated month names ("Jul" / "7月" / "7月")
    private static let shortMonthSymbols = Calendar.current.shortMonthSymbols

    private static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("yMMMM")
        return formatter
    }()

    var hasActiveFilters: Bool {
        !selectedIngredients.isEmpty || !selectedTagIDs.isEmpty
    }

    /// Return all unique ingredients (used for filtering)
    func allIngredients(from allRecipes: [Recipe]) -> [String] {
        IngredientCatalog.normalized(allRecipes.flatMap { $0.ingredientList.map(\.name) })
    }

    /// Return ingredient names filtered by `ingredientSearch`
    func filteredIngredients(from allIngredients: [String]) -> [String] {
        if ingredientSearch.isEmpty { return allIngredients }
        return allIngredients.filter { $0.localizedStandardContains(ingredientSearch) }
    }

    /// Delete a recipe
    func deleteRecipe(_ recipe: Recipe) throws {
        context.delete(recipe)
        try context.save()
    }

    /// Toggle a recipe's favorite state
    func toggleFavorite(_ recipe: Recipe) throws {
        recipe.isFavorite.toggle()
        try context.save()
    }

    /// Toggle selection for an ingredient
    func toggleIngredient(_ ingredient: String) {
        if selectedIngredients.contains(ingredient) {
            selectedIngredients.remove(ingredient)
        } else {
            selectedIngredients.insert(ingredient)
        }
    }

    /// Toggle selection for a tag filter
    func toggleTag(_ tag: RecipeTag) {
        if selectedTagIDs.contains(tag.id) {
            selectedTagIDs.remove(tag.id)
        } else {
            selectedTagIDs.insert(tag.id)
        }
    }

    /// Resolve imported tag names to tags, reusing existing ones
    /// (case-insensitively) and creating the rest. Duplicates are dropped.
    func tags(named names: [String]) throws -> [RecipeTag] {
        var known = try context.fetch(FetchDescriptor<RecipeTag>())
        var result: [RecipeTag] = []
        for name in names {
            if let match = known.first(where: {
                $0.name.compare(name, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
            }) {
                if !result.contains(where: { $0.id == match.id }) {
                    result.append(match)
                }
            } else {
                let tag = RecipeTag(name: name)
                context.insert(tag)
                known.append(tag)
                result.append(tag)
            }
        }
        return result
    }

    /// Delete a tag everywhere (recipes keep working, they just lose the tag)
    func deleteTag(_ tag: RecipeTag) throws {
        selectedTagIDs.remove(tag.id)
        // Unlink by hand rather than trusting the .nullify rule to have run by
        // the time the next render reads Recipe.tags — a stale entry there is
        // a destroyed object, and reading its name or id traps.
        for recipe in tag.recipeList where recipe.isLive {
            recipe.tags?.removeAll { $0.id == tag.id }
        }
        context.delete(tag)
        try context.save()
    }
}
