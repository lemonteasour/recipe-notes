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

    @State private var showingError = false
    @State private var errorMessage = ""

    let recipeToEdit: Recipe?

    @State private var viewModel: RecipeFormViewModel?

    init(recipeToEdit: Recipe? = nil) {
        self.recipeToEdit = recipeToEdit
    }

    var body: some View {
        NavigationStack {
            if let vm = viewModel {
                RecipeFormContentView(viewModel: vm)
                    .navigationTitle(vm.recipeToEdit == nil ? "New Recipe" : "Edit Recipe")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { dismiss() }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                do {
                                    try vm.saveRecipe()
                                    dismiss()
                                } catch {
                                    errorMessage = error.localizedDescription
                                    showingError = true
                                }
                            }
                            .disabled(vm.name.isEmpty)
                        }
                    }
                    .alert("Error", isPresented: $showingError) {
                        Button("OK", role: .cancel) { }
                    } message: {
                        Text(errorMessage)
                    }
            } else {
                ProgressView()
                    .onAppear {
                        viewModel = RecipeFormViewModel(context: context, recipeToEdit: recipeToEdit)
                    }
            }
        }
    }
}

struct RecipeFormContentView: View {
    @Bindable var viewModel: RecipeFormViewModel

    var body: some View {
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
                ForEach(viewModel.sortedSteps, id: \.id) { step in
                    if let binding = viewModel.binding(for: step) {
                        HStack(alignment: .top) {
                            Text("\(step.sortOrder + 1).")
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
        .scrollDismissesKeyboard(.interactively)
    }
}

#Preview {
    let container = PreviewData.containerWithSamples()

    return RecipeFormView()
        .modelContainer(container)
}

