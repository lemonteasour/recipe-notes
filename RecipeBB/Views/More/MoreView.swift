//
//  MoreView.swift
//  RecipeBB
//
//  Created by Jay Hui on 22/10/2025.
//

import SwiftUI
import SwiftData
import UIKit

struct MoreView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(AppearanceMode.storageKey) private var appearanceMode: AppearanceMode = .system
    private let adMobService = AdMobService.shared
    @State private var showingAdAlert = false
    @State private var adAlertMessage = ""
    #if DEBUG
    @State private var showingResetConfirmation = false
    #endif

    private let reviewURL = URL(string: "https://apps.apple.com/app/id6752032405?action=write-review")
    private let aboutURL = URL(string: "https://lemonteasour.com/projects/recipebb")
    private let privacyURL = URL(string: "https://lemonteasour.com/projects/recipebb/privacy")
    // iOS lists the app's language under its own Settings page, which is the
    // only place the choice can actually be made
    private let settingsURL = URL(string: UIApplication.openSettingsURLString)

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker(selection: $appearanceMode) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "circle.lefthalf.filled")
                                .frame(width: 30)
                            Text("Theme")
                        }
                    }

                    if let settingsURL {
                        Button {
                            UIApplication.shared.open(settingsURL)
                        } label: {
                            HStack {
                                Image(systemName: "globe")
                                    .frame(width: 30)
                                Text("Language")
                                Spacer()
                                Image(systemName: "arrow.up.forward")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Preferences")
                } footer: {
                    if settingsURL != nil {
                        Text("Language is set in the Settings app.")
                    }
                }

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
                                Text("About RecipeBB")
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
                } header: {
                    Text("Support the developer")
                }

                #if DEBUG
                Section {
                    Button(role: .destructive) {
                        showingResetConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                                .frame(width: 30)
                            Text(verbatim: "Reset to sample data")
                        }
                    }
                } header: {
                    // verbatim: debug-only strings stay out of the string catalog
                    Text(verbatim: "Developer")
                }
                #endif
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
            #if DEBUG
            .alert(Text(verbatim: "Reset to sample data?"), isPresented: $showingResetConfirmation) {
                Button(role: .destructive) {
                    PreviewData.wipeAndReseed(context: modelContext)
                } label: {
                    Text(verbatim: "Reset")
                }
                Button(role: .cancel) { } label: {
                    Text(verbatim: "Cancel")
                }
            } message: {
                Text(verbatim: "All recipes, tags, and pantry items will be deleted and replaced with sample data.")
            }
            #endif
        }
    }

    private func watchAd() async {
        if !adMobService.isAdReady {
            await adMobService.loadAd()
        }

        guard adMobService.isAdReady else {
            adAlertMessage = String(localized: "Could not load an ad. Please try again later.")
            showingAdAlert = true
            return
        }

        let success = await adMobService.presentAd()
        adAlertMessage = success
            ? String(localized: "Thank you for supporting the developer!")
            : String(localized: "Failed to show ad. Please try again later.")
        showingAdAlert = true
    }
}

#Preview {
    MoreView()
}
