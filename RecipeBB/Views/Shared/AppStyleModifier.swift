//
//  AppStyleModifier.swift
//  RecipeBB
//
//  Created by Jay Hui on 19/08/2026.
//

import SwiftUI

/// The app's shared visual vocabulary: two backgrounds, two radii, and the two
/// treatments that were being copied by hand into every screen.
///
/// Deliberately small, and deliberately closed — the same reasoning as
/// `FeedbackSignal`. This is not a token system to grow into; it exists so that
/// "what a card looks like" and "what a section header looks like" have one
/// answer instead of four, and so the warm background can be changed in one
/// place. Anything used once still belongs at its call site.
///
/// The colours themselves live in `Assets.xcassets` and reach code through
/// Xcode's generated asset symbols (`Color(.appBackground)`), the same route
/// `.tint(.accent)` already takes in `RecipeBBApp`.
enum AppRadius {
    /// The card corner. Chosen to sit just inside the iOS 26 continuous-corner
    /// look rather than to match any particular system control.
    static let card: CGFloat = 28

    /// Recipe photo thumbnails. Rounder than the 8pt it replaced, so it agrees
    /// with the app's rounded type rather than fighting it.
    static let thumbnail: CGFloat = 12
}

extension View {
    /// The uppercase secondary label that titles a hand-built section — the
    /// Pantry's category headers, the Planner's date header, the context-menu
    /// preview's section titles.
    ///
    /// Type and colour only: every call site pads differently, and folding the
    /// padding in here would mean four overrides on the way back out.
    func sectionHeaderStyle() -> some View {
        self
            .font(.footnote)
            .textCase(.uppercase)
            .foregroundStyle(.secondary)
            .accessibilityAddTraits(.isHeader)
    }

    /// The rounded panel that holds rows on the grouped background — Pantry
    /// category lists, the Pantry add form, the month grid, the day's entries.
    ///
    /// `.clipShape` rather than the `.cornerRadius` it replaces: continuous
    /// corners, and it clips the row dividers that used to paint into the
    /// corners.
    func cardStyle() -> some View {
        self
            .background(Color(.appBackgroundElevated))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
    }

    /// The warm ground every scrolling tab sits on, in place of the system's
    /// cool `systemGroupedBackground`.
    func appBackground() -> some View {
        background(Color(.appBackground))
    }

    /// `appBackground()` for a `List` or `Form`, which paint their own ground
    /// and have to be asked to stop first.
    ///
    /// `listRowBackground` is set here, on the container, so the rows sitting on
    /// the warm gutters are the same elevated colour as the hand-built cards in
    /// Pantry and Planner. Without it the rows keep the system's cool
    /// `secondarySystemGroupedBackground`, which reads blue against the amber.
    func listAppBackground() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(Color(.appBackground))
            .listRowBackground(Color(.appBackgroundElevated))
    }
}
