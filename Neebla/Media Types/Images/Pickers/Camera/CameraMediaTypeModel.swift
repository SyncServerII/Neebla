
import Foundation
import iOSShared

class CameraMediaTypeModel {
    let sharingGroupUUID: UUID
    let dismisser:MediaTypeListDismisser
    
    init(album sharingGroupUUID: UUID, dismisser:MediaTypeListDismisser) {
        self.sharingGroupUUID = sharingGroupUUID
        self.dismisser = dismisser
    }
    
    func uploadImage(asset: ImageObjectTypeAssets) {
        do {
            try AnyTypeManager.session.uploadNewObject(assets: asset, sharingGroupUUID: sharingGroupUUID)
            dismisser.dismiss(acquiredNewItem: true)
        } catch let error {
            logger.error("\(error)")
        }
    }
}
