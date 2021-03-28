//
//  Comments+UnreadCounts.swift
//  Neebla
//
//  Created by Christopher G Prince on 3/27/21.
//

import Foundation
import ChangeResolvers
import iOSShared
import SQLite

extension Comments {
    // Update the unread count for the comment file and its parent object, on the basis of the `commentFileModel.readCount`.
    static func updateUnreadCount(commentFileModel: ServerFileModel) throws {
        guard let url = commentFileModel.url else {
            return
        }
        
        let currentReadCount = commentFileModel.readCount ?? 0
        let commentFile = try CommentFile(with: url)
        let currentUnreadCount = max(commentFile.count - currentReadCount, 0)
        
        try setUnreadCount(commentFileModel: commentFileModel, unreadCount: currentUnreadCount)
    }
    
    static func resetReadCounts(commentFileModel: ServerFileModel) throws {
        guard let url = commentFileModel.url else {
            logger.warning("resetReadCounts: No URL")
            return
        }
        
        let commentFile = try CommentFile(with: url)

        try setUnreadCount(commentFileModel: commentFileModel, unreadCount: 0)
        if commentFileModel.readCount != commentFile.count {
            try commentFileModel.update(setters: ServerFileModel.readCountField.description <- commentFile.count)
        }
    }
    
    enum CommentsError: Error {
        case cannotFindObjectModel
    }
    
    // Set the unread count to `unreadCount` for the commentFileModel and its "parent" ServerObjectModel
    private static func setUnreadCount(commentFileModel: ServerFileModel, unreadCount:Int?) throws {
        if commentFileModel.unreadCount != unreadCount {
            try commentFileModel.update(setters: ServerFileModel.unreadCountField.description <- unreadCount)
        }
        
        guard let objectModel = try ServerObjectModel.fetchSingleRow(db: commentFileModel.db, where: ServerObjectModel.fileGroupUUIDField.description == commentFileModel.fileGroupUUID) else {
            throw CommentsError.cannotFindObjectModel
        }
        
        let unreadCount = unreadCount ?? 0

        if objectModel.unreadCount != unreadCount {
            try objectModel.update(setters: ServerObjectModel.unreadCountField.description <- unreadCount)
            commentFileModel.postUnreadCountUpdateNotification(sharingGroupUUID: objectModel.sharingGroupUUID)
        }
    }
}
