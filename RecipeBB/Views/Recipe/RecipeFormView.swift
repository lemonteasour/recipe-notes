//
//  RecipeFormView.swift
//  RecipeBB
//
//  Created by Jay Hui on 21/08/2025.
//

import SwiftUI
import SwiftData
import PhotosUI

struct RecipeFormView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: RecipeFormViewModel
    @State private var errorMessage: String?
    @State private var feedback: FeedbackSignal?

    init(context: ModelContext, recipeToEdit: Recipe? = nil) {
        _viewModel = State(initialValue: RecipeFormViewModel(context: context, recipeToEdit: recipeToEdit))
    }

    var body: some View {
        NavigationStack {
            RecipeFormContentView(viewModel: viewModel)
                .navigationTitle(viewModel.recipeToEdit == nil ? "New Recipe" : "Edit Recipe")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            do {
                                try viewModel.saveRecipe()
                                // Set before dismissing: the sheet animates out,
                                // so the update that plays this still happens.
                                feedback = .saved
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }
                        .disabled(viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .errorAlert($errorMessage)
                .sensoryFeedback(signal: feedback)
        }
    }
}

/// The form's focusable text fields, keyed by the row they belong to, so a
/// freshly added row can take focus without an extra tap.
enum RecipeFormField: Hashable {
    case ingredientName(UUID)
    case heading(UUID)
    case step(UUID)
}

struct RecipeFormContentView: View {
    @Bindable var viewModel: RecipeFormViewModel

    @State private var selectedPhotoItem: PhotosPickerItem?
    @FocusState private var focusedField: RecipeFormField?

    /// Capped: at the largest accessibility sizes an uncapped 100pt would scale
    /// past the width of the row and leave the name field nothing.
    @ScaledMetric private var quantityWidth: CGFloat = 100
    @ScaledMetric private var stepNumberColumn: CGFloat = 24

    var body: some View {
        let hasPhoto = viewModel.photo != nil
        Form {
            Section("Photo") {
                if let data = viewModel.photo, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .listRowInsets(EdgeInsets())
                }

                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Label(hasPhoto ? "Change photo" : "Add photo",
                          systemImage: "photo")
                }

                if hasPhoto {
                    Button("Remove photo", role: .destructive) {
                        viewModel.photo = nil
                        selectedPhotoItem = nil
                    }
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                Task { await viewModel.updatePhoto(from: newItem) }
            }

            Section("Details") {
                TextField("Recipe name", text: $viewModel.name)
                TextField("Description", text: $viewModel.desc, axis: .vertical)
            }

            Section("Tags") {
                ForEach(viewModel.allTags) { tag in
                    let isSelected = viewModel.isTagSelected(tag)
                    Button {
                        viewModel.toggleTag(tag)
                    } label: {
                        HStack {
                            Text(tag.name)
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
                }

                HStack {
                    TextField("New tag", text: $viewModel.newTagName)
                        .onSubmit(viewModel.addTag)
                    Button("Add tag", action: viewModel.addTag)
                        .disabled(viewModel.newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            Section("Ingredients") {
                ForEach($viewModel.ingredientItems) { $item in
                    if item.kind == .heading {
                        TextField("Heading", text: $item.name)
                            .font(.headline)
                            .focused($focusedField, equals: .heading(item.id))
                    } else {
                        HStack {
                            IngredientNameFieldView(
                                text: $item.name,
                                suggestions: viewModel.allIngredientNames,
                                focus: $focusedField,
                                field: .ingredientName(item.id)
                            )

                            TextField("Quantity", text: $item.quantity)
                                .frame(width: min(quantityWidth, 160))
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
                .onDelete(perform: viewModel.deleteIngredientItems)
                .onMove(perform: viewModel.moveIngredientItems)

                Button("Add ingredient") {
                    focus(on: .ingredientName(viewModel.addIngredient().id))
                }
                Button("Add heading") {
                    focus(on: .heading(viewModel.addHeading().id))
                }
            }

            Section("Steps") {
                ForEach($viewModel.steps) { $step in
                    HStack(alignment: .top) {
                        Text("\(step.sortOrder + 1).")
                            .foregroundStyle(.secondary)
                            .frame(width: stepNumberColumn)
                            // The number can't be combined into the field
                            // without making it uneditable, so it moves into
                            // the field's label instead of being read alone.
                            .accessibilityHidden(true)

                        TextField("Step", text: $step.value, axis: .vertical)
                            .focused($focusedField, equals: .step(step.id))
                            .accessibilityLabel(Text("Step \(step.sortOrder + 1)"))
                    }
                }
                .onDelete(perform: viewModel.deleteSteps)
                .onMove(perform: viewModel.moveSteps)

                Button("Add step") {
                    focus(on: .step(viewModel.addStep().id))
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    /// Focus lands a runloop late: the row is only added to the hierarchy on the
    /// update this button triggers, and a field that doesn't exist yet can't take
    /// focus.
    private func focus(on field: RecipeFormField) {
        Task { focusedField = field }
    }
}

#Preview {
    let container = SeedDataService.containerWithSamples()

    return RecipeFormView(context: container.mainContext)
        .modelContainer(container)
}

