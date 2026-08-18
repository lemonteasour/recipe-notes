//
//  Data+PhotoDownscaling.swift
//  RecipeBB
//
//  Created by Jay Hui on 18/08/2026.
//

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

extension Data {
    /// Re-encodes image data as a JPEG whose long edge is at most
    /// `maxPixelSize`, or nil if the data isn't a decodable image.
    ///
    /// Recipe photos used to be stored at whatever resolution the picker handed
    /// over — several MB each from a modern iPhone. Local-only that was merely
    /// wasteful; with sync on, every one of them is uploaded against a 5GB free
    /// iCloud tier and downloaded again by every other device. 1600px is still
    /// more than the largest place the photo is ever drawn (a full-width hero on
    /// the detail screen).
    ///
    /// Goes through ImageIO rather than `UIImage`: the thumbnail is decoded at
    /// the target size, so a 48MP photo never costs its full ~190MB of bitmap.
    /// Smaller images are returned as they are — this never upscales.
    func downscaledPhotoJPEG(maxPixelSize: Int = 1600, quality: CGFloat = 0.8) -> Data? {
        guard let source = CGImageSourceCreateWithData(
            self as CFData,
            [kCGImageSourceShouldCache: false] as CFDictionary
        ) else { return nil }

        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            // Bakes the EXIF orientation into the pixels. Without it, a photo
            // taken in portrait comes back on its side.
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(
            source, 0, thumbnailOptions as CFDictionary
        ) else { return nil }

        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            output, UTType.jpeg.identifier as CFString, 1, nil
        ) else { return nil }

        CGImageDestinationAddImage(
            destination,
            image,
            [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary
        )
        guard CGImageDestinationFinalize(destination) else { return nil }

        return output as Data
    }
}
