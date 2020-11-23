
import Foundation
import iOSBasics
import iOSShared

class ItemTypeManager {
    enum ItemTypeManagerError: Error {
        case duplicateObjectType
    }
    
    static let session = ItemTypeManager()
    let objectTypes:[DeclarableObject & ObjectDownloadHandler] = [
        ImageObjectType(),
        URLObjectType()
    ]
    
    // Call this at app launch, only once.
    func setup() throws {
        let allObjectTypes = objectTypes.map {$0.objectType}
        guard allObjectTypes.count == Set<String>(allObjectTypes).count else {
            throw ItemTypeManagerError.duplicateObjectType
        }
        
        do {
            for objectType in objectTypes {
                try Services.session.serverInterface.syncServer.register(object: objectType)
            }
        } catch let error {
            logger.error("\(error)")
        }
    }
}
