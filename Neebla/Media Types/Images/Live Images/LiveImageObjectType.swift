
import Foundation
import iOSBasics
import ChangeResolvers
import iOSShared
import UIKit
import ImageIOSwift
import ImageIOUIKit

class LiveImageObjectType: ItemType, DeclarableObject {
    let declaredFiles: [DeclarableFile]
    
    enum LiveImageObjectTypeError: Error {
        case invalidFileLabel
        case badAssetType
        case couldNotLoadHEIC
        case couldNotGetJPEGData
    }
    
    let displayName = "live image"

    // Object declaration
    static let objectType: String = "liveImage"
    static let commentDeclaration = FileDeclaration(fileLabel: FileLabels.comments, mimeType: .text, changeResolverName: CommentFile.changeResolverName)
    
    // These can be HEIC or JPEG coming from iOS, but I'm going to convert them all to jpeg and upload/download them that way.
    static let imageDeclaration = FileDeclaration(fileLabel: "image", mimeType: .jpeg, changeResolverName: nil)
    
    static let movieDeclaration = FileDeclaration(fileLabel: "movie", mimeType: .mov, changeResolverName: nil)
    
    init() {
        declaredFiles = [Self.commentDeclaration, Self.imageDeclaration, Self.movieDeclaration]
    }
    
    static func createNewFile(for fileLabel: String) throws -> URL {
        let localObjectsDir = Files.getDocumentsDirectory().appendingPathComponent(
            LocalFiles.objectsDir)
        let fileExtension: String
        
        switch fileLabel {
        case Self.commentDeclaration.fileLabel:
            fileExtension = Self.commentFilenameExtension
        case Self.imageDeclaration.fileLabel:
            fileExtension = Self.jpegImageFilenameExtension
        case Self.movieDeclaration.fileLabel:
            fileExtension = Self.quicktimeMovieFilenameExtension
            
        default:
            throw LiveImageObjectTypeError.invalidFileLabel
        }
        
        return try Files.createTemporary(withPrefix: Self.filenamePrefix, andExtension: fileExtension, inDirectory: localObjectsDir)
    }
    
    static func uploadNewObjectInstance(assets: LiveImageObjectTypeAssets, sharingGroupUUID: UUID) throws {
        // Need to first save these files locally. And reference them by ServerFileModel's.

        let imageFileUUID = UUID()
        let movieFileUUID = UUID()
        let commentFileUUID = UUID()
        let fileGroupUUID = UUID()

        let commentFile = CommentFile()
        let commentFileData = try commentFile.getData()
        
        let commentFileURL = try createNewFile(for: commentDeclaration.fileLabel)
        try commentFileData.write(to: commentFileURL)
        
        // These will be the new copies/names.
        let imageFileURL = try createNewFile(for: imageDeclaration.fileLabel)
        let movieFileURL = try createNewFile(for: movieDeclaration.fileLabel)

        switch assets.imageType {
        case .heic:
            // Load the file data, and convert it to jpeg.
            // I started off using a method from here: https://stackoverflow.com/questions/46440308 but I wasn't preserving image orientation. So have shifted to using https://github.com/davbeck/ImageIOSwift
            
            guard let imageSource = ImageSource(url:assets.imageFile),
                let image = imageSource.image(at:0) else {
                throw LiveImageObjectTypeError.couldNotLoadHEIC
            }
            
            // I'm assuming this will always be 1 for our HEIC files, but want to get some data on this.
            logger.debug("Success: imageSource.count: \(imageSource.count)")

            guard let jpegData = image.jpegData(compressionQuality: SettingsModel.jpegQuality) else {
                throw LiveImageObjectTypeError.couldNotGetJPEGData
            }
            try jpegData.write(to: imageFileURL)
            
        case .jpeg:
            _ = try FileManager.default.replaceItemAt(imageFileURL, withItemAt: assets.imageFile, backupItemName: nil, options: [])
        }
        
        _ = try FileManager.default.replaceItemAt(movieFileURL, withItemAt: assets.movieFile, backupItemName: nil, options: [])

        let objectModel = try ServerObjectModel(db: Services.session.db, sharingGroupUUID: sharingGroupUUID, fileGroupUUID: fileGroupUUID, objectType: objectType, creationDate: Date(), updateCreationDate: true)
        try objectModel.insert()
        
        let imageFileModel = try ServerFileModel(db: Services.session.db, fileGroupUUID: fileGroupUUID, fileUUID: imageFileUUID, fileLabel: imageDeclaration.fileLabel, url: imageFileURL)
        try imageFileModel.insert()

        let movieFileModel = try ServerFileModel(db: Services.session.db, fileGroupUUID: fileGroupUUID, fileUUID: movieFileUUID, fileLabel: movieDeclaration.fileLabel, url: movieFileURL)
        try movieFileModel.insert()
        
        let commentFileModel = try ServerFileModel(db: Services.session.db, fileGroupUUID: fileGroupUUID, fileUUID: commentFileUUID, fileLabel: commentDeclaration.fileLabel, url: commentFileURL)
        try commentFileModel.insert()
        
        let commentUpload = FileUpload(fileLabel: commentDeclaration.fileLabel, dataSource: .copy(commentFileURL), uuid: commentFileUUID)
        let imageUpload = FileUpload(fileLabel: imageDeclaration.fileLabel, dataSource: .immutable(imageFileURL), uuid: imageFileUUID)
        let movieUpload = FileUpload(fileLabel: movieDeclaration.fileLabel, dataSource: .immutable(movieFileURL), uuid: movieFileUUID)
        
        let upload = ObjectUpload(objectType: objectType, fileGroupUUID: fileGroupUUID, sharingGroupUUID: sharingGroupUUID, uploads: [commentUpload, imageUpload, movieUpload])

        try Services.session.serverInterface.syncServer.queue(upload:upload)
    }
}

extension LiveImageObjectType: ObjectDownloadHandler {
    func getFileLabel(appMetaData: String) -> String? {
        return nil
    }
    
    func objectWasDownloaded(object: DownloadedObject) throws {
        try object.upsert(db: Services.session.db, itemType: Self.self)
        
        let files = object.downloads.map { FileToDownload(uuid: $0.uuid, fileVersion: $0.fileVersion) }
        let downloadObject = ObjectToDownload(fileGroupUUID: object.fileGroupUUID, downloads: files)
        try Services.session.syncServer.markAsDownloaded(object: downloadObject)
    }
}
