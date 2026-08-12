//
//  RecipeLinkPickerView.swift
//  RecipeBB
//
//  Created by Jay Hui on 12/08/2026.
//

import SwiftUI
import SwiftData

/// Picks the recipe a planner entry links to, or clears the link.
///
/// Linking is never compulsory — "None" is the first row and an entry saved
/// without one keeps whatever title the user typed.
struct RecipeLinkPickerView: View {
    @Binding var selection: Recipe?

    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Recipe.name) private var recipes: [Recipe]
    @State private var searchText = ""

    private var filtered: [Recipe] {
        let live = recipes.filter(\.isLive)
        guard !searchText.isEmpty else { return live }
        return live.filter { $0.name.localizedStandardContains(searchText) }
    }

    var body: some View {
        List {
            Section {
                row(title: Text("None"), isSelected: selection == nil) {
                    selection = nil
                    dismiss()
                }
            }

            Section {
                ForEach(filtered) { recipe in
                    row(title: Text(recipe.name), isSelected: selection?.id == recipe.id) {
                        selection = recipe
                        dismiss()
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search recipes")
        .overlay {
            if filtered.isEmpty {
                if !searchText.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    ContentUnavailableView(
                        "No Recipes",
                        systemImage: "book.closed",
                        description: Text("You can still add an entry without one.")
                    )
                }
            }
        }
        .navigationTitle("Recipe")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(title: Text, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                title.foregroundStyle(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview {
    @Previewable @State var selection: Recipe?
    let container = PreviewData.containerWithSamples()
    return NavigationStack {
        RecipeLinkPickerView(selection: $selection)
    }
    .modelContainer(container)
}
