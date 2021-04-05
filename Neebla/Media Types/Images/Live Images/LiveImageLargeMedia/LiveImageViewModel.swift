
import Foundation
import UIKit
import PhotosUI
import iOSShared

class LiveImageViewModel {
    let imageFileLabel = LiveImageObjectType.imageDeclaration.fileLabel
    let movieFileLabel = LiveImageObjectType.movieDeclaration.fileLabel
    var imageURL: URL?
    var movieURL: URL?
    private(set) var gone: Bool = false
    private(set) var error: Bool = true
    var started = false
    
    init(fileGroupUUID: UUID) {
        do {
            let imageFileModel = try ServerFileModel.getFileFor(fileLabel: imageFileLabel, withFileGroupUUID: fileGroupUUID)
            guard let url1 = imageFileModel.url else {
                logger.error("No image URL")
                gone = imageFileModel.gone
                return
            }
            imageURL = url1

            let movieFileModel = try ServerFileModel.getFileFor(fileLabel: movieFileLabel, withFileGroupUUID: fileGroupUUID)
            guard let url2 = movieFileModel.url else {
                logger.error("No image URL")
                gone = movieFileModel.gone
                return
            }
            movieURL = url2
            
            error = false
        } catch let error {
            logger.error("\(error)")
        }
    }
    
    static func getLivePhoto(image: URL, movie: URL, previewImage: UIImage?, completion: @escaping (PHLivePhoto?) -> ()) {
        PHLivePhoto.request(withResourceFileURLs: [image, movie], placeholderImage: previewImage, targetSize: CGSize.zero, contentMode: .aspectFit) { (livePhoto: PHLivePhoto?, infoDict: [AnyHashable : Any]) in
            
            logger.debug("infoDict: \(infoDict); livePhoto: \(String(describing: livePhoto))")
            
            completion(livePhoto)
        }
    }
}
