//
//  RecipeIndexedListView.swift
//  RecipeBB
//
//  Created by Jay Hui on 12/07/2026.
//

import SwiftUI
import UIKit

/// A UITableView-backed recipe list with a Contacts-style section index bar
/// on the trailing edge. SwiftUI's List has no section index support, which
/// is the whole reason this drops down to UIKit.
struct RecipeIndexedListView: UIViewRepresentable {
    let sections: [RecipeListSection]
    let onSelect: (Recipe) -> Void
    let onToggleFavorite: (Recipe) -> Void
    let onDelete: (Recipe) -> Void
    let onAddToPlanner: (Recipe) -> Void

    func makeUIView(context: Context) -> UITableView {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = context.coordinator
        tableView.keyboardDismissMode = .interactive
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Coordinator.cellIdentifier)
        context.coordinator.configureDataSource(for: tableView)
        return tableView
    }

    func updateUIView(_ tableView: UITableView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.apply(sections: sections, animated: !context.transaction.disablesAnimations)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    @MainActor
    final class Coordinator: NSObject, UITableViewDelegate {
        static let cellIdentifier = "RecipeCell"

        var parent: RecipeIndexedListView
        fileprivate var sections: [RecipeListSection] = []
        /// Entries in the index bar, and the table section each one jumps to
        fileprivate var indexTitles: [String] = []
        fileprivate var indexTargets: [Int] = []
        private var recipesByID: [UUID: Recipe] = [:]
        private var dataSource: DataSource?
        private weak var tableView: UITableView?

        init(parent: RecipeIndexedListView) {
            self.parent = parent
        }

        func configureDataSource(for tableView: UITableView) {
            self.tableView = tableView
            let dataSource = DataSource(tableView: tableView) { [weak self] tableView, indexPath, recipeID in
                let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellIdentifier, for: indexPath)
                guard let recipe = self?.recipesByID[recipeID] else { return cell }
                cell.contentConfiguration = UIHostingConfiguration {
                    RecipeRowView(recipe: recipe)
                }
                cell.accessoryType = .disclosureIndicator
                return cell
            }
            dataSource.coordinator = self
            dataSource.defaultRowAnimation = .fade
            self.dataSource = dataSource
        }

        func apply(sections: [RecipeListSection], animated: Bool) {
            self.sections = sections
            indexTitles = []
            indexTargets = []
            for (index, section) in sections.enumerated() {
                for title in section.indexTitles {
                    indexTitles.append(title)
                    indexTargets.append(index)
                }
            }
            recipesByID = Dictionary(
                sections.flatMap { $0.recipes.map { ($0.id, $0) } },
                uniquingKeysWith: { first, _ in first }
            )

            var snapshot = NSDiffableDataSourceSnapshot<String, UUID>()
            snapshot.appendSections(sections.map(\.id))
            for section in sections {
                snapshot.appendItems(section.recipes.map(\.id), toSection: section.id)
            }
            // Surviving rows may still have changed (favorite heart, tags, name)
            snapshot.reconfigureItems(snapshot.itemIdentifiers)
            dataSource?.apply(snapshot, animatingDifferences: animated)
            // Batch updates don't re-query sectionIndexTitles; only an explicit
            // reload refreshes the scrubber after sort/filter changes
            tableView?.reloadSectionIndexTitles()
        }

        private func recipe(at indexPath: IndexPath) -> Recipe? {
            guard let id = dataSource?.itemIdentifier(for: indexPath) else { return nil }
            return recipesByID[id]
        }

        // MARK: - UITableViewDelegate
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
            guard let recipe = recipe(at: indexPath) else { return }
            parent.onSelect(recipe)
        }

        func tableView(
            _ tableView: UITableView,
            leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath
        ) -> UISwipeActionsConfiguration? {
            guard let recipe = recipe(at: indexPath) else { return nil }
            let action = UIContextualAction(
                style: .normal,
                title: recipe.isFavorite ? String(localized: "Unfavorite") : String(localized: "Favorite")
            ) { [weak self] _, _, completion in
                self?.parent.onToggleFavorite(recipe)
                completion(true)
            }
            action.image = UIImage(systemName: recipe.isFavorite ? "heart.slash" : "heart")
            action.backgroundColor = .systemPink
            return UISwipeActionsConfiguration(actions: [action])
        }

        func tableView(
            _ tableView: UITableView,
            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
        ) -> UISwipeActionsConfiguration? {
            guard let recipe = recipe(at: indexPath) else { return nil }
            let action = UIContextualAction(
                style: .destructive,
                title: String(localized: "Delete")
            ) { [weak self] _, _, completion in
                self?.parent.onDelete(recipe)
                completion(true)
            }
            action.image = UIImage(systemName: "trash")
            return UISwipeActionsConfiguration(actions: [action])
        }

        func tableView(
            _ tableView: UITableView,
            contextMenuConfigurationForRowAt indexPath: IndexPath,
            point: CGPoint
        ) -> UIContextMenuConfiguration? {
            guard let recipe = recipe(at: indexPath), recipe.isLive else { return nil }
            // The id round-trips through the configuration so the commit
            // handler can resolve the recipe without capturing a model that
            // may have been deleted while the menu was open.
            return UIContextMenuConfiguration(identifier: recipe.id.uuidString as NSString) {
                Self.previewController(for: recipe, in: tableView)
            } actionProvider: { [weak self] _ in
                self?.previewMenu(for: recipe)
            }
        }

        func tableView(
            _ tableView: UITableView,
            willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration,
            animator: UIContextMenuInteractionCommitAnimating
        ) {
            guard let identifier = configuration.identifier as? String,
                  let id = UUID(uuidString: identifier) else { return }
            animator.addCompletion { [weak self] in
                guard let recipe = self?.recipesByID[id], recipe.isLive else { return }
                self?.parent.onSelect(recipe)
            }
        }

        private static func previewController(
            for recipe: Recipe,
            in tableView: UITableView
        ) -> UIViewController {
            let controller = UIHostingController(rootView: RecipePreviewView(recipe: recipe))
            let width = tableView.bounds.width
            let maxHeight = tableView.bounds.height * 0.7
            let idealHeight = RecipePreviewView.idealHeight(for: recipe, width: width)
            controller.preferredContentSize = CGSize(
                width: width,
                height: min(max(idealHeight, 60), maxHeight)
            )
            return controller
        }

        private func previewMenu(for recipe: Recipe) -> UIMenu {
            let favorite = UIAction(
                title: recipe.isFavorite ? String(localized: "Unfavorite") : String(localized: "Favorite"),
                image: UIImage(systemName: recipe.isFavorite ? "heart.slash" : "heart")
            ) { [weak self] _ in
                self?.parent.onToggleFavorite(recipe)
            }
            // Lives here rather than in RecipeDetailView's toolbar, which
            // already carries four actions and can't take a fifth on a small
            // phone in Japanese.
            let plan = UIAction(
                title: String(localized: "Add to Planner"),
                image: UIImage(systemName: "calendar.badge.plus")
            ) { [weak self] _ in
                self?.parent.onAddToPlanner(recipe)
            }
            let delete = UIAction(
                title: String(localized: "Delete"),
                image: UIImage(systemName: "trash"),
                attributes: .destructive
            ) { [weak self] _ in
                self?.parent.onDelete(recipe)
            }
            return UIMenu(children: [favorite, plan, delete])
        }
    }

    /// Diffable data source subclass so section headers and the index bar can
    /// be provided (they are data source, not delegate, callbacks).
    private final class DataSource: UITableViewDiffableDataSource<String, UUID> {
        weak var coordinator: Coordinator?

        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            guard let sections = coordinator?.sections, sections.indices.contains(section) else { return nil }
            return sections[section].title
        }

        override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
            let titles = coordinator?.indexTitles ?? []
            // A one-entry scrubber is noise, not navigation
            return titles.count > 1 ? titles : nil
        }

        override func tableView(
            _ tableView: UITableView,
            sectionForSectionIndexTitle title: String,
            at index: Int
        ) -> Int {
            guard let targets = coordinator?.indexTargets, targets.indices.contains(index) else { return 0 }
            return targets[index]
        }
    }
}

struct RecipeRowView: View {
    let recipe: Recipe

    var body: some View {
        // A cell can re-render for a recipe deleted out from under it (bulk
        // deletes, debug reset); touching attributes then faults destroyed
        // backing data and crashes, so render a placeholder instead.
        if recipe.isLive {
            content
        } else {
            Color.clear.frame(height: 48)
        }
    }

    /// Nil when there's nothing live to show, so a recipe whose only tags were
    /// just deleted doesn't render an empty line.
    private var tagLine: String? {
        let names = recipe.sortedTags.map(\.name)
        return names.isEmpty ? nil : names.joined(separator: " · ")
    }

    private var content: some View {
        HStack(spacing: 12) {
            if let data = recipe.photo, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(recipe.name)
                if let tagLine {
                    Text(tagLine)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            if recipe.isFavorite {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.pink)
                    .imageScale(.small)
                    // The existing "Favorite" key is the action in the context
                    // menu (ja お気に入りに追加); a badge is state, not an offer.
                    .accessibilityLabel("Favorited")
            }
        }
    }
}
