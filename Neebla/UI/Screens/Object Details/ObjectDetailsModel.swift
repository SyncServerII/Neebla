
import Foundation
import iOSShared
import SQLite

class ObjectDetailsModel {
    let object: ServerObjectModel
    private(set) var objectTypeDisplayName:String!
    let mediaTitle: String?

    init?(object: ServerObjectModel) {
        self.object = object
        
        guard let displayName = AnyTypeManager.session.displayName(forObjectType: object.objectType) else {
            logger.error("Could not get display name for objectType: \(object.objectType)")
            return nil
        }
        objectTypeDisplayName = displayName
        
        do {
            mediaTitle = try Comments.displayableMediaTitle(for: object)
        } catch let error {
            logger.error("\(error)")
            return nil
        }
    }
    
    func deleteObject() -> Bool {
        do {
            // Do the SyncServer call first; it's the most likely to fail of these two.
            try Services.session.syncServer.queue(objectDeletion: object.fileGroupUUID)
            try object.update(setters: ServerObjectModel.deletedField.description <- true)
        } catch let error {
            logger.error("\(error)")
            return false
        }
        
        return true
    }
}
