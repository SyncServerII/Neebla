//
//  ServerFileModel+Comments.swift
//  Neebla
//
//  Created by Christopher G Prince on 7/18/21.
//

import Foundation
import ChangeResolvers
import iOSShared
import ServerShared

extension ServerFileModel {
    // Assumes that `self` references a comment file. Throws an error if there was no comment file.
    func userIdsInComments() throws -> Set<UserId> {
        guard let url = url else {
            throw ServerFileModelError.noURL
        }
        
        let commentFile = try CommentFile(with: url)

        var result = Set<UserId>()
        
        for fixedObject in commentFile {
            guard let dict = fixedObject as? [String: String],
                let message = DiscussionMessage.fromDictionary(dict) else {
                throw ServerFileModelError.couldNotLoadComment
            }
            
            guard let userId = UserId(message.sender.senderId) else {
                throw ServerFileModelError.badUserId
            }
            
            if userId == CommentsViewModel.unknownUserID {
                logger.warning("User id was: CommentsViewModel.unknownUserID: \(CommentsViewModel.unknownUserID)")
                continue
            }
            
            result.insert(userId)
        }
        
        return result
    }
}
