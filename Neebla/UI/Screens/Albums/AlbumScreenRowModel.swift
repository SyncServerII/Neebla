//
//  AlbumScreenRowModel.swift
//  Neebla
//
//  Created by Christopher G Prince on 2/7/21.
//

import Foundation
import SQLite
import iOSShared

class AlbumScreenRowModel: ObservableObject, AlbumUnreadCountDelegate, AlbumDownloadIndicatorDelegate {

    private var unreadCountUpdateObserver: AnyObject?
    @Published var albumUnreadCountBadgeText:String?
    
    var album:AlbumModel?
    
    // This field reflects the `needsDownload` field of the album, but is split out separately so I can access it as `@Published` to update the UI. Both this field and the `album` are updated by the `albumDownloadIndicator`.
    @Published var albumNeedsDownload: Bool = false
    
    private var albumUnreadCount:AlbumUnreadCount!
    private var albumDownloadIndicator:AlbumDownloadIndicator!
    
    init(album:AlbumModel?) {
        self.album = album
        if let album = album {
            albumUnreadCount = AlbumUnreadCount(album: album, delegate: self)
        }
        albumDownloadIndicator = AlbumDownloadIndicator(delegate: self)
    }
}
