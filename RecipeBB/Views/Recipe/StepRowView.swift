//
//  StepRowView.swift
//  RecipeBB
//

import SwiftUI

struct StepRowView: View {
    let step: Step

    var body: some View {
        HStack(alignment: .top) {
            Text("\(step.sortOrder + 1).")
                .foregroundStyle(.secondary)
                .frame(width: 24)
            Text(step.value)
            Spacer()
        }
    }
}
