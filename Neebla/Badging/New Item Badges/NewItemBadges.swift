//
//  NewItemBadges.swift
//  Neebla
//
//  Created by Christopher G Prince on 8/28/21.
//

import Foundation
import SQLite

class NewItemBadges {
    // This doesn't update the server. Don't want to flood it with requests.
    static func markAllNotNew(for objects:[ServerObjectModel]) throws {
        guard objects.count > 0 else {
            return
        }
        
        for object in objects {
            if object.new {
                object.new = false
                try object.update(setters: ServerObjectModel.newField.description <- false)
                object.postNewUpdateNotification()
            }
        }
    }
}
