
import Foundation
import iOSShared

class URLPickerModel {
    let sharingGroupUUID: UUID
    let dismisser:MediaTypeListDismisser

    init(album sharingGroupUUID: UUID, dismisser:MediaTypeListDismisser) {
        self.sharingGroupUUID = sharingGroupUUID
        self.dismisser = dismisser
    }
    
    func upload(assets: UploadableMediaAssets) {
        do {
            try AnyTypeManager.session.uploadNewObject(assets: assets, sharingGroupUUID: sharingGroupUUID)
            dismisser.dismiss(acquiredNewItem: true)
        }
        catch let error {
            logger.error("error: \(error)")
        }
    }
}
