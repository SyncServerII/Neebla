
import Foundation
import iOSShared

class URLPickerModel {
    let sharingGroupUUID: UUID
    let alertMessage: AlertMessage
    let dismisser:MediaTypeListDismisser

    init(album sharingGroupUUID: UUID, alertMessage: AlertMessage, dismisser:MediaTypeListDismisser) {
        self.sharingGroupUUID = sharingGroupUUID
        self.alertMessage = alertMessage
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
