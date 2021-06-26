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

extension MediaItemAttributes {
    static var declaration:FileDeclaration { FileDeclaration(fileLabel: FileLabels.mediaItemAttributes, mimeTypes: [.text], changeResolverName: MediaItemAttributes.changeResolverName)
    }
    
    // This for a new MediaItemsAttributes file.
    // Also returns the new `ServerFileModel` locally representing the `MediaItemAttributes`
    static func createUpload(fileUUID: UUID, fileGroupUUID: UUID) throws -> (FileUpload, ServerFileModel) {
        let data = try MediaItemAttributes.emptyFile()
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
}

