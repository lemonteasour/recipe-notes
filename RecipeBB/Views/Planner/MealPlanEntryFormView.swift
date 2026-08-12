//
//  MealPlanEntryFormView.swift
//  RecipeBB
//
//  Created by Jay Hui on 12/08/2026.
//

import SwiftUI
import SwiftData

/// Add or edit one planner entry.
///
/// Plain `@State` rather than a form ViewModel — five fields with no child
/// collections is `PantryView.addNewItem()` territory, not
/// `RecipeFormViewModel` territory.
struct MealPlanEntryFormView: View {
    let viewModel: PlannerViewModel
    let day: CalendarDay
    /// Nil when adding. Held across the sheet's lifetime, so every read of it
    /// checks `isLive` first — under sync a remote delete can land mid-edit.
    let entryToEdit: MealPlanEntry?
    /// Set when the form is opened from the Recipes tab's "Add to Planner"
    /// action, so the link is already made and only the day needs picking.
    let prefilledRecipe: Recipe?

    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var slot: MealSlot = .unspecified
    @State private var note = ""
    @State private var linkedRecipe: Recipe?
    @State private var selectedDay: CalendarDay
    @State private var errorMessage: String?
    @State private var feedback: FeedbackSignal?
    @State private var didLoad = false
    @FocusState private var isTitleFocused: Bool

    init(
        viewModel: PlannerViewModel,
        day: CalendarDay,
        entryToEdit: MealPlanEntry? = nil,
        prefilledRecipe: Recipe? = nil
    ) {
        self.viewModel = viewModel
        self.day = day
        self.entryToEdit = entryToEdit
        self.prefilledRecipe = prefilledRecipe
        _selectedDay = State(initialValue: entryToEdit?.day ?? day)
    }

    /// The recipe's name stands in for a blank title, so linking one is enough
    /// on its own — matching what `PlannerViewModel.addEntry` will store.
    private var titlePlaceholder: String {
        if let linkedRecipe, linkedRecipe.isLive, !linkedRecipe.name.isEmpty {
            return linkedRecipe.name
        }
        return String(localized: "What did you cook?")
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || (linkedRecipe?.isLive == true)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(titlePlaceholder, text: $title)
                        .focused($isTitleFocused)

                    NavigationLink {
                        RecipeLinkPickerView(selection: $linkedRecipe)
                    } label: {
                        LabeledContent("Recipe") {
                            if let linkedRecipe, linkedRecipe.isLive {
                                Text(linkedRecipe.name)
                            } else {
                                Text("None").foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section {
                    Picker("Meal", selection: $slot) {
                        ForEach(MealSlot.displayOrder) { option in
                            Text(option.label).tag(option)
                        }
                    }

                    DatePicker(
                        "Date",
                        selection: Binding(
                            get: { selectedDay.date() },
                            set: { selectedDay = CalendarDay($0) }
                        ),
                        displayedComponents: .date
                    )
                }

                Section {
                    TextField("Note", text: $note, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle(entryToEdit == nil ? "New Entry" : "Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(!canSave)
                }
            }
            .errorAlert($errorMessage)
            .sensoryFeedback(signal: feedback)
            .onAppear {
                // Guarded: `onAppear` fires again when the recipe picker pops,
                // and reloading would discard whatever the user just typed.
                guard !didLoad else { return }
                didLoad = true
                if let entryToEdit, entryToEdit.isLive {
                    title = entryToEdit.title
                    slot = entryToEdit.slot
                    note = entryToEdit.note
                    linkedRecipe = entryToEdit.hasLiveRecipe ? entryToEdit.recipe : nil
                    selectedDay = entryToEdit.day
                } else if let prefilledRecipe, prefilledRecipe.isLive {
                    // The title stays blank on purpose — `addEntry` falls back
                    // to the recipe's name, and the placeholder already shows it
                    linkedRecipe = prefilledRecipe
                } else {
                    isTitleFocused = true
                }
            }
        }
    }

    private func save() {
        do {
            if let entryToEdit {
                // The entry can be deleted out from under an open sheet — by a
                // swipe on another screen today, by a remote delete once sync
                // is on. Writing into a destroyed object traps.
                guard entryToEdit.isLive else {
                    errorMessage = String(localized: "This entry was deleted.")
                    return
                }
                try viewModel.updateEntry(
                    entryToEdit,
                    day: selectedDay,
                    title: title,
                    slot: slot,
                    note: note,
                    recipe: linkedRecipe?.isLive == true ? linkedRecipe : nil
                )
            } else {
                try viewModel.addEntry(
                    on: selectedDay,
                    title: title,
                    slot: slot,
                    note: note,
                    recipe: linkedRecipe?.isLive == true ? linkedRecipe : nil
                )
            }
            feedback = .saved
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    let container = PreviewData.containerWithSamples()
    return MealPlanEntryFormView(
        viewModel: PlannerViewModel(context: container.mainContext),
        day: .today()
    )
    .modelContainer(container)
}
