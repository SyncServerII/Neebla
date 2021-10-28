//
//  MovieObjectType.swift
//  Neebla
//
//  Created by Christopher G Prince on 10/24/21.
//

import Foundation
import iOSBasics
import ChangeResolvers
import iOSShared
import UIKit
import ServerShared

class MovieObjectType: ItemType, DeclarableObject {
    let declaredFiles: [DeclarableFile]
    
    enum MovieObjectTypeError: Error, UserDisplayable {
        case invalidFileLabel
        case badAssetType
        case badObjectType
        case couldNotGetImage
        
        var userDisplayableMessage: (title: String, message: String)? {
            return nil
        }
    }
    
    let displayNameArticle = "a"
    let displayName = "movie"

    // Object declaration
    static let objectType = ObjectType.movie.rawValue

    // A still image to show for icons.
    static let imageDeclaration = FileDeclaration(fileLabel: "image", mimeTypes: [.jpeg], changeResolverName: nil)
    
    static let movieDeclaration = FileDeclaration(fileLabel: "movie", mimeTypes: [.mov], changeResolverName: nil)
    
    init() {
        declaredFiles = [CommentFile.declaration, Self.imageDeclaration, Self.movieDeclaration, MediaItemAttributes.declaration]
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
            throw MovieObjectTypeError.invalidFileLabel
        }
        
        return try Files.createTemporary(withPrefix: ItemTypeFiles.filenamePrefix, andExtension: fileExtension, inDirectory: localObjectsDir)
    }
    
    static func uploadNewObjectInstance(assets: MovieObjectTypeAssets, sharingGroupUUID: UUID) throws {
        // Need to first save these files locally. And reference them by ServerFileModel's.

        let imageFileUUID = UUID()
        let movieFileUUID = UUID()
        let commentFileUUID = UUID()
        let mediaItemAttributeUUID = UUID()
        let fileGroupUUID = UUID()
        
        // The intent is that this have one key/value for each file other than the comment file.
        let reconstructionDictionary: [String: String] = [
            Comments.Keys.mediaUUIDKey: imageFileUUID.uuidString,
            Comments.Keys.movieUUIDKey: movieFileUUID.uuidString,
            Comments.Keys.mediaItemAttributesKey: mediaItemAttributeUUID.uuidString
        ]
                
        // These will be the new copies/names.
        let imageFileURL = try createNewFile(for: imageDeclaration.fileLabel)
        let movieFileURL = try createNewFile(for: movieDeclaration.fileLabel)

        _ = try FileManager.default.replaceItemAt(imageFileURL, withItemAt: assets.thumbnailFile, backupItemName: nil, options: [])
        _ = try FileManager.default.replaceItemAt(movieFileURL, withItemAt: assets.movieFile, backupItemName: nil, options: [])

        let objectModel = try ServerObjectModel(db: Services.session.db, sharingGroupUUID: sharingGroupUUID, fileGroupUUID: fileGroupUUID, objectType: objectType, creationDate: Date(), updateCreationDate: true)
        try objectModel.insert()
        
        let imageFileModel = try ServerFileModel(db: Services.session.db, fileGroupUUID: fileGroupUUID, fileUUID: imageFileUUID, fileLabel: imageDeclaration.fileLabel, downloadStatus: .downloaded, url: imageFileURL)
        try imageFileModel.insert()

        let movieFileModel = try ServerFileModel(db: Services.session.db, fileGroupUUID: fileGroupUUID, fileUUID: movieFileUUID, fileLabel: movieDeclaration.fileLabel, downloadStatus: .downloaded, url: movieFileURL)
        try movieFileModel.insert()
        
        let (mediaItemAttributesUpload, _) = try MediaItemAttributes.createUpload(fileUUID: mediaItemAttributeUUID, fileGroupUUID: fileGroupUUID)
        
        let commentUpload = try CommentFile.createUpload(fileUUID: commentFileUUID, fileGroupUUID: fileGroupUUID, reconstructionDictionary: reconstructionDictionary)

        let imageUpload = FileUpload.forOthers(fileLabel: imageDeclaration.fileLabel, dataSource: .immutable(imageFileURL), uuid: imageFileUUID)
        let movieUpload = FileUpload.forOthers(fileLabel: movieDeclaration.fileLabel, dataSource: .immutable(movieFileURL), uuid: movieFileUUID)
        
        let pushNotificationText = try PushNotificationMessage.forUpload(of: objectModel)
        let upload = ObjectUpload(objectType: objectType, fileGroupUUID: fileGroupUUID, sharingGroupUUID: sharingGroupUUID, pushNotificationMessage: pushNotificationText, uploads: [commentUpload, imageUpload, movieUpload, mediaItemAttributesUpload])

        try Services.session.syncServer.queue(upload:upload)
    }
}

extension MovieObjectType: ObjectDownloadHandler {
    func getFileLabel(appMetaData: String) -> String? {
        return nil
    }
    
    func objectWasDownloaded(object: DownloadedObject) throws {
        try objectWasDownloaded(object: object, itemType: Self.self)
    }
}

extension MovieObjectType: MediaTypeActivityItems {
    func activityItems(forObject object: ServerObjectModel) throws -> [Any] {
        guard object.objectType == objectType else {
            throw MovieObjectTypeError.badObjectType
        }
        
        guard let imageFileModel = try? ServerFileModel.getFileFor(fileLabel: Self.imageDeclaration.fileLabel, withFileGroupUUID: object.fileGroupUUID) else {
            throw MovieObjectTypeError.couldNotGetImage
        }
        
        guard let fullSizeImageURL = imageFileModel.url else {
            throw MovieObjectTypeError.couldNotGetImage
        }
        
        guard let imageData = try? Data(contentsOf: fullSizeImageURL),
            let image = UIImage(data: imageData) else {
            throw MovieObjectTypeError.couldNotGetImage
        }
 
        return [image]
    }
}

