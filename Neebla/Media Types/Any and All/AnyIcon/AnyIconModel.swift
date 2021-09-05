//
//  AnyIconModel.swift
//  Neebla
//
//  Created by Christopher G Prince on 2/7/21.
//

import Foundation
import iOSShared

class AnyIconModel: ObservableObject, CommentCountsObserverDelegate, MediaItemBadgeObserverDelegate, NewItemBadgeObserverDelegate {
    @Published var mediaItemBadge: MediaItemBadge?
    @Published var unreadCountBadgeText: String?
    @Published var newItem: Bool = false
    var mediaItemCommentCount:CommentCountsObserver!
    let object: ServerObjectModel
    var mediaItemBadgeObserver: MediaItemBadgeObserver!
    var newItemObserver: NewItemBadgeObserver!
    
    init(object: ServerObjectModel) {
        self.object = object
        mediaItemCommentCount = CommentCountsObserver(object: object, delegate: self)
        mediaItemBadgeObserver = MediaItemBadgeObserver(object: object, delegate: self)
        newItemObserver = NewItemBadgeObserver(object: object, delegate: self)
    }
}
