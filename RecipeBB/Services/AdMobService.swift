//
//  AdMobService.swift
//  RecipeBB
//
//  Created by Jay Hui on 10/11/2025.
//

import UIKit
import GoogleMobileAds
import os

@Observable
@MainActor
class AdMobService: NSObject, FullScreenContentDelegate {
    static let shared = AdMobService()

    var isAdLoading = false
    var isAdReady = false

    private var rewardedAd: RewardedAd?
    private var loadTask: Task<Void, Never>?

    private let adUnitID: String? = {
        return Bundle.main.object(forInfoDictionaryKey: "AdMobRewardedAdUnitIdentifier") as? String
    }()

    private override init() {
        super.init()
    }

    func loadAd() async {
        // Cancel any existing load task
        loadTask?.cancel()

        // Prevent multiple simultaneous loads
        guard !isAdLoading else { return }

        // If adUnitID is not configured, ads are disabled
        guard let adUnitID else {
            Logger.ads.notice("AdMob not configured: AdMobRewardedAdUnitIdentifier missing in Info.plist")
            return
        }

        isAdLoading = true

        // Store the load task so we can cancel it if needed
        loadTask = Task {
            do {
                let ad = try await RewardedAd.load(
                    with: adUnitID, request: Request())

                // Check if task was cancelled
                guard !Task.isCancelled else {
                    Logger.ads.debug("Ad load was cancelled")
                    isAdLoading = false
                    return
                }

                ad.fullScreenContentDelegate = self
                self.rewardedAd = ad
                self.isAdReady = true
                self.isAdLoading = false
                Logger.ads.info("Rewarded ad loaded successfully")
            } catch {
                Logger.ads.error("Failed to load rewarded ad: \(error.localizedDescription)")
                self.isAdReady = false
                self.isAdLoading = false
            }
        }

        await loadTask?.value
    }

    /// Presents a loaded ad from the app's current root view controller.
    /// - Returns: `true` if the user was shown the ad and earned the reward.
    func presentAd() async -> Bool {
        guard let rootViewController = Self.rootViewController() else {
            Logger.ads.error("Unable to present ad: no root view controller")
            return false
        }
        return await withCheckedContinuation { continuation in
            showAd(from: rootViewController) { success in
                continuation.resume(returning: success)
            }
        }
    }

    nonisolated func showAd(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        Task { @MainActor in
            guard let ad = rewardedAd, isAdReady else {
                Logger.ads.notice("Ad wasn't ready.")
                completion(false)
                return
            }

            ad.present(from: viewController) {
                let reward = ad.adReward
                Logger.ads.debug("Reward amount: \(reward.amount)")

                Task { @MainActor in
                    self.isAdReady = false
                    self.rewardedAd = nil
                    completion(true)
                    // Preload next ad
                    await self.loadAd()
                }
            }
        }
    }

    /// Resolves the key window's root view controller for ad presentation.
    private static func rootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
    }

    // MARK: - FullScreenContentDelegate

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Logger.ads.debug("Ad did dismiss")
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Logger.ads.error("Ad failed to present: \(error.localizedDescription)")
    }
}
