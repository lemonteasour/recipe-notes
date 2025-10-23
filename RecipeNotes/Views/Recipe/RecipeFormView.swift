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
    
    @StateObject private var viewModel: RecipeFormViewModel
    
    init(context: ModelContext, recipeToEdit: Recipe? = nil) {
        _viewModel = StateObject(wrappedValue: RecipeFormViewModel(context: context, recipeToEdit: recipeToEdit))
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
            .navigationTitle(viewModel.recipeToEdit == nil ? "New Recipe" : "Edit Recipe")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        do {
                            try viewModel.saveRecipe()
                            dismiss()
                        } catch {
                            errorMessage = error.localizedDescription
                            showingError = true
                        }
                    }
                    .disabled(viewModel.name.isEmpty)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
}

#Preview {
    let container = PreviewData.containerWithSamples()
    
    return RecipeFormView(context: container.mainContext)
        .modelContainer(container)
}

