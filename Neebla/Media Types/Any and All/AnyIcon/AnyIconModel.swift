//
//  AnyIconModel.swift
//  Neebla
//
//  Created by Christopher G Prince on 2/7/21.
//

import Foundation
import iOSShared

class AnyIconModel: ObservableObject, MediaItemCommentCountsDelegate {
    @Published var mediaItemUnreadCountBadgeText: String?
    var mediaItemCommentCount:MediaItemCommentCounts!
    let object: ServerObjectModel
    
    init(object: ServerObjectModel) {
        self.object = object
        mediaItemCommentCount = MediaItemCommentCounts(object: object, delegate: self)
    }
}
