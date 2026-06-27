//
//  ErrorAlert.swift
//  RecipeBB
//
//  Created by Jay Hui on 27/09/2025.
//

import SwiftUI

/// Presents a standard "Error" alert whenever `message` is non-nil.
/// Replaces the repeated `showingError` / `errorMessage` + `.alert` boilerplate.
private struct ErrorAlertModifier: ViewModifier {
    @Binding var message: String?

    func body(content: Content) -> some View {
        content.alert(
            "Error",
            isPresented: Binding(
                get: { message != nil },
                set: { if !$0 { message = nil } }
            ),
            presenting: message
        ) { _ in
            Button("OK", role: .cancel) { }
        } message: { message in
            Text(message)
        }
    }
}

extension View {
    /// Shows an error alert with the given message, clearing it on dismiss.
    func errorAlert(_ message: Binding<String?>) -> some View {
        modifier(ErrorAlertModifier(message: message))
    }
}
