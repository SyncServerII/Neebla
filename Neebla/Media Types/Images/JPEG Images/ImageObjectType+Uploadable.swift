
import Foundation
import UIKit

struct ImageObjectTypeAssets: UploadableMediaAssets {
    let image: UIImage
}

extension ImageObjectType: UploadableMediaType {
    func canUpload(assets: UploadableMediaAssets) -> Bool {
        guard assets is ImageObjectTypeAssets else {
            return false
        }
        
        return true
    }
    
    func uploadNewObjectInstance(assets: UploadableMediaAssets, sharingGroupUUID: UUID) throws {
        guard let assets = assets as? ImageObjectTypeAssets else {
            throw ImageObjectTypeError.badAssetType
        }
        
        try ImageObjectType.uploadNewObjectInstance(image: assets.image, sharingGroupUUID: sharingGroupUUID)
    }
}
