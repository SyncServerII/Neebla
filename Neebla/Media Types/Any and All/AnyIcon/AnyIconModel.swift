//
//  AnyIconModel.swift
//  Neebla
//
//  Created by Christopher G Prince on 2/7/21.
//

import Foundation
import iOSShared

class AnyIconModel: ObservableObject, CommentCountsObserverDelegate, MediaItemBadgeObserverDelegate {
    @Published var mediaItemBadge: MediaItemBadge?
    @Published var unreadCountBadgeText: String?
    var mediaItemCommentCount:CommentCountsObserver!
    let object: ServerObjectModel
    var badgeObserver: MediaItemBadgeObserver!
    
    init(object: ServerObjectModel) {
        self.object = object
        mediaItemCommentCount = CommentCountsObserver(object: object, delegate: self)
        badgeObserver = MediaItemBadgeObserver(object: object, delegate: self)
    }
}
