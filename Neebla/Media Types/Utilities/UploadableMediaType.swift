//
//  UploadableMediaType.swift
//  Neebla
//
//  Created by Christopher G Prince on 12/6/20.
//

import Foundation

protocol UploadableMediaAssets {
}

protocol UploadableMediaType {
    // Call this, and get a result of true before calling `uploadNewObjectInstance`.
    // It's assumed that each media type has a unique specific type conforming to UploadableMediaAssets
    func canUpload(assets: UploadableMediaAssets) -> Bool
    
    func uploadNewObjectInstance(assets: UploadableMediaAssets, sharingGroupUUID: UUID) throws
}
