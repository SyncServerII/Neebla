
import Foundation
import iOSBasics
import ChangeResolvers
import SQLite
import iOSShared

class Comments {
    let displayName = "comment"
    
    // Create an initial comment file.
    // The `reconstructionDictionary` has metadata. See comment in Comments+Keys.swift. The keys should *not* conflict with the keys used in the comments.
    // Returns Data that can be uploaded to the server representing the initial comment file.
    static func createInitialFile(mediaTitle:String?, reconstructionDictionary: [String: String]) throws -> Data {
        var commentFile = CommentFile()
        commentFile[Comments.Keys.mediaTitleKey] = mediaTitle
        
        for (key, value) in reconstructionDictionary {
            commentFile[key] = value
        }
        
        return try commentFile.getData()
    }
    
    // Upload a change to a comment file.
    // The `fileUUID` references the comment file within the object-- just a convenience. We could get it given the `object` and the file label also.
    static func queueUpload(fileUUID: UUID, comment: Data, object: ServerObjectModel) throws {
        let file = FileUpload.forOthers(fileLabel: FileLabels.comments, dataSource: .data(comment), uuid: fileUUID)
        
        let pushNotificationText = try PushNotificationMessage.forAddingComment(to: object)
        let upload = ObjectUpload(objectType: object.objectType, fileGroupUUID: object.fileGroupUUID, sharingGroupUUID: object.sharingGroupUUID, pushNotificationMessage: pushNotificationText, uploads: [file])
        
        try Services.session.syncServer.queue(upload: upload)
    }
    
    // Save of comment file from a local change.
    static func save(commentFile: CommentFile, commentFileModel:ServerFileModel, object: ServerObjectModel) throws {
        var commentFileModel = commentFileModel
        let commentFileURL: URL
        
        if let url = commentFileModel.url {
            commentFileURL = url
        }
        else {
            commentFileURL = try ItemTypeFiles.createNewCommentFile()
            commentFileModel = try commentFileModel.update(setters: ServerFileModel.urlField.description <- commentFileURL)
        }
        
        try commentFile.save(toFile: commentFileURL)
        
        // Since this a local change, we take this as "user has read all comments".
        let mediaItemAttributesFileModel = try? ServerFileModel.getFileFor(fileLabel: FileLabels.mediaItemAttributes, withFileGroupUUID: commentFileModel.fileGroupUUID)
        let commentCounts = try CommentCounts(commentFileModel: commentFileModel, commentFile: commentFile, mediaItemAttributesFileModel: mediaItemAttributesFileModel, userId: Services.session.userId)
        try commentCounts.markAllRead(object: object)
        
        let commentUpdateDate = Date()
        try object.update(setters:
            ServerObjectModel.updateDateField.description <- commentUpdateDate)
        object.postUpdateDateChangedNotification()
    }
    
    // The UI-displayable title of media objects are stored in their associated comment file.
    static func displayableMediaTitle(for object: ServerObjectModel) throws -> String? {
        let fileModel = try ServerFileModel.getFileFor(fileLabel: FileLabels.comments, withFileGroupUUID: object.fileGroupUUID )
        guard let fileURL = fileModel.url else {
            return nil
        }
        
        let commentFile = try CommentFile(with: fileURL)
        return commentFile[Comments.Keys.mediaTitleKey] as? String
    }
}

