
import Foundation
import iOSShared
import UIKit

// REMOVE THIS

enum PickedImage {
    enum PickedImageError: Error {
        case noLiveImageSupportYet
        case couldNotCreateUIImage
    }
    
    case jpeg(assets: ImageObjectTypeAssets)
    case liveImage(assets: LiveImageObjectTypeAssets)
    
    func toUploadAssets() throws -> UploadableMediaAssets {
        switch self {
        case .jpeg(let assets):
            return assets
            
        case .liveImage(let assets):
            return assets
        }
    }
}
