//
//  RecipeFormView.swift
//  RecipeNotes
//
//  Created by Jay Hui on 21/08/2025.
//

import SwiftUI
import SwiftData

struct RecipeFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: RecipeFormViewModel

    init(recipeToEdit: Recipe? = nil) {
        _viewModel = StateObject(wrappedValue: RecipeFormViewModel(recipeToEdit: recipeToEdit))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Recipe name", text: $viewModel.name)
                    TextField("Description", text: $viewModel.desc, axis: .vertical)
                }

                Section("Ingredients") {
                    ForEach(viewModel.combinedIngredientItems, id: \.id) { item in
                        if let ingredient = item as? Ingredient,
                           let binding = viewModel.binding(for: ingredient) {
                            HStack {
                                IngredientNameFieldView(
                                    text: binding.name,
                                    suggestions: viewModel.allIngredientNames
                                )
                                TextField("Quantity", text: binding.quantity)
                                    .frame(width: 100)
                                    .multilineTextAlignment(.trailing)
                            }
                        } else if let heading = item as? IngredientHeading,
                                  let binding = viewModel.binding(for: heading) {
                            TextField("Heading", text: binding.name)
                                .font(.headline)
                        }
                    }
                    .onDelete(perform: viewModel.deleteIngredientItems)
                    .onMove(perform: viewModel.moveIngredientItems)

                    Button("Add ingredient", action: viewModel.addIngredient)
                    Button("Add heading", action: viewModel.addHeading)
                }

                Section("Steps") {
                    ForEach(viewModel.steps.sorted(by: { $0.index < $1.index }), id: \.id) { step in
                        if let binding = $viewModel.steps.first(where: { $0.id == step.id }) {
                            HStack(alignment: .top) {
                                Text("\(step.index + 1).")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 24)

                                TextField("Step", text: binding.value, axis: .vertical)
                            }
                        }
                    }
                    .onDelete(perform: viewModel.deleteSteps)
                    .onMove(perform: viewModel.moveSteps)

                    Button("Add step", action: viewModel.addStep)
                }
            }
            .navigationTitle(viewModel.recipeToEdit == nil ? "New Recipe" : "Edit Recipe")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if viewModel.saveRecipe() { dismiss() }
                    }
                    .disabled(viewModel.name.isEmpty)
                }
            }
            .onAppear {
                viewModel.setContext(context)
                viewModel.allIngredientNames = viewModel.fetchAllIngredientNames(context: context)
            }
        }
    }
}

#Preview {
    let container = PreviewData.containerWithSamples()
    let viewModel = RecipeFormViewModel(context: container.mainContext)

    return RecipeFormView()
        .environmentObject(viewModel)
        .modelContainer(container)
}

