//
//  AppearanceMode.swift
//  RecipeBB
//
//  Created by Jay Hui on 13/08/2026.
//

import SwiftUI

/// Which color scheme the app forces, if any. Stored in `UserDefaults` under
/// `appearanceModeKey` and read by `RecipeBBApp` via `@AppStorage`, so the raw
/// values are persisted and must not change.
enum AppearanceMode: String, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    static let storageKey = "appearanceMode"

    var id: Self { self }

    /// Matches `MealSlot.label`.
    var label: LocalizedStringKey {
        switch self {
        case .system: "Same as device"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    /// `nil` hands the choice back to the system.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
