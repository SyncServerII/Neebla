
import Foundation
import iOSBasics
import ChangeResolvers
import iOSShared
import UIKit
import ServerShared

class LiveImageObjectType: ItemType, DeclarableObject {
    let declaredFiles: [DeclarableFile]
    
    enum LiveImageObjectTypeError: Error, UserDisplayable {
        case invalidFileLabel
        case badAssetType
        case couldNotLoadHEIC
        case couldNotGetJPEGData
        case imageConversionFailed(String)
        case badObjectType
        case couldNotGetImage
        case badAspectRatio
        
        var userDisplayableMessage: (title: String, message: String)? {
            if case .badAspectRatio = self {
                return LiveImageObjectTypeError.badAspectRatio
            }
            return nil
        }
    }
    
    let displayNameArticle = "a"
    let displayName = "live image"

    // Object declaration
    static let objectType = ObjectType.liveImage.rawValue
    
    static let commentDeclaration = FileDeclaration(fileLabel: FileLabels.comments, mimeTypes: [.text], changeResolverName: CommentFile.changeResolverName)
    
    // These can be HEIC or JPEG coming from iOS, but I'm going to convert them all to jpeg and upload/download them that way. I think JPEG's are easier for users to deal with.
    static let imageDeclaration = FileDeclaration(fileLabel: "image", mimeTypes: [.jpeg], changeResolverName: nil)
    
    static let movieDeclaration = FileDeclaration(fileLabel: "movie", mimeTypes: [.mov], changeResolverName: nil)
    
    init() {
        declaredFiles = [Self.commentDeclaration, Self.imageDeclaration, Self.movieDeclaration, MediaItemAttributes.declaration]
    }
    
    static func createNewFile(for fileLabel: String, mimeType: MimeType? = nil) throws -> URL {
        let localObjectsDir = Files.getDocumentsDirectory().appendingPathComponent(
            LocalFiles.objectsDir)
        let fileExtension: String
        
        switch fileLabel {
        case FileLabels.comments:
            return try ItemTypeFiles.createNewCommentFile()
            
        case FileLabels.mediaItemAttributes:
            return try ItemTypeFiles.createNewMediaItemAttributesFile()
            
        case Self.imageDeclaration.fileLabel:
            fileExtension = MimeType.jpeg.fileNameExtension
        case Self.movieDeclaration.fileLabel:
            fileExtension = MimeType.mov.fileNameExtension
            
        default:
            throw LiveImageObjectTypeError.invalidFileLabel
        }
        
        return try Files.createTemporary(withPrefix: ItemTypeFiles.filenamePrefix, andExtension: fileExtension, inDirectory: localObjectsDir)
    }
    
    static func uploadNewObjectInstance(assets: LiveImageObjectTypeAssets, sharingGroupUUID: UUID) throws {
        // Need to first save these files locally. And reference them by ServerFileModel's.

        let imageFileUUID = UUID()
        let movieFileUUID = UUID()
        let commentFileUUID = UUID()
        let mediaItemAttributeUUID = UUID()
        let fileGroupUUID = UUID()

        let currentUserName = try SettingsModel.userName(db: Services.session.db)
        let commentFileData = try Comments.createInitialFile(mediaTitle: currentUserName, reconstructionDictionary: [
            Comments.Keys.mediaUUIDKey: imageFileUUID.uuidString,
            Comments.Keys.movieUUIDKey: movieFileUUID.uuidString
        ])
        
        let commentFileURL = try createNewFile(for: commentDeclaration.fileLabel)
        try commentFileData.write(to: commentFileURL)
        
        // These will be the new copies/names.
        let imageFileURL = try createNewFile(for: imageDeclaration.fileLabel)
        let movieFileURL = try createNewFile(for: movieDeclaration.fileLabel)

        _ = try FileManager.default.replaceItemAt(imageFileURL, withItemAt: assets.imageFile, backupItemName: nil, options: [])
        _ = try FileManager.default.replaceItemAt(movieFileURL, withItemAt: assets.movieFile, backupItemName: nil, options: [])

        let objectModel = try ServerObjectModel(db: Services.session.db, sharingGroupUUID: sharingGroupUUID, fileGroupUUID: fileGroupUUID, objectType: objectType, creationDate: Date(), updateCreationDate: true)
        try objectModel.insert()
        
        let imageFileModel = try ServerFileModel(db: Services.session.db, fileGroupUUID: fileGroupUUID, fileUUID: imageFileUUID, fileLabel: imageDeclaration.fileLabel, downloadStatus: .downloaded, url: imageFileURL)
        try imageFileModel.insert()

        let movieFileModel = try ServerFileModel(db: Services.session.db, fileGroupUUID: fileGroupUUID, fileUUID: movieFileUUID, fileLabel: movieDeclaration.fileLabel, downloadStatus: .downloaded, url: movieFileURL)
        try movieFileModel.insert()
        
        let commentFileModel = try ServerFileModel(db: Services.session.db, fileGroupUUID: fileGroupUUID, fileUUID: commentFileUUID, fileLabel: commentDeclaration.fileLabel, downloadStatus: .downloaded, url: commentFileURL)
        try commentFileModel.insert()
        
        let (mediaItemAttributesUpload, _) = try MediaItemAttributes.createUpload(fileUUID: mediaItemAttributeUUID, fileGroupUUID: fileGroupUUID)

        let commentUpload = FileUpload.forOthers(fileLabel: commentDeclaration.fileLabel, dataSource: .copy(commentFileURL), uuid: commentFileUUID)
        let imageUpload = FileUpload.forOthers(fileLabel: imageDeclaration.fileLabel, dataSource: .immutable(imageFileURL), uuid: imageFileUUID)
        let movieUpload = FileUpload.forOthers(fileLabel: movieDeclaration.fileLabel, dataSource: .immutable(movieFileURL), uuid: movieFileUUID)
        
        let pushNotificationText = try PushNotificationMessage.forUpload(of: objectModel)
        let upload = ObjectUpload(objectType: objectType, fileGroupUUID: fileGroupUUID, sharingGroupUUID: sharingGroupUUID, pushNotificationMessage: pushNotificationText, uploads: [commentUpload, imageUpload, movieUpload, mediaItemAttributesUpload])

        try Services.session.syncServer.queue(upload:upload)
    }
}

extension LiveImageObjectType: ObjectDownloadHandler {
    func getFileLabel(appMetaData: String) -> String? {
        return nil
    }
    
    func objectWasDownloaded(object: DownloadedObject) throws {
        try objectWasDownloaded(object: object, itemType: Self.self)
    }
}


extension LiveImageObjectType: MediaTypeActivityItems {
    func activityItems(forObject object: ServerObjectModel) throws -> [Any] {
        guard object.objectType == objectType else {
            throw LiveImageObjectTypeError.badObjectType
        }
        
        guard let imageFileModel = try? ServerFileModel.getFileFor(fileLabel: Self.imageDeclaration.fileLabel, withFileGroupUUID: object.fileGroupUUID) else {
            throw LiveImageObjectTypeError.couldNotGetImage
        }
        
        guard let fullSizeImageURL = imageFileModel.url else {
            throw LiveImageObjectTypeError.couldNotGetImage
        }
        
        guard let imageData = try? Data(contentsOf: fullSizeImageURL),
            let image = UIImage(data: imageData) else {
            throw LiveImageObjectTypeError.couldNotGetImage
        }
 
        return [image]
    }
}
