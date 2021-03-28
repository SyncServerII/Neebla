//
//  AnyIconModel.swift
//  Neebla
//
//  Created by Christopher G Prince on 2/7/21.
//

import Foundation
import iOSShared

class AnyIconModel: ObservableObject, MediaItemUnreadCountDelegate {
    @Published var mediaItemUnreadCountBadgeText: String?
    var mediaItemUnreadCount:MediaItemUnreadCount!
    let object: ServerObjectModel
    
    init(object: ServerObjectModel) {
        self.object = object
        mediaItemUnreadCount = MediaItemUnreadCount(object: object, delegate: self)
    }
}
