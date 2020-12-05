
import Foundation
import iOSShared

class ObjectDetailsModel {
    let object: ServerObjectModel
    private(set) var objectTypeDisplayName:String!

    init?(object: ServerObjectModel) {
        self.object = object
        
        guard let displayName = AnyTypeManager.session.displayName(forObjectType: object.objectType) else {
            logger.error("Could not get display name for objectType: \(object.objectType)")
            return nil
        }
        objectTypeDisplayName = displayName
    }
}
