//
//  GIFHelper.swift
//  Neebla
//
//  Created by Christopher G Prince on 3/14/21.
//

import Foundation
import ImageIO
import UIKit
import iOSShared

// Adapted from https://stackoverflow.com/questions/27919620
class GIFHelper {
    enum GIFHelperError: Error, UserDisplayable {
        case notAtLeastTwoSlices
        case couldNotGetData
        case couldNotGetSettings
        case couldNotConvertToJPEG
        case couldNotGetImage
        
        var userDisplayableMessage: (title: String, message: String)? {
            if self == .notAtLeastTwoSlices {
                return (title: "Alert!", message: "There was only a single image slice in the GIF. Neebla needs at least two image slices.")
            }
            return nil
        }
    }
    
    private let source: CGImageSource
    
    init(gifURL: URL) throws {
        guard let gifData = try? Data(contentsOf: gifURL),
            let source =  CGImageSourceCreateWithData(gifData as CFData, nil) else {
            throw GIFHelperError.couldNotGetData
        }
        
        self.source = source
        
        let imageCount = CGImageSourceGetCount(source)
        
        // In order to get the icon for the object representation, need at least one. Also, if user saves a GIF from Chrome, it saves GIF's with only one "image" slice, and these cause Gifu (the GIF rendering package we're using) problems. i.e., The large image doesn't render GIF *at all*-- just see black. So going to require at least one more.
        guard imageCount >= 2 else {
            throw GIFHelperError.notAtLeastTwoSlices
        }
    }

    // Just arbitrarily using the 0th image from the GIF
    func saveJPEGIcon(to jpegURL: URL) throws {
        guard let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw GIFHelperError.couldNotGetImage
        }
        
        let image = UIImage(cgImage: cgImage)

        guard let jpegQuality = try? SettingsModel.jpegQuality(db: Services.session.db) else {
            throw GIFHelperError.couldNotGetSettings
        }
        
        guard let jpegData = image.jpegData(compressionQuality: jpegQuality) else {
            throw GIFHelperError.couldNotConvertToJPEG
        }

        try jpegData.write(to: jpegURL)
    }
}
