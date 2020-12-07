
import Foundation
import SMLinkPreview

struct URLObjectTypeAssets: UploadableMediaAssets {
    let linkData: LinkData
    let image: LinkPreview.LoadedImage?
}

extension URLObjectType: UploadableMediaType {
    func canUpload(assets: UploadableMediaAssets) -> Bool {
        guard assets is URLObjectTypeAssets else {
            return false
        }
        
        return true
    }
    
    func uploadNewObjectInstance(assets: UploadableMediaAssets, sharingGroupUUID: UUID) throws {
        guard let assets = assets as? URLObjectTypeAssets else {
            throw URLObjectTypeError.badAssetType
        }
        
        try URLObjectType.uploadNewObjectInstance(asset: assets, sharingGroupUUID: sharingGroupUUID)
    }
}
