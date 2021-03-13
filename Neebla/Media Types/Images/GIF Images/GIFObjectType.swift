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

struct GIFObjectTypeAssets: UploadableMediaAssets {
    enum GIFObjectTypeAssetsError: Error {
        case badMimeType
    }
    
    static let allowedMimeTypes: Set<MimeType> = [.gif]
    
    // Mime type of the image
    let mimeType: MimeType
    
    // File reference to gif. This needs to be movied/copied to a permanent location in the app.
    let gifURL: URL
    
    init(mimeType: MimeType, gifURL: URL) throws {
        guard Self.allowedMimeTypes.contains(mimeType) else {
            throw GIFObjectTypeAssetsError.badMimeType
        }
        
        self.mimeType = mimeType
        self.gifURL = gifURL
    }
}

class GIFObjectType: ItemType, DeclarableObject {
    enum GIFObjectTypeError: Error {
        case invalidFileLabel
        case badAssetType
        case badObjectType
        case couldNotGetImage
        case noMimeType
    }

    let displayNameArticle = "a"
    let displayName = "gif"

    // Object declaration
    static let objectType: String = "gif"
    static let commentDeclaration = FileDeclaration(fileLabel: FileLabels.comments, mimeTypes: [.text], changeResolverName: CommentFile.changeResolverName)
    static let gifDeclaration = FileDeclaration(fileLabel: "gif", mimeTypes: [.gif], changeResolverName: nil)
    
    static func createNewFile(for fileLabel: String, mimeType: MimeType? = nil) throws -> URL {
        let localObjectsDir = Files.getDocumentsDirectory().appendingPathComponent(
            LocalFiles.objectsDir)
        let fileExtension: String
        
        switch fileLabel {
        case Self.commentDeclaration.fileLabel:
            fileExtension = Self.commentFilenameExtension
        case Self.gifDeclaration.fileLabel:
            guard let mimeType = mimeType else {
                throw GIFObjectTypeError.noMimeType
            }
            fileExtension = mimeType.fileNameExtension
        default:
            throw GIFObjectTypeError.invalidFileLabel
        }
        
        return try Files.createTemporary(withPrefix: Self.filenamePrefix, andExtension: fileExtension, inDirectory: localObjectsDir)
    }
    
    let declaredFiles: [DeclarableFile]
    
    static func uploadNewObjectInstance(assets: GIFObjectTypeAssets, sharingGroupUUID: UUID) throws {
        // Need to first save these files locally. And reference them by ServerFileModel's.

        let gifFileUUID = UUID()
        let commentFileUUID = UUID()
        let fileGroupUUID = UUID()
        
        let currentUserName = try SettingsModel.userName(db: Services.session.db)
        let commentFileData = try Comments.createInitialFile(mediaTitle: currentUserName, reconstructionDictionary: [
            Comments.Keys.mediaUUIDKey:gifFileUUID.uuidString
        ])
        
        let commentFileURL = try createNewFile(for: commentDeclaration.fileLabel)
        try commentFileData.write(to: commentFileURL)
        
        let gifFileURL = try createNewFile(for: gifDeclaration.fileLabel, mimeType: assets.mimeType)
        _ = try FileManager.default.replaceItemAt(gifFileURL, withItemAt: assets.gifURL, backupItemName: nil, options: [])

        let objectModel = try ServerObjectModel(db: Services.session.db, sharingGroupUUID: sharingGroupUUID, fileGroupUUID: fileGroupUUID, objectType: objectType, creationDate: Date(), updateCreationDate: true)
        try objectModel.insert()
        
        let gifFileModel = try ServerFileModel(db: Services.session.db, fileGroupUUID: fileGroupUUID, fileUUID: gifFileUUID, fileLabel: gifDeclaration.fileLabel, downloadStatus: .downloaded, url: gifFileURL)
        try gifFileModel.insert()
        
        let commentFileModel = try ServerFileModel(db: Services.session.db, fileGroupUUID: fileGroupUUID, fileUUID: commentFileUUID, fileLabel: commentDeclaration.fileLabel, downloadStatus: .downloaded, url: commentFileURL)
        try commentFileModel.insert()
        
        let commentUpload = FileUpload(fileLabel: commentDeclaration.fileLabel, dataSource: .copy(commentFileURL), uuid: commentFileUUID)
        let gifUpload = FileUpload(fileLabel: gifDeclaration.fileLabel, mimeType: assets.mimeType, dataSource: .immutable(gifFileURL), uuid: gifFileUUID)
        
        let pushNotificationText = try PushNotificationMessage.forUpload(of: objectModel)
        let upload = ObjectUpload(objectType: objectType, fileGroupUUID: fileGroupUUID, sharingGroupUUID: sharingGroupUUID, pushNotificationMessage: pushNotificationText, uploads: [commentUpload, gifUpload])

        try Services.session.syncServer.queue(upload:upload)
    }

    init() {
        declaredFiles = [Self.commentDeclaration, Self.gifDeclaration]
    }
}

extension GIFObjectType: ObjectDownloadHandler {
    func getFileLabel(appMetaData: String) -> String? {
        return nil
    }
    
    func objectWasDownloaded(object: DownloadedObject) throws {
        try object.upsert(db: Services.session.db, itemType: Self.self)
        
        let files = object.downloads.map { FileToDownload(uuid: $0.uuid, fileVersion: $0.fileVersion) }
        let downloadObject = ObjectToDownload(fileGroupUUID: object.fileGroupUUID, downloads: files)
        try Services.session.syncServer.markAsDownloaded(object: downloadObject)
        
        try object.downloads.update(db: Services.session.db, downloadStatus: .downloaded)
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
        
        #warning("Change for GIF?")
        guard let imageData = try? Data(contentsOf: fullSizeGIFURL),
            let image = UIImage(data: imageData) else {
            throw GIFObjectTypeError.couldNotGetImage
        }
 
        return [image]
    }
}
