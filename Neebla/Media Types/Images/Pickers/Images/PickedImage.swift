
import Foundation
import iOSShared
import UIKit

enum PickedImage {
    enum PickedImageError: Error {
        case noLiveImageSupportYet
        case couldNotCreateUIImage
    }
    
    case jpeg(URL)

    // These are also used for file name extensions.
    enum ImageType: String {
        case heic
        case jpeg
    }
    
    case liveImage(movie: URL, imageURL:URL, imageType: ImageType)
    
    func toUploadAssets() throws -> UploadableMediaAssets {
        switch self {
        case .jpeg(let url):
            let imageData = try Data(contentsOf: url)

            if let image = UIImage(data: imageData) {
                return ImageObjectTypeAssets(image: image)
            }
            else {
                throw PickedImageError.couldNotCreateUIImage
            }
            
        case .liveImage:
            throw PickedImageError.noLiveImageSupportYet
        }
    }
}
