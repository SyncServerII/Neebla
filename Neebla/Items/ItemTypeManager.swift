
import Foundation
import iOSBasics
import iOSShared

class ItemTypeManager {
    static let session = ItemTypeManager()
    let objectTypes = [
        ImageObjectType()
    ]
    
    // Call this at app launch, only once.
    func setup() {
        do {
            for objectType in objectTypes {
                try Services.session.serverInterface.syncServer.register(object: objectType)
            }
        } catch let error {
            logger.error("\(error)")
        }
    }
}
