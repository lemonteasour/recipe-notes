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

/// One section of the recipe list. `indexTitle` is the entry shown in the
/// scrubber bar on the right (nil = no entry, e.g. repeated years).
struct RecipeListSection: Identifiable {
    let id: String
    let title: String
    let indexTitle: String?
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
        var recipes = allRecipes.filter(matchesFilters).sorted(by: isOrderedBySortOption)

        var sections: [RecipeListSection] = []
        if favoritesOnTop {
            let favorites = recipes.filter(\.isFavorite)
            if !favorites.isEmpty {
                recipes.removeAll(where: \.isFavorite)
                sections.append(RecipeListSection(
                    id: "favorites",
                    title: String(localized: "Favorites"),
                    indexTitle: "♥",
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
            recipe.tags.contains { selectedTagIDs.contains($0.id) }

        let matchesIngredients =
            selectedIngredients.isEmpty ||
            recipe.ingredients.contains { selectedIngredients.contains($0.name) }

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
            buckets[index].append(recipe)
        }

        var order = Array(titles.indices)
        if sortOption == .nameDescending { order.reverse() }

        return order.compactMap { index in
            guard !buckets[index].isEmpty else { return nil }
            return RecipeListSection(
                id: "name-\(titles[index])",
                title: titles[index],
                indexTitle: titles[index],
                recipes: buckets[index]
            )
        }
    }

    /// Month sections for the date sorts; the scrubber indexes years, so only
    /// the first section of each year gets an index entry.
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

        var lastYear: Int?
        return grouped.map { key, recipes in
            let year = key.year ?? 0
            let indexTitle = year != lastYear ? "\(year)" : nil
            lastYear = year
            return RecipeListSection(
                id: "date-\(year)-\(key.month ?? 0)",
                title: Self.monthYearFormatter.string(from: recipes[0].createdAt),
                indexTitle: indexTitle,
                recipes: recipes
            )
        }
    }

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
        IngredientCatalog.normalized(allRecipes.flatMap { $0.ingredients.map(\.name) })
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
        context.delete(tag)
        try context.save()
    }
}
