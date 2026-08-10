//
//  StepRowView.swift
//  RecipeBB
//

import SwiftUI

struct StepRowView: View {
    let step: Step
    /// Position in the list rather than `step.sortOrder`, so steps that land on
    /// a duplicate order after a sync merge still read 1, 2, 3.
    let number: Int

    var body: some View {
        HStack(alignment: .top) {
            Text("\(number).")
                .foregroundStyle(.secondary)
                .frame(width: 24)
            Text(step.value)
            Spacer()
        }
    }
}
