//
//  MediaItemMultipleBadgeViewModel.swift
//  Neebla
//
//  Created by Christopher G Prince on 6/25/21.
//

import Foundation

class MediaItemMultipleBadgeViewModel:ObservableObject, MediaItemBadgesObserverDelegate {
    @Published var mediaItemBadges: Badges?
    var badgesObserver:MediaItemBadgesObserver!
    
    init(object: ServerObjectModel) {
        badgesObserver = MediaItemBadgesObserver(object: object, delegate: self)
    }
}
