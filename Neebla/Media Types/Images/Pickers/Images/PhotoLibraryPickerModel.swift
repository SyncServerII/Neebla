
import Foundation
import UIKit
import iOSShared

class PhotoLibraryPickerModel {
    let sharingGroupUUID: UUID
    let dismisser:MediaTypeListDismisser
    
    init(album sharingGroupUUID: UUID, dismisser:MediaTypeListDismisser) {
        self.sharingGroupUUID = sharingGroupUUID
        self.dismisser = dismisser
    }
    
    func uploadImage(pickerResult: Result<UploadableMediaAssets, Error>) {
        switch pickerResult {
        case .failure(let error):
            logger.error("error: \(error)")
            #warning("Need to show this to the user.")
            break
            
        case .success(let asset):
            do {
                try AnyTypeManager.session.uploadNewObject(assets: asset, sharingGroupUUID: sharingGroupUUID)
                dismisser.dismiss(acquiredNewItem: true)
            }
            catch let error {
                logger.error("error: \(error)")
            }
        }
    }
}
