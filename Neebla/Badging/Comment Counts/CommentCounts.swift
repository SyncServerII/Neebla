//
//  CommentCounts.swift
//  Neebla
//
//  Created by Christopher G Prince on 6/11/21.
//

import Foundation
import ChangeResolvers
import SQLite
import ServerShared
import iOSBasics

class CommentCounts {
    enum CommentsError: Error {
        case cannotFindObjectModel
        case notBothUserIdAndmediaItemAttributes
    }
    
    private var commentFile: CommentFile?
    private var mediaItemAttributesFile: MediaItemAttributes?
    private let commentFileModel: ServerFileModel
    private var mediaItemAttributesFileModel: ServerFileModel?
    private var userId: String?
    
    // Unread counts in the media item attributes are keyed by userId, so need to pass that. The commentFileModel is not optional because we need that in order to update the read/unread counts in the db. If you give mediaItemAttributesFileModel, you must also give the userId
    init(commentFileModel: ServerFileModel, commentFile: CommentFile? = nil, mediaItemAttributesFileModel:ServerFileModel? = nil, userId: UserId? = nil) throws {

        let params = ([mediaItemAttributesFileModel as Any, userId as Any]).compactMap {$0}
        guard params.count == 0 || params.count == 2 else {
            throw CommentsError.notBothUserIdAndmediaItemAttributes
        }
        
        if let userId = userId {
            self.userId = "\(userId)"
        }
        self.commentFileModel = commentFileModel
        self.mediaItemAttributesFileModel = mediaItemAttributesFileModel
        
        if let commentFile = commentFile {
            self.commentFile = commentFile
        }
        else if let url = commentFileModel.url {
            self.commentFile = try CommentFile(with: url)
        }
        
        if let url = mediaItemAttributesFileModel?.url {
            let data = try Data(contentsOf: url)
            self.mediaItemAttributesFile = try MediaItemAttributes(with: data)
        }
    }
    
    // Update the unread count for the comment file and its parent object to current values.
    func updateUnreadCount() throws {
        var currentReadCount = commentFileModel.readCount ?? 0
        
        if let userId = userId,
            let mediaItemAttributesFile = mediaItemAttributesFile {
            let result = mediaItemAttributesFile.get(type: .readCount, key: userId)
            switch result {
            case .readCount(userId: _, readCount: let readCount):
                if let readCount = readCount {
                    // Max in case the media item attribute better reflects
                    // the users reading progress.
                    currentReadCount = max(currentReadCount, readCount)
                }
            default:
                break
            }
        }
        
        guard let commentFile = commentFile else {
            return
        }
        
        let currentUnreadCount = max(commentFile.count - currentReadCount, 0)
        
        try setUnreadCount(unreadCount: currentUnreadCount)
    }
    
    // Sets `unreadCount` to 0 and `readCount` to the number of comments in the comment file.
    func markAllRead(object: ServerObjectModel) throws {
        guard let commentFile = commentFile else {
            return
        }

        try setUnreadCount(unreadCount: 0)
        if commentFileModel.readCount != commentFile.count {
            try commentFileModel.update(setters: ServerFileModel.readCountField.description <- commentFile.count)
        }
        
        // TODO: Currently only going to do this if there is already a file for MediaItemAttributes-- later I want to create and upload a file if it's not there already. See https://github.com/SyncServerII/Neebla/issues/16
        if let userId = userId,
            let mediaItemAttributesFileModel = mediaItemAttributesFileModel {
            
            var update = false
            if mediaItemAttributesFileModel.readCount == nil {
                update = true
            }
            else if let modelReadCount = mediaItemAttributesFileModel.readCount,
                commentFile.count > modelReadCount,
                // Don't bother writing an unread count of zero-- that just indicates no comments.
                commentFile.count > 0 {
                update = true
            }
            
            if update {
                try mediaItemAttributesFileModel.update(setters: ServerFileModel.readCountField.description <- commentFile.count)
                
                let encoder = JSONEncoder()
                let keyValue1 = KeyValue.readCount(userId: userId, readCount: commentFile.count)
                let data = try encoder.encode(keyValue1)

                let file = FileUpload.informNoOne(fileLabel: FileLabels.mediaItemAttributes, dataSource: .data(data), uuid: mediaItemAttributesFileModel.fileUUID)
                let upload = ObjectUpload(objectType: object.objectType, fileGroupUUID: mediaItemAttributesFileModel.fileGroupUUID, sharingGroupUUID: object.sharingGroupUUID, uploads: [file])
                try Services.session.syncServer.queue(upload: upload)
            }
        }
    }
    
    // Set the unread count to `unreadCount` for the commentFileModel and its "parent" ServerObjectModel
    private func setUnreadCount(unreadCount:Int) throws {
        if commentFileModel.unreadCount != unreadCount {
            try commentFileModel.update(setters: ServerFileModel.unreadCountField.description <- unreadCount)
        }
        
        guard let objectModel = try ServerObjectModel.fetchSingleRow(db: commentFileModel.db, where: ServerObjectModel.fileGroupUUIDField.description == commentFileModel.fileGroupUUID) else {
            throw CommentsError.cannotFindObjectModel
        }
        
        if objectModel.unreadCount != unreadCount {
            try objectModel.update(setters: ServerObjectModel.unreadCountField.description <- unreadCount)
            commentFileModel.postUnreadCountUpdateNotification(sharingGroupUUID: objectModel.sharingGroupUUID)
        }
    }
}
