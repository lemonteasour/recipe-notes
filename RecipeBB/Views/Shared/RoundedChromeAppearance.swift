//
//  RoundedChromeAppearance.swift
//  RecipeBB
//
//  Created by Jay Hui on 19/08/2026.
//

import UIKit

/// Rounds the navigation and tab bar titles to match `.fontDesign(.rounded)`,
/// which the rest of the app gets from one modifier in `RecipeBBApp`.
///
/// Those two are the only text SwiftUI's font environment can't reach: UIKit
/// draws them, and there is no SwiftUI API for their font. Without this the app
/// reads rounded everywhere except its own titles, which is worse than not
/// doing it at all.
///
/// Neither a `View` nor a `ViewModifier`, so it doesn't take the `Modifier`
/// suffix — it has to run before any view exists, and is called once from
/// `RecipeBBApp.init()`. `@MainActor` because every appearance proxy and
/// `UIFont` call below is; `App.init()` is already on the main actor, so the
/// call site needs nothing.
@MainActor
enum RoundedChromeAppearance {
    static func apply() {
        applyNavigationBar()
        applyTabBar()
    }

    /// The fonts are resolved once, at launch, from the *current* Dynamic Type
    /// size — appearance proxies hold a concrete `UIFont`, not a promise to
    /// scale. Changing the text size while the app is running therefore resizes
    /// every SwiftUI label immediately but leaves the bar titles until the next
    /// launch. Accepted: the alternative is a `UINavigationBar` subclass, and
    /// the mismatch is a title one step out of size until relaunch.
    private static func rounded(_ style: UIFont.TextStyle, weight: UIFont.Weight) -> UIFont {
        let base = UIFont.preferredFont(forTextStyle: style)
        guard let descriptor = base.fontDescriptor.withDesign(.rounded) else { return base }
        let weighted = descriptor.addingAttributes(
            [.traits: [UIFontDescriptor.TraitKey.weight: weight]]
        )
        return UIFont(descriptor: weighted, size: 0)
    }

    /// Only the font attribute is touched, and only on appearance objects that
    /// already exist.
    ///
    /// Calling any `configureWith…` method here — or assigning a freshly built
    /// `UINavigationBarAppearance` — would replace the iOS 26 glass background
    /// with a flat one. `standardAppearance` always returns an object;
    /// `scrollEdgeAppearance` and `compactAppearance` are nil until something
    /// sets them, and filling them in would cost the transparent scroll-edge
    /// state.
    private static func applyNavigationBar() {
        let inline = rounded(.headline, weight: .semibold)
        let large = rounded(.largeTitle, weight: .bold)

        let bar = UINavigationBar.appearance()
        for appearance in [bar.standardAppearance, bar.scrollEdgeAppearance, bar.compactAppearance] {
            guard let appearance else { continue }
            appearance.titleTextAttributes[.font] = inline
            appearance.largeTitleTextAttributes[.font] = large
        }
    }

    /// A no-op if the system is drawing the tab bar itself rather than through
    /// `UITabBar`, which is fine — there is nothing to fall back to and nothing
    /// breaks either way.
    private static func applyTabBar() {
        let item = UITabBarItem.appearance()
        let font = rounded(.caption2, weight: .medium)
        item.setTitleTextAttributes([.font: font], for: .normal)
        item.setTitleTextAttributes([.font: font], for: .selected)
    }
}
