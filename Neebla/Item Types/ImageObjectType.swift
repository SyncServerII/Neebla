
import Foundation
import iOSBasics
import ChangeResolvers
import UIKit
import iOSShared

class ImageObjectType: ItemType, DeclarableObject {
    enum ImageObjectTypeError: Error {
        case couldNotGetJPEGData
        case invalidFileLabel
    }
    
    static let objectType: String = "image"
    static let imageFilenameExtension = "jpeg"
    
    static let commentDeclaration = FileDeclaration(fileLabel: "comments", mimeType: .text, changeResolverName: CommentFile.changeResolverName)
    static let imageDeclaration = FileDeclaration(fileLabel: "image", mimeType: .jpeg, changeResolverName: nil)
    
    static func createNewFile(for fileLabel: String) throws -> URL {
        let localObjectsDir = Files.getDocumentsDirectory().appendingPathComponent(
            LocalFiles.objectsDir)
        try Files.createDirectoryIfNeeded(localObjectsDir)

        let fileExtension: String
        
        switch fileLabel {
        case Self.commentDeclaration.fileLabel:
            fileExtension = Self.commentFilenameExtension
        case Self.imageDeclaration.fileLabel:
            fileExtension = Self.imageFilenameExtension
        default:
            throw ImageObjectTypeError.invalidFileLabel
        }
        
        return try Files.createTemporary(withPrefix: Self.filenamePrefix, andExtension: fileExtension, inDirectory: localObjectsDir)
    }
    
    let declaredFiles: [DeclarableFile]

    func getFileLabel(appMetaData: String) -> String? {
        return nil
    }

    static func uploadNewObjectInstance(image: UIImage, sharingGroupUUID: UUID) throws {
        // Need to first save these files locally. And reference them by ServerFileModel's.

        let imageFileUUID = UUID()
        let commentFileUUID = UUID()
        let fileGroupUUID = UUID()

        let commentFile = CommentFile()
        let commentFileData = try commentFile.getData()
        
        let commentFileURL = try createNewFile(for: commentDeclaration.fileLabel)
        try commentFileData.write(to: commentFileURL)
        
        guard let jpegData = image.jpegData(compressionQuality: SettingsModel.jpegQuality) else {
            throw ImageObjectTypeError.couldNotGetJPEGData
        }
        let imageFileURL = try createNewFile(for: imageDeclaration.fileLabel)
        try jpegData.write(to: imageFileURL)
        
        let objectModel = try ServerObjectModel(db: Services.session.db, sharingGroupUUID: sharingGroupUUID, fileGroupUUID: fileGroupUUID, objectType: objectType)
        try objectModel.insert()
        
        let imageFileModel = try ServerFileModel(db: Services.session.db, fileGroupUUID: fileGroupUUID, fileUUID: imageFileUUID, fileLabel: imageDeclaration.fileLabel, url: imageFileURL)
        try imageFileModel.insert()
        
        let commentFileModel = try ServerFileModel(db: Services.session.db, fileGroupUUID: fileGroupUUID, fileUUID: commentFileUUID, fileLabel: commentDeclaration.fileLabel, url: commentFileURL)
        try commentFileModel.insert()
        
        let commentUpload = FileUpload(fileLabel: commentDeclaration.fileLabel, dataSource: .copy(commentFileURL), uuid: commentFileUUID)
        let imageUpload = FileUpload(fileLabel: imageDeclaration.fileLabel, dataSource: .immutable(imageFileURL), uuid: imageFileUUID)
        let upload = ObjectUpload(objectType: objectType, fileGroupUUID: fileGroupUUID, sharingGroupUUID: sharingGroupUUID, uploads: [commentUpload, imageUpload])

        try Services.session.serverInterface.syncServer.queue(upload:upload)
    }

    init() {
        declaredFiles = [Self.commentDeclaration, Self.imageDeclaration]
    }
}

extension ImageObjectType: ObjectDownloadHandler {    
    func objectWasDownloaded(object: DownloadedObject) throws {
        try object.upsert(db: Services.session.db, itemType: Self.self)
    }
}
