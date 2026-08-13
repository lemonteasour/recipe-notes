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

    @ScaledMetric private var numberColumn: CGFloat = 24

    var body: some View {
        HStack(alignment: .top) {
            Text("\(number).")
                .foregroundStyle(.secondary)
                .frame(width: numberColumn)
            Text(step.value)
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}
