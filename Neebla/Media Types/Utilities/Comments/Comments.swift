
import Foundation
import iOSBasics
import ChangeResolvers
import SQLite

class Comments {    
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
        let file = FileUpload(fileLabel: FileLabels.comments, dataSource: .data(comment), uuid: fileUUID)
        let upload = ObjectUpload(objectType: object.objectType, fileGroupUUID: object.fileGroupUUID, sharingGroupUUID: object.sharingGroupUUID, uploads: [file])
        try Services.session.syncServer.queue(upload: upload)
    }
    
    static func save(commentFile: CommentFile, commentFileModel:ServerFileModel) throws {
        let commentFileURL: URL
        
        if let url = commentFileModel.url {
            commentFileURL = url
        }
        else {
            commentFileURL = try URLObjectType.createNewFile(for: URLObjectType.commentDeclaration.fileLabel)
            try commentFileModel.update(setters: ServerFileModel.urlField.description <- commentFileURL)
        }
        
        try commentFile.save(toFile: commentFileURL)
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

