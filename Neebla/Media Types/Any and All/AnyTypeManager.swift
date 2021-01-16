
import Foundation
import iOSBasics
import iOSShared

class AnyTypeManager {
    enum ItemTypeManagerError: Error {
        case duplicateObjectType
        case couldNotUploadWithAssets
        case couldNotFindObjectType
    }
    
    static let session = AnyTypeManager()
    // These objects don't provide support for pickers because the relationship between object type and picker isn't 1:1
    let objectTypes:[DeclarableObject & ObjectDownloadHandler & ItemType & UploadableMediaType & MediaTypeActivityItems] = [
        ImageObjectType(),
        URLObjectType(),
        LiveImageObjectType()
    ]
    
    // Call this at app launch, only once.
    func setup() throws {
        let allObjectTypes = objectTypes.map {$0.objectType}
        guard allObjectTypes.count == Set<String>(allObjectTypes).count else {
            throw ItemTypeManagerError.duplicateObjectType
        }
        
        for objectType in objectTypes {
            try Services.session.serverInterface.syncServer.register(object: objectType)
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
    
    func displayNameArticle(forObjectType objectType: String) -> String? {
        for type in objectTypes {
            if type.objectType == objectType {
                return type.displayNameArticle
            }
        }
        
        return nil
    }
    
    func uploadNewObject(assets: UploadableMediaAssets, sharingGroupUUID: UUID) throws {
        for type in objectTypes {
            if type.canUpload(assets: assets)  {
                 try type.uploadNewObjectInstance(assets: assets, sharingGroupUUID: sharingGroupUUID)
                 return
            }
        }
        
        throw ItemTypeManagerError.couldNotUploadWithAssets
    }
    
    func activityItems(forObject object: ServerObjectModel) throws -> [Any] {
        for type in objectTypes {
            if type.objectType == object.objectType {
                return try type.activityItems(forObject: object)
            }
        }
        
        throw ItemTypeManagerError.couldNotFindObjectType
    }
}
