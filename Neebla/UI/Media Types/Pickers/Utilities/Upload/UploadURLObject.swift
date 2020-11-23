
import Foundation
import iOSShared

struct UploadURLObject {
    static func upload(linkMedia: LinkMedia, sharingGroupUUID: UUID, alertMessage: AlertMessage, dismisser:MediaTypeListDismisser) {
        
        do {
            try URLObjectType.uploadNewObjectInstance(linkMedia: linkMedia, sharingGroupUUID: sharingGroupUUID)
        } catch let error {
            logger.error("\(error)")
            alertMessage.alertMessage = "Could not upload new url!"
        }
        
        // Put this *after* `uploadNewObjectInstance` call above because that call adds the new object to the database, and this `dismiss` call will refresh a view based on that database. Plus reporting `acquiredNewItem` only really makes sense *after* the upload/add.
        dismisser.dismiss(acquiredNewItem: true)
    }
}
