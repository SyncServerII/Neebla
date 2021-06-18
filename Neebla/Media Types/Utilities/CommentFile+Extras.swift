//
//  CommentFile+Extras.swift
//  Neebla
//
//  Created by Christopher G Prince on 6/18/21.
//

import Foundation
import ChangeResolvers
import iOSBasics
import iOSShared

extension CommentFile {
    static var declaration:FileDeclaration { FileDeclaration(fileLabel: FileLabels.comments, mimeTypes: [.text], changeResolverName: CommentFile.changeResolverName)
    }
    
    static func createUpload(fileUUID: UUID, fileGroupUUID: UUID, reconstructionDictionary: [String: String]) throws -> FileUpload {
    
        let currentUserName = try SettingsModel.userName(db: Services.session.db)
        let data = try Comments.createInitialFile(mediaTitle: currentUserName, reconstructionDictionary: reconstructionDictionary)
        let url = try ItemTypeFiles.createNewCommentFile()
        try data.write(to: url)
        
        let commentFileModel = try ServerFileModel(db: Services.session.db, fileGroupUUID: fileGroupUUID, fileUUID: fileUUID, fileLabel: FileLabels.comments, downloadStatus: .downloaded, url: url)
        try commentFileModel.insert()
        
        let commentUpload = FileUpload.forOthers(fileLabel: FileLabels.comments, dataSource: .copy(url), uuid: fileUUID)

        return commentUpload
    }
}
