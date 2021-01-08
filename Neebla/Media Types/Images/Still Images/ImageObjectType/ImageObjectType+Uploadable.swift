
import Foundation
import UIKit
import ServerShared

struct ImageObjectTypeAssets: UploadableMediaAssets {
    enum ImageObjectTypeAssetsError: Error {
        case badMimeType
    }
    
    static let allowedMimeTypes: Set<MimeType> = [.jpeg, .png]
    
    // Mime type of the image
    let mimeType: MimeType
    
    // File reference to an image. This needs to be movied/copied to a permanent location in the app.
    let imageURL: URL
    
    init(mimeType: MimeType, imageURL: URL) throws {
        guard Self.allowedMimeTypes.contains(mimeType) else {
            throw ImageObjectTypeAssetsError.badMimeType
        }
        
        self.mimeType = mimeType
        self.imageURL = imageURL
    }
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
