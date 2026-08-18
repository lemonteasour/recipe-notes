//
//  TagMergeService.swift
//  RecipeBB
//
//  Created by Jay Hui on 18/08/2026.
//

import CoreData
import Foundation
import SwiftData
import os

/// Collapses duplicate tags that arrive from another device.
///
/// `RecipeFormViewModel.addTag` and `RecipeListViewModel.tags(named:)` both
/// reuse an existing tag when the name matches case-insensitively, which is the
/// whole story on a single device. Two devices offline each adding "Pasta"
/// produce two rows with two perfectly valid UUIDs; sync merges both and the
/// filter sheet shows the same chip twice. `@Attribute(.unique)` would not have
/// caught it even if CloudKit allowed one — the duplication is semantic, keyed
/// on the name, not on anything the store enforces.
@MainActor
enum TagMergeService {

    /// Merges once at launch, then again after every change that arrives from
    /// another device. Runs until cancelled — call it from a `.task` that lives
    /// as long as the app does.
    static func mergeDuplicatesOnRemoteChanges(in container: ModelContainer) async {
        mergeDuplicates(in: container.mainContext)
        for await _ in remoteChanges() {
            mergeDuplicates(in: container.mainContext)
        }
    }

    /// Merges tags whose names differ only by case, accents or surrounding
    /// whitespace into a single survivor, repointing recipes as it goes.
    /// Returns how many tags were deleted.
    @discardableResult
    static func mergeDuplicates(in context: ModelContext) -> Int {
        let tags = (try? context.fetch(FetchDescriptor<RecipeTag>())) ?? []

        var groups: [String: [RecipeTag]] = [:]
        for tag in tags where tag.isLive {
            groups[mergeKey(for: tag.name), default: []].append(tag)
        }

        var deleted = 0
        for group in groups.values where group.count > 1 {
            // The survivor is chosen by a rule every device computes the same
            // way. Both ends of a merge run this pass independently, and if
            // they disagreed about which row to keep they would each delete the
            // other's — leaving the user with no tag at all.
            let ordered = group.sorted(by: isOlder)
            let survivor = ordered[0]

            for duplicate in ordered.dropFirst() {
                // Repointed by hand rather than left to the .nullify rule, same
                // reason as `RecipeListViewModel.deleteTag`: a stale entry in
                // `Recipe.tags` is a destroyed object and reading it traps.
                for recipe in duplicate.recipeList where recipe.isLive {
                    var remaining = recipe.tagList.filter { $0.isLive && $0.id != duplicate.id }
                    if !remaining.contains(where: { $0.id == survivor.id }) {
                        remaining.append(survivor)
                    }
                    recipe.tags = remaining
                }
                context.delete(duplicate)
                deleted += 1
            }
        }

        guard deleted > 0 else { return 0 }

        do {
            try context.save()
            Logger.persistence.notice("Merged \(deleted, privacy: .public) duplicate tag(s)")
        } catch {
            Logger.persistence.error(
                "Failed to merge duplicate tags: \(String(describing: error), privacy: .public)"
            )
        }
        return deleted
    }

    /// Trimmed and folded rather than compared, so the grouping above can key a
    /// dictionary on it. `nil` locale asks for the canonical mapping — a Turkish
    /// device must not fold "I" differently from every other device, or the two
    /// would never agree on which tags are duplicates.
    private static func mergeKey(for name: String) -> String {
        name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }

    /// Oldest wins, with `id` as the tie-break — `createdAt` alone isn't enough,
    /// since two devices seeded from the same store hold identical timestamps.
    private static func isOlder(_ lhs: RecipeTag, _ rhs: RecipeTag) -> Bool {
        if lhs.createdAt != rhs.createdAt { return lhs.createdAt < rhs.createdAt }
        return lhs.id.uuidString < rhs.id.uuidString
    }

    /// Store changes made outside this process — which, once sync is on, means
    /// CloudKit imports. Yielded as bare signals: the payload only names Core
    /// Data object ids, and `Notification` isn't `Sendable`.
    ///
    /// Buffers one, so a burst of imports (a fresh install pulling a whole
    /// library) costs one merge pass after it settles rather than one per batch.
    private static func remoteChanges() -> AsyncStream<Void> {
        AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            nonisolated(unsafe) let observer = NotificationCenter.default.addObserver(
                forName: .NSPersistentStoreRemoteChange,
                object: nil,
                queue: nil
            ) { _ in
                continuation.yield()
            }
            continuation.onTermination = { _ in
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
}
