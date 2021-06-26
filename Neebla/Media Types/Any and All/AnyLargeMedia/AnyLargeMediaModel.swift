//
//  AnyLargeMediaModel.swift
//  Neebla
//
//  Created by Christopher G Prince on 6/18/21.
//

import Foundation

class AnyLargeMediaModel: ObservableObject, CommentCountsObserverDelegate, MediaItemBadgeObserverDelegate {
    // This is soley for self's badge. And for .hide functionality.
    @Published var mediaItemBadge: MediaItemBadge?
    
    @Published var unreadCountBadgeText: String?
    private var countsObserver: CommentCountsObserver!
    private var badgeObserver: MediaItemBadgeObserver!
    
    init(object: ServerObjectModel) {
        countsObserver = CommentCountsObserver(object: object, delegate: self)
        badgeObserver = MediaItemBadgeObserver(object: object, delegate: self)
    }
}
