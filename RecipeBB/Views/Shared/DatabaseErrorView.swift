//
//  DatabaseErrorView.swift
//  RecipeBB
//
//  Created by Jay Hui on 20/08/2025.
//

import SwiftUI

// Error view shown when database initialization fails
struct DatabaseErrorView: View {
    let error: Error?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)

            Text("Database Error")
                .font(.title)
                .bold()

            Text("Failed to initialize the app's database. This may be due to:")
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                Text("• Insufficient storage space")
                Text("• Database corruption")
                Text("• iOS update migration issues")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)

            Text("Try restarting your device. If the problem persists, you may need to reinstall the app.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .padding()

            if let error {
                Text("Error: \(error.localizedDescription)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
        }
        .padding()
    }
}
