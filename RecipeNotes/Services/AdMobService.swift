//
//  AdMobService.swift
//  RecipeNotes
//
//  Created by Jay Hui on 10/11/2025.
//

import UIKit
import GoogleMobileAds

class AdMobService: NSObject, ObservableObject, FullScreenContentDelegate {
    static let shared = AdMobService()

    @Published var isAdLoading = false
    @Published var isAdReady = false

    private var rewardedAd: RewardedAd?

    private let adUnitID: String? = {
        return Bundle.main.object(forInfoDictionaryKey: "AdMobRewardedAdUnitIdentifier") as? String
    }()

    private override init() {
        super.init()
        MobileAds.shared.start()
    }

    func loadAd() async {
        guard !isAdLoading else { return }

        // If adUnitID is not configured, ads are disabled
        guard let adUnitID else {
            print("AdMob not configured: AdMobRewardedAdUnitIdentifier missing in Info.plist")
            return
        }

        await MainActor.run {
            isAdLoading = true
        }

        do {
            let ad = try await RewardedAd.load(
                with: adUnitID, request: Request())
            ad.fullScreenContentDelegate = self

            await MainActor.run {
                self.rewardedAd = ad
                self.isAdReady = true
                self.isAdLoading = false
            }
            print("Rewarded ad loaded successfully")
        } catch {
            print("Failed to load rewarded ad with error: \(error.localizedDescription)")
            await MainActor.run {
                self.isAdReady = false
                self.isAdLoading = false
            }
        }
    }

    func showAd(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        guard let ad = rewardedAd, isAdReady else {
            print("Ad wasn't ready.")
            completion(false)
            return
        }

        ad.present(from: viewController) {
            let reward = ad.adReward
            print("Reward amount: \(reward.amount)")

            Task {
                await MainActor.run {
                    self.isAdReady = false
                    self.rewardedAd = nil
                }
                completion(true)
                // Preload next ad
                await self.loadAd()
            }
        }
    }

    // MARK: - FullScreenContentDelegate

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("Ad did dismiss")
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Ad failed to present with error: \(error.localizedDescription)")
    }
}
