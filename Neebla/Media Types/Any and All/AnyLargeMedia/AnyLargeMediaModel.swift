//
//  AnyLargeMediaModel.swift
//  Neebla
//
//  Created by Christopher G Prince on 6/18/21.
//

import Foundation

class AnyLargeMediaModel: ObservableObject, MediaItemCommentCountsDelegate {
    @Published var mediaItemUnreadCountBadgeText: String?
    private var counts: MediaItemCommentCounts!
    
    init(object: ServerObjectModel) {
        counts = MediaItemCommentCounts(object: object, delegate: self)
    }
}
