//
//  AdMobService.swift
//  RecipeBB
//
//  Created by Jay Hui on 10/11/2025.
//

import UIKit
import GoogleMobileAds
import UserMessagingPlatform
import os

@Observable
@MainActor
class AdMobService: NSObject, FullScreenContentDelegate {
    static let shared = AdMobService()

    var isAdLoading = false
    var isAdReady = false

    private var rewardedAd: RewardedAd?
    private var loadTask: Task<Void, Never>?
    private var isMobileAdsStarted = false
    private var presentationCompletion: (@Sendable (Bool) -> Void)?
    private var rewardEarned = false

    private let adUnitID: String? = {
        return Bundle.main.object(forInfoDictionaryKey: "AdMobRewardedAdUnitIdentifier") as? String
    }()

    private override init() {
        super.init()
    }

    /// Gathers UMP consent (presenting the consent form if required),
    /// then starts the Mobile Ads SDK if ads may be requested.
    func requestConsentAndStart() async {
        do {
            try await ConsentInformation.shared.requestConsentInfoUpdate(with: RequestParameters())
            try await ConsentForm.loadAndPresentIfRequired(from: nil)
        } catch {
            Logger.ads.error("Consent gathering failed: \(error.localizedDescription)")
        }

        // canRequestAds can still be true on error if consent was obtained previously.
        guard ConsentInformation.shared.canRequestAds, !isMobileAdsStarted else { return }
        isMobileAdsStarted = true
        await MobileAds.shared.start()
    }

    func loadAd() async {
        // If a load is already in flight, wait for it instead of starting another
        if isAdLoading {
            await loadTask?.value
            return
        }

        // Ads may only be requested once consent has been resolved and the SDK started
        guard isMobileAdsStarted else {
            Logger.ads.notice("Ad not loaded: Mobile Ads SDK not started (no consent yet)")
            return
        }

        // If adUnitID is not configured, ads are disabled
        guard let adUnitID else {
            Logger.ads.notice("AdMob not configured: AdMobRewardedAdUnitIdentifier missing in Info.plist")
            return
        }

        isAdLoading = true

        loadTask = Task {
            do {
                let ad = try await RewardedAd.load(
                    with: adUnitID, request: Request())

                ad.fullScreenContentDelegate = self
                self.rewardedAd = ad
                self.isAdReady = true
                Logger.ads.info("Rewarded ad loaded successfully")
            } catch {
                Logger.ads.error("Failed to load rewarded ad: \(error.localizedDescription)")
                self.isAdReady = false
            }
            self.isAdLoading = false
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

    func showAd(from viewController: UIViewController, completion: @escaping @Sendable (Bool) -> Void) {
        guard let ad = rewardedAd, isAdReady else {
            Logger.ads.notice("Ad wasn't ready.")
            completion(false)
            return
        }

        // The reward handler only fires if the user watches enough of the ad;
        // completion is called from the delegate once the ad is dismissed or fails.
        isAdReady = false
        rewardEarned = false
        presentationCompletion = completion

        ad.present(from: viewController) {
            let reward = ad.adReward
            Logger.ads.debug("Reward amount: \(reward.amount)")

            Task { @MainActor in
                self.rewardEarned = true
            }
        }
    }

    /// Tears down the presented ad and resumes the caller, in all outcomes:
    /// reward earned, dismissed early, or failed to present.
    private func finishPresentation() {
        isAdReady = false
        rewardedAd = nil

        let completion = presentationCompletion
        presentationCompletion = nil
        completion?(rewardEarned)

        // Preload next ad
        Task { await loadAd() }
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
        finishPresentation()
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Logger.ads.error("Ad failed to present: \(error.localizedDescription)")
        finishPresentation()
    }
}
