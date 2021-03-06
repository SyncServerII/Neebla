//
//  GIFObjectType.swift
//  Neebla
//
//  Created by Christopher G Prince on 3/11/21.
//

import Foundation
import iOSBasics
import ChangeResolvers
import UIKit
import iOSShared
import ServerShared
import Gifu

class GIFObjectType: ItemType, DeclarableObject {
    enum GIFObjectTypeError: Error {
        case invalidFileLabel
        case badAssetType
        case badObjectType
        case couldNotGetImage
        case noMimeType
        case couldNotGetData
    }

    let displayNameArticle = "a"
    let displayName = "gif"

    // Object declaration
    static let objectType = ObjectType.gif.rawValue
        
    // Aside from comment and media item attribute files, GIF objects are structured with a GIF image file, and with a still image jpeg file. The still image is just one image extracted from the GIF.

    static let gifDeclaration = FileDeclaration(fileLabel: "gif", mimeTypes: [GIFObjectTypeAssets.gifMimeType], changeResolverName: nil)
    static let iconDeclaration = FileDeclaration(fileLabel: "icon", mimeTypes: [GIFObjectTypeAssets.iconMimeType], changeResolverName: nil)

    static func createNewFile(for fileLabel: String, mimeType: MimeType? = nil) throws -> URL {
        let localObjectsDir = Files.getDocumentsDirectory().appendingPathComponent(
            LocalFiles.objectsDir)
        let fileExtension: String
        
        switch fileLabel {
        case FileLabels.comments:
            return try ItemTypeFiles.createNewCommentFile()
            
        case FileLabels.mediaItemAttributes:
            return try ItemTypeFiles.createNewMediaItemAttributesFile()
            
        case Self.gifDeclaration.fileLabel:
            guard let mimeType = mimeType else {
                throw GIFObjectTypeError.noMimeType
            }
            fileExtension = mimeType.fileNameExtension
        
        case Self.iconDeclaration.fileLabel:
            guard let mimeType = mimeType else {
                throw GIFObjectTypeError.noMimeType
            }
            fileExtension = mimeType.fileNameExtension
            
        default:
            throw GIFObjectTypeError.invalidFileLabel
        }
        
        return try Files.createTemporary(withPrefix: ItemTypeFiles.filenamePrefix, andExtension: fileExtension, inDirectory: localObjectsDir)
    }
    
    let declaredFiles: [DeclarableFile]
    
    static func uploadNewObjectInstance(assets: GIFObjectTypeAssets, sharingGroupUUID: UUID) throws {
        // Need to first save these files locally. And reference them by ServerFileModel's.

        let gifFileUUID = UUID()
        let iconFileUUID = UUID()
        let commentFileUUID = UUID()
        let mediaItemAttributesUUID = UUID()
        let fileGroupUUID = UUID()
        
        // The intent is that this have one entry per non-comment file
        let reconstructionDictionary: [String: String] = [
            Comments.Keys.mediaUUIDKey:gifFileUUID.uuidString,
            Comments.Keys.gifPreviewImageUUIDKey:iconFileUUID.uuidString,
            Comments.Keys.mediaItemAttributesKey: mediaItemAttributesUUID.uuidString
        ]
        
        let gifFileURL = try createNewFile(for: gifDeclaration.fileLabel, mimeType: GIFObjectTypeAssets.gifMimeType)
        _ = try FileManager.default.replaceItemAt(gifFileURL, withItemAt: assets.gifFile, backupItemName: nil, options: [])
        
        let iconFileURL = try createNewFile(for: iconDeclaration.fileLabel, mimeType: GIFObjectTypeAssets.iconMimeType)
        _ = try FileManager.default.replaceItemAt(iconFileURL, withItemAt: assets.iconFile, backupItemName: nil, options: [])

        let objectModel = try ServerObjectModel(db: Services.session.db, sharingGroupUUID: sharingGroupUUID, fileGroupUUID: fileGroupUUID, objectType: objectType, creationDate: Date(), updateCreationDate: true)
        try objectModel.insert()
        
        let gifFileModel = try ServerFileModel(db: Services.session.db, fileGroupUUID: fileGroupUUID, fileUUID: gifFileUUID, fileLabel: gifDeclaration.fileLabel, downloadStatus: .downloaded, url: gifFileURL)
        try gifFileModel.insert()
        
        let iconFileModel = try ServerFileModel(db: Services.session.db, fileGroupUUID: fileGroupUUID, fileUUID: iconFileUUID, fileLabel: iconDeclaration.fileLabel, downloadStatus: .downloaded, url: iconFileURL)
        try iconFileModel.insert()

        let commentUpload = try CommentFile.createUpload(fileUUID: commentFileUUID, fileGroupUUID: fileGroupUUID, reconstructionDictionary: reconstructionDictionary)

        let (mediaItemAttributesUpload, _) = try MediaItemAttributes.createUpload(fileUUID: mediaItemAttributesUUID, fileGroupUUID: fileGroupUUID)
        
        let gifUpload = FileUpload.forOthers(fileLabel: gifDeclaration.fileLabel, mimeType: GIFObjectTypeAssets.gifMimeType, dataSource: .immutable(gifFileURL), uuid: gifFileUUID)
        let iconUpload = FileUpload.forOthers(fileLabel: iconDeclaration.fileLabel, mimeType: GIFObjectTypeAssets.iconMimeType, dataSource: .immutable(iconFileURL), uuid: iconFileUUID)

        let pushNotificationText = try PushNotificationMessage.forUpload(of: objectModel)
        let upload = ObjectUpload(objectType: objectType, fileGroupUUID: fileGroupUUID, sharingGroupUUID: sharingGroupUUID, pushNotificationMessage: pushNotificationText, uploads: [commentUpload, gifUpload, iconUpload, mediaItemAttributesUpload])

        try Services.session.syncServer.queue(upload:upload)
    }

    init() {
        declaredFiles = [CommentFile.declaration, Self.gifDeclaration, Self.iconDeclaration, MediaItemAttributes.declaration]
    }
}

extension GIFObjectType: ObjectDownloadHandler {
    func getFileLabel(appMetaData: String) -> String? {
        return nil
    }
    
    func objectWasDownloaded(object: DownloadedObject) throws {
        try objectWasDownloaded(object: object, itemType: Self.self)
    }
}

extension GIFObjectType: MediaTypeActivityItems {
    func activityItems(forObject object: ServerObjectModel) throws -> [Any] {
        guard object.objectType == objectType else {
            throw GIFObjectTypeError.badObjectType
        }
        
        guard let gifFileModel = try? ServerFileModel.getFileFor(fileLabel: Self.gifDeclaration.fileLabel, withFileGroupUUID: object.fileGroupUUID) else {
            throw GIFObjectTypeError.couldNotGetImage
        }
        
        guard let fullSizeGIFURL = gifFileModel.url else {
            throw GIFObjectTypeError.couldNotGetImage
        }
        
        // See https://stackoverflow.com/questions/31765148/sharing-gifs-swift
        let data = try Data(contentsOf: fullSizeGIFURL)
        return [data]
    }
}
