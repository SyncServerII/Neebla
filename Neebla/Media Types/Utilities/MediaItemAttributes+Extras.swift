//
//  MediaItemAttributes+Extras.swift
//  Neebla
//
//  Created by Christopher G Prince on 6/17/21.
//

import Foundation
import ChangeResolvers
import iOSBasics
import iOSShared
import SQLite

extension MediaItemAttributes {
    private enum MediaTypesError: Error {
        case cannotGetUserId
    }
    
    static var declaration:FileDeclaration { FileDeclaration(fileLabel: FileLabels.mediaItemAttributes, mimeTypes: [.text], changeResolverName: MediaItemAttributes.changeResolverName)
    }
    
    // This for a new MediaItemsAttributes file.
    // Also returns the new `ServerFileModel` locally representing the `MediaItemAttributes`
    // Sets the `notNew` property of the `MediaItemsAttributes` file for this user because this is the creating user-- the media item is not new to them because they just created it.
    static func createUpload(fileUUID: UUID, fileGroupUUID: UUID) throws -> (FileUpload, ServerFileModel) {
        var data = try MediaItemAttributes.emptyFile()
        let mia = try MediaItemAttributes(with: data)
        
        guard let userId = Services.session.userId else {
            throw MediaTypesError.cannotGetUserId
        }
        
        let keyValue = KeyValue.notNew(userId: "\(userId)", used: true)
        try mia.add(keyValue: keyValue)
        data = try mia.getData()
        
        let url = try ItemTypeFiles.createNewMediaItemAttributesFile()
        try data.write(to: url)

        let mediaItemAttributesFileModel = try ServerFileModel(db: Services.session.db, fileGroupUUID: fileGroupUUID, fileUUID: fileUUID, fileLabel: FileLabels.mediaItemAttributes, downloadStatus: .downloaded, url: url)
        try mediaItemAttributesFileModel.insert()

        return (FileUpload.informNoOne(fileLabel: FileLabels.mediaItemAttributes, dataSource: .copy(url), uuid: fileUUID),
                mediaItemAttributesFileModel)
    }
    
    // This for a new MediaItemsAttributes file.
    // Returns the `ServerFileModel` locally representing the `MediaItemAttributes`
    static func queueUpload(fileUUID: UUID, fileGroupUUID: UUID, sharingGroupUUID: UUID, objectType: ObjectType) throws -> ServerFileModel {
    
        let (fileUpload, miaFileModel) = try createUpload(fileUUID: fileUUID, fileGroupUUID: fileGroupUUID)
        
        let upload = ObjectUpload(objectType: objectType.rawValue, fileGroupUUID: fileGroupUUID, sharingGroupUUID: sharingGroupUUID, pushNotificationMessage: nil, uploads: [fileUpload])

        try Services.session.syncServer.queue(upload:upload)
        
        return miaFileModel
    }

    static func getKeywords(fromCSV csv: String?) -> Set<String>? {
        guard let csv = csv else {
            return nil
        }
        
        let split = csv.split(separator: ",").map{ String($0) }
        return Set<String>(split)
    }

    func updateKeywords(objectModel: ServerObjectModel) throws {
        var keywordsCSV: String?
        let keywords = getKeywords()
        
        if keywords.count > 0 {
            keywordsCSV = keywords.sorted().joined(separator: ",")
        }
        
        try Self.updateKeywords(from: keywordsCSV, objectModel: objectModel)
    }
    
    // Also sets the field on the model.
    static func updateKeywords(from keywords: Set<String>?, objectModel: ServerObjectModel) throws {
        let keywordsCSV = keywords?.sorted().joined(separator: ",")
        try Self.updateKeywords(from: keywordsCSV, objectModel: objectModel)
    }
    
    private static func updateKeywords(from keywordsCSV: String?, objectModel: ServerObjectModel) throws {
        if objectModel.keywords != keywordsCSV {
            try objectModel.update(setters: ServerObjectModel.keywordsField.description <- keywordsCSV)
            objectModel.keywords = keywordsCSV
        }
    }
}

