//
//  ContentView.swift
//  RecipeBB
//
//  Created by Jay Hui on 11/10/2025.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var context

    @State private var selection: AppTab = .recipes

    enum AppTab {
        case recipes
        case pantry
        case planner
        case more
    }

    var body: some View {
        TabView(selection: $selection) {
            Tab("Recipes", systemImage: "book.pages.fill", value: AppTab.recipes) {
                RecipeListView()
            }

            Tab("Pantry", systemImage: "carrot.fill", value: AppTab.pantry) {
                PantryView(context: context)
            }

            Tab("Planner", systemImage: "calendar", value: AppTab.planner) {
                PlannerView(context: context)
            }

            Tab("More", systemImage: "ellipsis.circle.fill", value: AppTab.more) {
                MoreView()
            }
        }
    }
}

#Preview {
    let container = SeedDataService.containerWithSamples()
    let viewModel = RecipeListViewModel(context: container.mainContext)

    return ContentView()
        .environment(viewModel)
        .modelContainer(container)
}
