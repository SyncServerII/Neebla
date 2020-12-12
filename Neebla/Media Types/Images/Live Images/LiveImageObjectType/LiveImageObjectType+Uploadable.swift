
import Foundation
import UIKit

struct LiveImageObjectTypeAssets: UploadableMediaAssets {
    // These are also used for file name extensions in the picker.
    enum ImageType: String {
        case jpeg
        case heic
    }
    
    // The following files can be used as permanent, but they will not be in the right directory/location for saving in the app. Plus, the specific file names won't be what are needed in the app.
    
    let imageFile: URL
    let imageType: ImageType
    
    let movieFile: URL
}

extension LiveImageObjectType: UploadableMediaType {
    func canUpload(assets: UploadableMediaAssets) -> Bool {
        guard assets is LiveImageObjectTypeAssets else {
            return false
        }
        
        return true
    }
    
    func uploadNewObjectInstance(assets: UploadableMediaAssets, sharingGroupUUID: UUID) throws {
        guard let assets = assets as? LiveImageObjectTypeAssets else {
            throw LiveImageObjectTypeError.badAssetType
        }
        
        try LiveImageObjectType.uploadNewObjectInstance(assets: assets, sharingGroupUUID: sharingGroupUUID)
    }
}
