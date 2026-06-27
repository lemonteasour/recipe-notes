//
//  Logger+Categories.swift
//  RecipeBB
//
//  Created by Jay Hui on 27/09/2025.
//

import Foundation
import os

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "RecipeBB"

    /// Logs related to ad loading and presentation.
    static let ads = Logger(subsystem: subsystem, category: "ads")

    /// Logs related to the SwiftData stack.
    static let persistence = Logger(subsystem: subsystem, category: "persistence")
}
