//
//  Step.swift
//  RecipeNotes
//
//  Created by Jay Hui on 26/08/2025.
//

import Foundation
import SwiftData

@Model
class Step: Identifiable {
    @Attribute(.unique) var id: UUID
    var value: String
    var index: Int

    init(value: String, index: Int) {
        self.id = UUID()
        self.value = value
        self.index = index
    }
}
