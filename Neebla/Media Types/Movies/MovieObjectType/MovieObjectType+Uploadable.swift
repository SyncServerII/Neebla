//
//  MovieObjectType+Uploadable.swift
//  Neebla
//
//  Created by Christopher G Prince on 10/24/21.
//

import Foundation
import UIKit

struct MovieObjectTypeAssets: UploadableMediaAssets {
    // The following files can be used as permanent, but they will not be in the right directory/location for saving in the app. Plus, the specific file names won't be what are needed in the app.
    
    // JPEG image.
    let thumbnailFile: URL
    
    let movieFile: URL
}

extension MovieObjectType: UploadableMediaType {
    func canUpload(assets: UploadableMediaAssets) -> Bool {
        guard assets is MovieObjectTypeAssets else {
            return false
        }
        
        return true
    }
    
    func uploadNewObjectInstance(assets: UploadableMediaAssets, sharingGroupUUID: UUID) throws {
        guard let assets = assets as? MovieObjectTypeAssets else {
            throw MovieObjectTypeError.badAssetType
        }
        
        try MovieObjectType.uploadNewObjectInstance(assets: assets, sharingGroupUUID: sharingGroupUUID)
    }
}
