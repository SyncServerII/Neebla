//
//  O.swift
//  Neebla
//
//  Created by Christopher G Prince on 6/11/21.
//

import Foundation
import iOSBasics
import SQLite
import iOSShared

enum ObjectDownloadHandlerError: Error {
    case noObject
}

extension ObjectDownloadHandler {
    func updateUnreadCount(object: DownloadedObject, db: Connection) throws {
        var commentFileModel:ServerFileModel?
        var mediaItemAttributesFileModel:ServerFileModel?

        for file in object.downloads {
            guard let fileModel = try ServerFileModel.fetchSingleRow(db: db, where: ServerFileModel.fileUUIDField.description == file.uuid) else {
                throw ObjectDownloadHandlerError.noObject
            }

            switch fileModel.fileLabel {
            case FileLabels.comments:
                commentFileModel = fileModel

            case FileLabels.mediaItemAttributes:
                mediaItemAttributesFileModel = fileModel
                
            default:
                break
            }
        }
        
        if commentFileModel == nil && mediaItemAttributesFileModel == nil {
            // Neither has been updated; no need to update comment counts.
            return
        }
        
        do {
            if commentFileModel == nil {
                commentFileModel = try ServerFileModel.getFileFor(fileLabel: FileLabels.comments, withFileGroupUUID: object.fileGroupUUID)
            }
            
            if mediaItemAttributesFileModel == nil {
                mediaItemAttributesFileModel = try ServerFileModel.getFileFor(fileLabel: FileLabels.mediaItemAttributes, withFileGroupUUID: object.fileGroupUUID)
            }
        } catch let error {
            if let error = error as? ServerFileModel.ServerFileModelError,
                error == .noFileForFileLabel {
                // Not going to consider this an error. One of the files wasn't downloaded yet apparently.
            }
            else {
                throw error
            }
        }
        
        guard let commentFileModel = commentFileModel else {
            return
        }
        
        let commentCounts = try CommentCounts(commentFileModel: commentFileModel, mediaItemAttributesFileModel: mediaItemAttributesFileModel, userId: Services.session.userId)
        try commentCounts.updateUnreadCount()
    }
}
