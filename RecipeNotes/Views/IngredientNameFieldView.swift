//
//  IngredientNameFieldView.swift
//  RecipeNotes
//
//  Created by Jay Hui on 11/10/2025.
//

import SwiftUI

struct IngredientNameFieldView: View {

    @Binding var text: String
    let suggestions: [String]

    @State private var filteredSuggestions: [String] = []
    @State private var showSuggestions = false
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 0) {
                TextField("Ingredient name", text: $text)
                    .focused($isFocused)
                    .onChange(of: text) {
                        let query = text.trimmingCharacters(in: .whitespaces)
                        if query.isEmpty {
                            showSuggestions = false
                        } else {
                            filteredSuggestions = suggestions
                                .filter { $0.localizedCaseInsensitiveContains(query) }
                                .sorted()
                                .prefix(5)
                                .map { $0 }
                            showSuggestions = !filteredSuggestions.isEmpty
                        }
                    }

                if showSuggestions {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(filteredSuggestions, id: \.self) { suggestion in
                            Button {
                                text = suggestion
                                DispatchQueue.main.async {
                                    showSuggestions = false
                                    isFocused = false
                                }
                            } label: {
                                Text(suggestion)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(8)
                            }
                            .buttonStyle(.plain)
                            Divider()
                        }
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .shadow(radius: 3)
                    .padding(.top, 4)
                }
            }
        }
    }
}
