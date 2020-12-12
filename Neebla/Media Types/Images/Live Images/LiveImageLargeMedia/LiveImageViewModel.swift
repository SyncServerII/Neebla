
import Foundation
import UIKit
import PhotosUI
import iOSShared

class LiveImageViewModel {
    let imageFileLabel = LiveImageObjectType.imageDeclaration.fileLabel
    let movieFileLabel = LiveImageObjectType.movieDeclaration.fileLabel
    let imageURL: URL
    let movieURL: URL
        
    init?(fileGroupUUID: UUID) {
        do {
            guard let url1 = try ServerFileModel.getFileFor(fileLabel: imageFileLabel, withFileGroupUUID: fileGroupUUID).url else {
                logger.error("No image URL")
                return nil
            }
            imageURL = url1

            guard let url2 = try ServerFileModel.getFileFor(fileLabel: movieFileLabel, withFileGroupUUID: fileGroupUUID).url else {
                logger.error("No image URL")
                return nil
            }
            movieURL = url2
        } catch let error {
            logger.error("\(error)")
            return nil
        }
    }
    
    func getLivePhoto(previewImage: UIImage?, completion: @escaping (PHLivePhoto?) -> ()) {
        PHLivePhoto.request(withResourceFileURLs: [imageURL, movieURL], placeholderImage: previewImage, targetSize: CGSize.zero, contentMode: .aspectFit) { (livePhoto: PHLivePhoto?, infoDict: [AnyHashable : Any]) in
            
            logger.debug("infoDict: \(infoDict); livePhoto: \(String(describing: livePhoto))")
            
            completion(livePhoto)
        }
    }
}
