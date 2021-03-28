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
    @Published var albumNeedsDownload: Bool = false
    var album:AlbumModel!
    private var albumUnreadCount:AlbumUnreadCount!
    private var albumDownloadIndicator:AlbumDownloadIndicator!
    
    init(album:AlbumModel) {
        self.album = album
        albumUnreadCount = AlbumUnreadCount(album: album, delegate: self)
        albumDownloadIndicator = AlbumDownloadIndicator(album: album, delegate: self)
    }
}
