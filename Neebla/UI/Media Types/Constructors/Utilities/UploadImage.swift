//
//  UploadImage.swift
//  Neebla
//
//  Created by Christopher G Prince on 11/18/20.
//

import Foundation
import UIKit
import iOSShared

struct UploadImage {
    static func upload(image: UIImage, sharingGroupUUID: UUID, alertMessage: AlertMessage, dismisser:MediaTypeListDismisser) {
        
        do {
            try ImageObjectType.uploadNewObjectInstance(image: image, sharingGroupUUID: sharingGroupUUID)
        } catch let error {
            logger.error("\(error)")
            alertMessage.alertMessage = "Could not upload new image!"
        }
        
        // Put this *after* `uploadNewObjectInstance` call above because that call adds the new image object type to the database, and this `dismiss` call will refresh a view based on that database. Plus reporting `acquiredNewItem` only really makes sense *after* the upload/add.
        dismisser.dismiss(acquiredNewItem: true)
    }
}
