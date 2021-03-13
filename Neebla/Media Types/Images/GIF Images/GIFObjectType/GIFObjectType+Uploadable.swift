//
//  GIFObjectType+Uploadable.swift
//  Neebla
//
//  Created by Christopher G Prince on 3/12/21.
//

import Foundation
import ServerShared

struct GIFObjectTypeAssets: UploadableMediaAssets {
    // The following files can be used as permanent, but they will not be in the right directory/location for saving in the app. Plus, the specific file names won't be what are needed in the app.
    
    static let iconMimeType = MimeType.jpeg
    let iconFile: URL
    
    static let gifMimeType = MimeType.gif
    let gifFile: URL
}

extension GIFObjectType: UploadableMediaType {
    func canUpload(assets: UploadableMediaAssets) -> Bool {
        guard assets is GIFObjectTypeAssets else {
            return false
        }
        
        return true
    }
    
    func uploadNewObjectInstance(assets: UploadableMediaAssets, sharingGroupUUID: UUID) throws {
        guard let assets = assets as? GIFObjectTypeAssets else {
            throw GIFObjectTypeError.badAssetType
        }
        
        try GIFObjectType.uploadNewObjectInstance(assets: assets, sharingGroupUUID: sharingGroupUUID)
    }
}
