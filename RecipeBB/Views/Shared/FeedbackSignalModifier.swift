//
//  FeedbackSignalModifier.swift
//  RecipeBB
//
//  Created by Jay Hui on 13/08/2026.
//

import SwiftUI

/// A one-shot haptic request. Hold one in `@State`, assign it when a mutation
/// succeeds, and `.sensoryFeedback(signal:)` plays it.
///
/// Views mutate models through callbacks rather than through one observable
/// value, so most sites have no natural thing to key `.sensoryFeedback(trigger:)`
/// off. Each instance carries a fresh `id` so repeated identical actions — five
/// pantry items added in a row — each play. The cases are the whole vocabulary
/// on purpose: naming them here keeps one action feeling the same everywhere,
/// instead of every call site picking its own weight.
struct FeedbackSignal: Equatable {
    let feedback: SensoryFeedback
    private let id = UUID()

    /// Something was created. Earns a haptic where the result lands outside
    /// where you're looking — the pantry add card keeps focus for the next item.
    static var added: FeedbackSignal { .init(feedback: .success) }

    /// An edit was committed. Deliberately identical to `added`: storing a
    /// change should feel the same whether or not the thing is new, and the
    /// recipe form's one Save button serves both.
    static var saved: FeedbackSignal { .init(feedback: .success) }

    /// Something was destroyed. Deliberately heavier than `added`.
    static var deleted: FeedbackSignal { .init(feedback: .impact(weight: .medium)) }

    /// A state flipped in place, e.g. favouriting from a swipe with your thumb
    /// over the row.
    static var toggled: FeedbackSignal { .init(feedback: .impact(flexibility: .soft)) }

    /// Compared by `id` alone: `SensoryFeedback` isn't `Equatable`, and identity
    /// is what decides whether the trigger fires anyway.
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}

extension View {
    /// Plays `signal` whenever a new one is assigned.
    func sensoryFeedback(signal: FeedbackSignal?) -> some View {
        sensoryFeedback(trigger: signal) { _, new in new?.feedback }
    }
}
