//
//  IngredientNameFieldView.swift
//  RecipeBB
//
//  Created by Jay Hui on 11/10/2025.
//

import SwiftUI

struct IngredientNameFieldView: View {

    @Binding var text: String
    let suggestions: [String]
    let excludeCurrent: Bool

    @State private var filteredSuggestions: [String] = []
    @State private var showSuggestions = false
    @State private var originalText: String = ""
    @FocusState private var isFocused: Bool

    init(text: Binding<String>, suggestions: [String], excludeCurrent: Bool = true) {
        self._text = text
        self.suggestions = suggestions
        self.excludeCurrent = excludeCurrent
        self._originalText = State(initialValue: text.wrappedValue)
    }

    var body: some View {
        TextField("Ingredient name", text: $text)
            .focused($isFocused)
            .onChange(of: text) {
                updateSuggestions()
            }
            .onChange(of: isFocused) { oldValue, newValue in
                if newValue {
                    // Field just got focus - update originalText and show suggestions if applicable
                    originalText = text.trimmingCharacters(in: .whitespaces)
                    if !originalText.isEmpty {
                        filteredSuggestions = suggestionMatches(for: originalText)
                        showSuggestions = !filteredSuggestions.isEmpty
                    }
                } else {
                    // Field lost focus - hide suggestions after delay
                    Task {
                        try? await Task.sleep(for: .milliseconds(150))
                        if !isFocused {
                            showSuggestions = false
                        }
                    }
                }
            }
            .popover(isPresented: $showSuggestions, arrowEdge: .bottom) {
                SuggestionsPopoverContent(
                    suggestions: filteredSuggestions,
                    onSelect: { suggestion in
                        text = suggestion
                        showSuggestions = false
                        isFocused = false
                    }
                )
                .presentationCompactAdaptation(.none)
            }
    }

    private func updateSuggestions() {
        let query = text.trimmingCharacters(in: .whitespaces)

        if query.isEmpty {
            showSuggestions = false
            filteredSuggestions = []
        } else if isFocused {
            // Only update suggestions if field is focused (user is actively typing)
            filteredSuggestions = suggestionMatches(for: query)
            showSuggestions = !filteredSuggestions.isEmpty
        }
    }

    /// Up to five suggestions containing `query`, excluding the field's original value.
    private func suggestionMatches(for query: String) -> [String] {
        var matches = suggestions.filter { $0.localizedCaseInsensitiveContains(query) }
        if excludeCurrent && !originalText.isEmpty {
            matches = matches.filter { $0.lowercased() != originalText.lowercased() }
        }
        return Array(matches.sorted().prefix(5))
    }
}

// MARK: - Suggestions Popover Content

struct SuggestionsPopoverContent: View {
    let suggestions: [String]
    let onSelect: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(suggestions, id: \.self) { suggestion in
                Button {
                    onSelect(suggestion)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "text.word.spacing")
                            .foregroundStyle(.secondary)
                            .font(.caption)

                        Text(suggestion)
                            .foregroundStyle(.primary)

                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if suggestion != suggestions.last {
                    Divider()
                }
            }
        }
        .frame(minWidth: 200, idealWidth: 250)
    }
}

