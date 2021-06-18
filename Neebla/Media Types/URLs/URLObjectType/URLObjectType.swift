
import Foundation
import iOSBasics
import ChangeResolvers
import iOSShared
import SMLinkPreview
import ServerShared

class URLObjectType: ItemType, DeclarableObject {
    enum URLObjectTypeError: Error {
        case invalidFileLabel
        case couldNotGetJPEGData
        case badAssetType
        case badObjectType
        case couldNotGetURLFile
    }

    static let urlFilenameExtension = "url"
    
    let displayNameArticle = "a"
    let displayName = "URL"

    // Object declaration
    static var objectType = ObjectType.url.rawValue
    
    static let urlDeclaration = FileDeclaration(fileLabel: "url", mimeTypes: [.url], changeResolverName: nil)
    static let commentDeclaration = FileDeclaration(fileLabel: FileLabels.comments, mimeTypes: [.text], changeResolverName: CommentFile.changeResolverName)
    static let previewImageDeclaration = FileDeclaration(fileLabel: "image", mimeTypes: [.jpeg], changeResolverName: nil)

    let declaredFiles: [DeclarableFile]

    init() {
        declaredFiles = [Self.commentDeclaration, Self.urlDeclaration, Self.previewImageDeclaration, MediaItemAttributes.declaration]
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
            
        case Self.urlDeclaration.fileLabel:
            fileExtension = Self.urlFilenameExtension
            
        case Self.previewImageDeclaration.fileLabel:
            fileExtension = MimeType.jpeg.fileNameExtension
            
        default:
            throw URLObjectTypeError.invalidFileLabel
        }
        
        return try Files.createTemporary(withPrefix: ItemTypeFiles.filenamePrefix, andExtension: fileExtension, inDirectory: localObjectsDir)
    }
    
    static func uploadNewObjectInstance(asset: URLObjectTypeAssets, sharingGroupUUID: UUID) throws {
    
        // Optional. Unused if no image preview.
        let imageFileUUID = UUID()
        
        let commentFileUUID = UUID()
        let urlFileUUID = UUID()
        let fileGroupUUID = UUID()
        let mediaItemAttributesUUID = UUID()

        var fileUploads = [FileUpload]()
        
        let objectModel = try ServerObjectModel(db: Services.session.db, sharingGroupUUID: sharingGroupUUID, fileGroupUUID: fileGroupUUID, objectType: objectType, creationDate: Date(), updateCreationDate: true)
        try objectModel.insert()

        // Comment file
        
        // Using `mediaUUIDKey` to reference the UUID for the .url file is a bit odd. (See its definition in Comments.Keys). But, to be consistent with historical usage, I'm keeping it this way.
        var reconstructionDictionary = [Comments.Keys.mediaUUIDKey: urlFileUUID.uuidString]
        if let _ = asset.image {
            reconstructionDictionary[Comments.Keys.urlPreviewImageUUIDKey] = imageFileUUID.uuidString
        }
        
        let currentUserName = try SettingsModel.userName(db: Services.session.db)
        let commentFileData = try Comments.createInitialFile(mediaTitle: currentUserName, reconstructionDictionary: reconstructionDictionary)
        let commentFileURL = try createNewFile(for: commentDeclaration.fileLabel)
        try commentFileData.write(to: commentFileURL)
        
        let commentFileModel = try ServerFileModel(db: Services.session.db, fileGroupUUID: fileGroupUUID, fileUUID: commentFileUUID, fileLabel: commentDeclaration.fileLabel, downloadStatus: .downloaded, url: commentFileURL)
        try commentFileModel.insert()

        let commentUpload = FileUpload.forOthers(fileLabel: commentDeclaration.fileLabel, dataSource: .copy(commentFileURL), uuid: commentFileUUID)
        fileUploads += [commentUpload]
        
        // Media item attributes file
        
        let (mediaItemAttributesUpload, _) = try MediaItemAttributes.createUpload(fileUUID: mediaItemAttributesUUID, fileGroupUUID: fileGroupUUID)
        fileUploads += [mediaItemAttributesUpload]
        
        // URL file
        let urlFileURL = try createNewFile(for: urlDeclaration.fileLabel)
        let imageType = asset.image?.imageType
        let urlFileContents = URLFile.URLFileContents(url: asset.linkData.url, title: asset.linkData.title, imageType: imageType)
        try URLFile.create(contents: urlFileContents, localFile: urlFileURL)
        
        let urlFileModel = try ServerFileModel(db: Services.session.db, fileGroupUUID: fileGroupUUID, fileUUID: urlFileUUID, fileLabel: urlDeclaration.fileLabel, downloadStatus: .downloaded, url: urlFileURL)
        try urlFileModel.insert()

        let urlFileUpload = FileUpload.forOthers(fileLabel: urlDeclaration.fileLabel, dataSource: .immutable(urlFileURL), uuid: urlFileUUID)
        fileUploads += [urlFileUpload]
            
        // Optional image preview file
        if let loadedImage = asset.image {
            let jpegQuality = try SettingsModel.jpegQuality(db: Services.session.db)
            
            guard let jpegData = loadedImage.image.jpegData(compressionQuality: jpegQuality) else {
                throw URLObjectTypeError.couldNotGetJPEGData
            }
            let imageFileURL = try createNewFile(for: previewImageDeclaration.fileLabel)
            try jpegData.write(to: imageFileURL)
            
            let imageFileModel = try ServerFileModel(db: Services.session.db, fileGroupUUID: fileGroupUUID, fileUUID: imageFileUUID, fileLabel: previewImageDeclaration.fileLabel, downloadStatus: .downloaded, url: imageFileURL)
            try imageFileModel.insert()
            
            let imageUpload = FileUpload.forOthers(fileLabel: previewImageDeclaration.fileLabel, dataSource: .immutable(imageFileURL), uuid: imageFileUUID)
            fileUploads += [imageUpload]
        }

        let pushNotificationText = try PushNotificationMessage.forUpload(of: objectModel)
        let upload = ObjectUpload(objectType: objectType, fileGroupUUID: fileGroupUUID, sharingGroupUUID: sharingGroupUUID, pushNotificationMessage: pushNotificationText, uploads: fileUploads)

        try Services.session.syncServer.queue(upload:upload)
    }
}

extension URLObjectType: ObjectDownloadHandler {
    func getFileLabel(appMetaData: String) -> String? {
        return nil
    }
    
    func objectWasDownloaded(object: DownloadedObject) throws {
        try objectWasDownloaded(object: object, itemType: Self.self)
    }
}

extension URLObjectType: MediaTypeActivityItems {
    func activityItems(forObject object: ServerObjectModel) throws -> [Any] {
        guard object.objectType == objectType else {
            throw URLObjectTypeError.badObjectType
        }
        
        guard let urlFileModel = try? ServerFileModel.getFileFor(fileLabel: Self.urlDeclaration.fileLabel, withFileGroupUUID: object.fileGroupUUID) else {
            throw URLObjectTypeError.couldNotGetURLFile
        }

        guard let urlFile = urlFileModel.url else {
            logger.warning("No url with url file!")
            throw URLObjectTypeError.couldNotGetURLFile
        }
        
        guard let contents = URLFile.parse(localURLFile: urlFile) else {
            logger.error("Could not get url file contents!")
            throw URLObjectTypeError.couldNotGetURLFile
        }
        
        return [contents.url]
    }
}
