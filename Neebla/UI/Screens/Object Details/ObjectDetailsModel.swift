
import Foundation
import iOSShared
import SQLite
import Combine

class ObjectDetailsModel: ObservableObject, ModelAlertDisplaying {
    var userEventSubscription: AnyCancellable!
    let object: ServerObjectModel
    private(set) var objectTypeDisplayName:String?
    var mediaTitle: String?
    @Published var userAlertModel: UserAlertModel
    @Published var modelInitialized: Bool
    
    init(object: ServerObjectModel, userAlertModel: UserAlertModel) {
        self.object = object
        self.userAlertModel = userAlertModel
        
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
        
        modelInitialized = success
        
        setupHandleUserEvents()
    }
    
    func deleteObject() -> Bool {
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
}
