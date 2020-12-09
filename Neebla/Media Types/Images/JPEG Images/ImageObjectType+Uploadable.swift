
import Foundation
import UIKit

struct ImageObjectTypeAssets: UploadableMediaAssets {
    // File reference to a JPEG image. This needs to be movied/copied to a permanent location in the app.
    let jpegFile: URL
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
        
        try ImageObjectType.uploadNewObjectInstance(assets: assets, sharingGroupUUID: sharingGroupUUID)
    }
}
