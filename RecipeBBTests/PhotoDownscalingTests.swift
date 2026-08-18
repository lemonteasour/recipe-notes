//
//  PhotoDownscalingTests.swift
//  RecipeBBTests
//
//  Recipe photos are stored at whatever the picker hands over, and with sync on
//  every byte of that is uploaded against a 5GB free iCloud tier and pulled down
//  again by every other device. These pin the shrink that keeps that in hand.
//

import Testing
import Foundation
import UIKit
@testable import RecipeBB

@MainActor
struct PhotoDownscalingTests {

    /// A solid-colour JPEG at exactly the requested pixel size, standing in for
    /// a photo out of the picker. `scale = 1` so the renderer doesn't quietly
    /// produce a 3× bitmap.
    private func jpeg(width: Int, height: Int) -> Data {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let size = CGSize(width: width, height: height)
        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.systemOrange.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        return image.jpegData(compressionQuality: 1)!
    }

    private func pixelSize(of data: Data) throws -> CGSize {
        let image = try #require(UIImage(data: data))
        return CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
    }

    @Test func downscalesALargePhotoToTheLongEdge() throws {
        let original = jpeg(width: 4032, height: 3024)

        let shrunk = try #require(original.downscaledPhotoJPEG())

        let size = try pixelSize(of: shrunk)
        #expect(size.width == 1600)
        // Aspect ratio preserved: 4:3 in, 4:3 out
        #expect(abs(size.width / size.height - 4.0 / 3.0) < 0.01)
        #expect(shrunk.count < original.count)
    }

    /// Portrait photos are capped on their *long* edge too — a limit that only
    /// looked at width would leave a portrait shot uncapped.
    @Test func capsTheLongEdgeOfAPortraitPhoto() throws {
        let shrunk = try #require(jpeg(width: 3024, height: 4032).downscaledPhotoJPEG())

        let size = try pixelSize(of: shrunk)
        #expect(size.height == 1600)
        #expect(size.width < 1600)
    }

    /// Never upscales: a small photo comes back at its own size rather than
    /// being blown up to the limit.
    @Test func leavesASmallPhotoAtItsOriginalSize() throws {
        let shrunk = try #require(jpeg(width: 800, height: 600).downscaledPhotoJPEG())

        #expect(try pixelSize(of: shrunk) == CGSize(width: 800, height: 600))
    }

    /// The form drops the photo rather than storing garbage when the picker
    /// hands back something undecodable.
    @Test func returnsNilForDataThatIsNotAnImage() {
        #expect(Data("not a photo".utf8).downscaledPhotoJPEG() == nil)
    }
}
