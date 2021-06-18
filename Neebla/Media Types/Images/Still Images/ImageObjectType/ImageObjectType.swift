
import Foundation
import iOSBasics
import ChangeResolvers
import UIKit
import iOSShared
import ServerShared

class ImageObjectType: ItemType, DeclarableObject {
    enum ImageObjectTypeError: Error {
        case couldNotGetJPEGData
        case invalidFileLabel
        case badAssetType
        case badObjectType
        case couldNotGetImage
        case noMimeType
    }

    let displayNameArticle = "an"
    let displayName = "image"

    // Object declaration
    static let objectType = ObjectType.image.rawValue
    
    static let imageDeclaration = FileDeclaration(fileLabel: "image", mimeTypes: [.jpeg, .png], changeResolverName: nil)
    
    static func createNewFile(for fileLabel: String, mimeType: MimeType? = nil) throws -> URL {
        let localObjectsDir = Files.getDocumentsDirectory().appendingPathComponent(
            LocalFiles.objectsDir)
        let fileExtension: String
        
        switch fileLabel {
        case FileLabels.mediaItemAttributes:
            return try ItemTypeFiles.createNewMediaItemAttributesFile()
            
        case FileLabels.comments:
            return try ItemTypeFiles.createNewCommentFile()
            
        case Self.imageDeclaration.fileLabel:
            guard let mimeType = mimeType else {
                throw ImageObjectTypeError.noMimeType
            }
            fileExtension = mimeType.fileNameExtension

        default:
            throw ImageObjectTypeError.invalidFileLabel
        }
        
        return try Files.createTemporary(withPrefix: ItemTypeFiles.filenamePrefix, andExtension: fileExtension, inDirectory: localObjectsDir)
    }
    
    let declaredFiles: [DeclarableFile]
    
    static func uploadNewObjectInstance(assets: ImageObjectTypeAssets, sharingGroupUUID: UUID) throws {
        // Need to first save these files locally. And reference them by ServerFileModel's.

        let imageFileUUID = UUID()
        let commentFileUUID = UUID()
        let mediaItemAttributesUUID = UUID()
        let fileGroupUUID = UUID()
        
        // This should have one entry per non-comment file
        let reconstructionDictionary: [String: String] = [
            Comments.Keys.mediaUUIDKey:imageFileUUID.uuidString,
            Comments.Keys.mediaItemAttributesKey: mediaItemAttributesUUID.uuidString
        ]
        
        let imageFileURL = try createNewFile(for: imageDeclaration.fileLabel, mimeType: assets.mimeType)
        _ = try FileManager.default.replaceItemAt(imageFileURL, withItemAt: assets.imageURL, backupItemName: nil, options: [])

        let objectModel = try ServerObjectModel(db: Services.session.db, sharingGroupUUID: sharingGroupUUID, fileGroupUUID: fileGroupUUID, objectType: objectType, creationDate: Date(), updateCreationDate: true)
        try objectModel.insert()
        
        let imageFileModel = try ServerFileModel(db: Services.session.db, fileGroupUUID: fileGroupUUID, fileUUID: imageFileUUID, fileLabel: imageDeclaration.fileLabel, downloadStatus: .downloaded, url: imageFileURL)
        try imageFileModel.insert()
                
        let commentUpload = try CommentFile.createUpload(fileUUID: commentFileUUID, fileGroupUUID: fileGroupUUID, reconstructionDictionary: reconstructionDictionary)

        let (mediaItemAttributesUpload, _) = try MediaItemAttributes.createUpload(fileUUID: mediaItemAttributesUUID, fileGroupUUID: fileGroupUUID)
        
        let imageUpload = FileUpload.forOthers(fileLabel: imageDeclaration.fileLabel, mimeType: assets.mimeType, dataSource: .immutable(imageFileURL), uuid: imageFileUUID)
        
        let pushNotificationText = try PushNotificationMessage.forUpload(of: objectModel)
        let upload = ObjectUpload(objectType: objectType, fileGroupUUID: fileGroupUUID, sharingGroupUUID: sharingGroupUUID, pushNotificationMessage: pushNotificationText, uploads: [commentUpload, imageUpload, mediaItemAttributesUpload])

        try Services.session.syncServer.queue(upload:upload)
    }

    init() {
        declaredFiles = [CommentFile.declaration, Self.imageDeclaration, MediaItemAttributes.declaration]
    }
}

extension ImageObjectType: ObjectDownloadHandler {
    func getFileLabel(appMetaData: String) -> String? {
        return nil
    }
    
    func objectWasDownloaded(object: DownloadedObject) throws {
        try objectWasDownloaded(object: object, itemType: Self.self)
    }
}

extension ImageObjectType: MediaTypeActivityItems {
    func activityItems(forObject object: ServerObjectModel) throws -> [Any] {
        guard object.objectType == objectType else {
            throw ImageObjectTypeError.badObjectType
        }
        
        guard let imageFileModel = try? ServerFileModel.getFileFor(fileLabel: Self.imageDeclaration.fileLabel, withFileGroupUUID: object.fileGroupUUID) else {
            throw ImageObjectTypeError.couldNotGetImage
        }
        
        guard let fullSizeImageURL = imageFileModel.url else {
            throw ImageObjectTypeError.couldNotGetImage
        }
        
        guard let imageData = try? Data(contentsOf: fullSizeImageURL),
            let image = UIImage(data: imageData) else {
            throw ImageObjectTypeError.couldNotGetImage
        }
 
        return [image]
    }
}
