
import Foundation
import iOSShared
import SQLite
import Combine
import SwiftUI

class ObjectDetailsModel: ObservableObject {
    let object: ServerObjectModel
    private(set) var objectTypeDisplayName:String?
    var mediaTitle: String?
    @Published var modelInitialized: Bool
    
    init(object: ServerObjectModel) {
#if DEBUG
        try? object.debugOutput()
#endif
        self.object = object
        
        var success = true
        
        if let displayName = AnyTypeManager.session.displayName(forObjectType: object.objectType) {
            objectTypeDisplayName = displayName
        }
        else {
            logger.error("Could not get display name for objectType: \(object.objectType)")
            success = false
        }
        
        do {
            mediaTitle = try Comments.displayableMediaTitle(for: object)
        } catch let error {
            logger.error("\(error)")
            success = false
        }
        
        /* Workaround for early version of app, when the title was stored in the app meta data for images.
         */
        if mediaTitle == nil {
            do {
                mediaTitle = try OldAppImage.getTitle(object: object)
            } catch let error {
                logger.error("OldAppImage.getTitle: \(error)")
            }
        }
        
        modelInitialized = success
    }
    
    private func deleteObject() -> Bool {
        do {
            let pushNotificationText = try PushNotificationMessage.forDeletion(of: object)

            // Do the SyncServer call first; it's the most likely to fail of these two.
            try Services.session.syncServer.queue(objectDeletion: object.fileGroupUUID, pushNotificationMessage: pushNotificationText)
            // The actual local deletion of files occurs after the deletion request is completed on the server, and the next index update occurs.
            try object.update(setters: ServerObjectModel.deletedField.description <- true)
        } catch let error {
            logger.error("\(error)")
            return false
        }
        
        return true
    }
    
    func promptForDeletion(dismiss: @escaping ()->()) {
        guard modelInitialized else {
            logger.error("promptForDeletion: Model not initialized")
            return
        }
        
        let displayName = objectTypeDisplayName ?? "item"
        
        let alert = AlertyHelper.customAction(
            title: "Delete?",
            message: "Really delete this \(displayName)?",
            actionButtonTitle: "Delete",
            action: {
                if self.deleteObject() {
                    dismiss()
                }
            },
            cancelTitle: "Cancel")
        showAlert(alert)
    }
}
