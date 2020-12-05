
import Foundation
import iOSBasics
import iOSShared

class AnyTypeManager {
    enum ItemTypeManagerError: Error {
        case duplicateObjectType
    }
    
    static let session = AnyTypeManager()
    let objectTypes:[DeclarableObject & ObjectDownloadHandler & ItemType] = [
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
    
    func displayName(forObjectType objectType: String) -> String? {
        for type in objectTypes {
            if type.objectType == objectType {
                return type.displayName
            }
        }
        
        return nil
    }
}
