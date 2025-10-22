//
//  ContentView.swift
//  RecipeNotes
//
//  Created by Jay Hui on 11/10/2025.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var context

    @State private var selection: Tab = .recipes

    enum Tab {
        case recipes
        case pantry
        case more
    }

    var body: some View {
        TabView(selection: $selection) {
            RecipeListView()
                .tabItem {
                    Label("Recipes", systemImage: "book.pages.fill")
                }
                .tag(Tab.recipes)

            PantryView(context: context)
                .tabItem {
                    Label("Pantry", systemImage: "carrot.fill")
                }
                .tag(Tab.pantry)

            MoreView()
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle.fill")
                }
                .tag(Tab.more)
        }
    }
}

#Preview {
    ContentView()
}
