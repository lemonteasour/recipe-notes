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

    private var viewModelBinding: Binding<RecipeFormViewModel>? {
        guard viewModel != nil else { return nil }
        return Binding(
            get: { self.viewModel! },
            set: { self.viewModel = $0 }
        )
    }

    var body: some View {
        NavigationStack {
            if let vm = viewModelBinding {
            Form {
                Section("Details") {
                    TextField("Recipe name", text: vm.name)
                    TextField("Description", text: vm.desc, axis: .vertical)
                }

                Section("Ingredients") {
                    ForEach(vm.wrappedValue.combinedIngredientItems, id: \.id) { item in
                        if let ingredient = item as? Ingredient,
                           let binding = vm.wrappedValue.binding(for: ingredient) {
                            HStack {
                                IngredientNameFieldView(
                                    text: binding.name,
                                    suggestions: vm.wrappedValue.allIngredientNames
                                )

                                TextField("Quantity", text: binding.quantity)
                                    .frame(width: 100)
                                    .multilineTextAlignment(.trailing)
                            }
                        } else if let heading = item as? IngredientHeading,
                                  let binding = vm.wrappedValue.binding(for: heading) {
                            TextField("Heading", text: binding.name)
                                .font(.headline)
                        }
                    }
                    .onDelete(perform: vm.wrappedValue.deleteIngredientItems)
                    .onMove(perform: vm.wrappedValue.moveIngredientItems)

                    Button("Add ingredient", action: vm.wrappedValue.addIngredient)
                    Button("Add heading", action: vm.wrappedValue.addHeading)
                }

                Section("Steps") {
                    ForEach(vm.wrappedValue.sortedSteps, id: \.id) { step in
                        if let binding = vm.wrappedValue.binding(for: step) {
                            HStack(alignment: .top) {
                                Text("\(step.sortOrder + 1).")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 24)

                                TextField("Step", text: binding.value, axis: .vertical)
                            }
                        }
                    }
                    .onDelete(perform: vm.wrappedValue.deleteSteps)
                    .onMove(perform: vm.wrappedValue.moveSteps)

                    Button("Add step", action: vm.wrappedValue.addStep)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(vm.wrappedValue.recipeToEdit == nil ? "New Recipe" : "Edit Recipe")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        do {
                            try vm.wrappedValue.saveRecipe()
                            dismiss()
                        } catch {
                            errorMessage = error.localizedDescription
                            showingError = true
                        }
                    }
                    .disabled(vm.wrappedValue.name.isEmpty)
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

#Preview {
    let container = PreviewData.containerWithSamples()

    return RecipeFormView()
        .modelContainer(container)
}

