//
//  MediaItemBadge.swift
//  Neebla
//
//  Created by Christopher G Prince on 6/15/21.
//

import Foundation

// These strings are encoded in Additional Media Attribute files. Don't change the case names. The top to bottom order is the order in which these are displayed in the UI in the `BadgePickerMenu`.
enum MediaItemBadge: String, CaseIterable, Codable {
    case favorite
    case hide
    case none
}

extension MediaItemBadge {
    var displayName: String {
        switch self {
        case .favorite:
            return "Favorite"
        case .hide:
            return "Hide"
        case .none:
            return "No Badge"
        }
    }
    
    var imageName: String? {
        switch self {
        case .hide:
            // Taking care of this with main image. Doesn't seem useful to provide two graphics each indicating `hide`.
            return nil
            
        case .favorite:
            return "Favorite"
            
        case .none:
            return nil
        }
    }
}
