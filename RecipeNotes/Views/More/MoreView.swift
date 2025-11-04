//
//  MoreView.swift
//  RecipeNotes
//
//  Created by Jay Hui on 22/10/2025.
//

import SwiftUI

struct MoreView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Link(destination: URL(string: "https://apps.apple.com/app/id6752032405?action=write-review")!) {
                        HStack {
                            Image(systemName: "star.fill")
                                .frame(width: 30)
                            Text("Leave a review")
                            Spacer()
                            Image(systemName: "arrow.up.forward")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Link(destination: URL(string: "https://lemonteasour.com/projects/recipenotes")!) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .frame(width: 30)
                            Text("About Recipe Notes")
                            Spacer()
                            Image(systemName: "arrow.up.forward")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Link(destination: URL(string: "https://lemonteasour.com/projects/recipenotes/privacy")!) {
                        HStack {
                            Image(systemName: "lock.fill")
                                .frame(width: 30)
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.forward")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Send feedback

                } header: {
                    Text("Help")
                }

                Section {
                    // Watch an ad

                    Link(destination: URL(string: "https://buymeacoffee.com/lemonteasour")!) {
                        HStack {
                            Image(systemName: "cup.and.saucer.fill")
                                .frame(width: 30)
                            Text("Buy me a coffee")
                            Spacer()
                            Image(systemName: "arrow.up.forward")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Support the developer")
                }
            }
            .navigationTitle("More")
        }
    }
}

#Preview {
    MoreView()
}
