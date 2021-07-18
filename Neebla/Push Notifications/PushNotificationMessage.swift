//
//  PushNotificationMessage.swift
//  Neebla
//
//  Created by Christopher G Prince on 1/15/21.
//

import Foundation

/* If there is an alum name, the server prefixes the push notifications with:
    username, album name:
With no album name, the prefix is:
    username:
*/

class PushNotificationMessage {
    enum PushNotificationError: Error {
        case badObjectType
    }
    
    // The push notification messsage that should be used for the deletion of the object.
    static func forDeletion(of object: ServerObjectModel) throws -> String {
        guard let displayName = AnyTypeManager.session.displayName(forObjectType: object.objectType),
        let displayNameArticle = AnyTypeManager.session.displayNameArticle(forObjectType: object.objectType) else {
            throw PushNotificationError.badObjectType
        }
        
        return "Removed \(displayNameArticle) \(displayName)"
    }

    // The push notification messsage that should be used for the upload of the object.
    static func forUpload(of object: ServerObjectModel) throws -> String {
        guard let displayName = AnyTypeManager.session.displayName(forObjectType: object.objectType),
        let displayNameArticle = AnyTypeManager.session.displayNameArticle(forObjectType: object.objectType) else {
            throw PushNotificationError.badObjectType
        }
        
        return "Added \(displayNameArticle) \(displayName)"
    }
    
    static func forAddingComment(to object: ServerObjectModel) throws -> String {
        guard let displayName = AnyTypeManager.session.displayName(forObjectType: object.objectType),
        let displayNameArticle = AnyTypeManager.session.displayNameArticle(forObjectType: object.objectType) else {
            throw PushNotificationError.badObjectType
        }
        
        return "Added a comment on \(displayNameArticle) \(displayName)"
    }
    
    enum MoveDirection: String {
        case from
        case to
    }
    
    static func forMoving(numberItems: Int, moveDirection: MoveDirection) -> String? {
        var itemTerm = "item"
        if numberItems > 1 {
            itemTerm += "s"
        }

        return "Moved \(numberItems) \(itemTerm) \(moveDirection.rawValue) album."
    }
}
