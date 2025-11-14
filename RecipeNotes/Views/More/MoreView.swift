//
//  MoreView.swift
//  RecipeNotes
//
//  Created by Jay Hui on 22/10/2025.
//

import SwiftUI

struct MoreView: View {
    @StateObject private var adMobService = AdMobService.shared
    @State private var showingAdAlert = false
    @State private var adAlertMessage = ""

    private let reviewURL = URL(string: "https://apps.apple.com/app/id6752032405?action=write-review")
    private let aboutURL = URL(string: "https://lemonteasour.com/projects/recipenotes")
    private let privacyURL = URL(string: "https://lemonteasour.com/projects/recipenotes/privacy")
    private let coffeeURL = URL(string: "https://buymeacoffee.com/lemonteasour")

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let reviewURL {
                        Link(destination: reviewURL) {
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
                    }

                    if let aboutURL {
                        Link(destination: aboutURL) {
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
                    }

                    if let privacyURL {
                        Link(destination: privacyURL) {
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
                    }

                    // Send feedback

                } header: {
                    Text("Help")
                }

                Section {
                    Button {
                        Task {
                            await watchAd()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "play.rectangle.fill")
                                .frame(width: 30)
                            Text("Watch an ad")
                            Spacer()
                            if adMobService.isAdLoading {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(adMobService.isAdLoading)

                    if let coffeeURL {
                        Link(destination: coffeeURL) {
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
                    }
                } header: {
                    Text("Support the developer")
                }
            }
            .navigationTitle("More")
            .onAppear {
                Task {
                    await adMobService.loadAd()
                }
            }
            .alert("Ad Status", isPresented: $showingAdAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(adAlertMessage)
            }
        }
    }

    private func watchAd() async {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            adAlertMessage = "Unable to show ad. Please try again."
            showingAdAlert = true
            return
        }

        if !adMobService.isAdReady {
            await adMobService.loadAd()
            adAlertMessage = "Ad is loading. Please wait a moment and try again."
            showingAdAlert = true
            return
        }

        adMobService.showAd(from: rootViewController) { success in
            if success {
                adAlertMessage = "Thank you for supporting the developer!"
                showingAdAlert = true
            } else {
                adAlertMessage = "Failed to show ad. Please try again later."
                showingAdAlert = true
            }
        }
    }
}

#Preview {
    MoreView()
}
