//
//  DownloadIndicator.swift
//  Neebla
//
//  Created by Christopher G Prince on 6/1/21.
//

import Foundation
import iOSBasics
import SQLite

class DownloadIndicator {
    // Check to see if the download indicator should be set to true.
    // See https://github.com/SyncServerII/Neebla/issues/15#issuecomment-852567995
    static func seeIfNeedsDownload(albumModel: AlbumModel, summaries:[SharingGroup.FileGroupSummary]) throws {
        guard !albumModel.needsDownload else {
            // The download indicator was already true. No need to do this work.
            return
        }
        
        var needsDownload = try summaries.informUserAboutSharingGroup()
        
        if !needsDownload && albumModel.lastSyncDateHasExpired  {
            let downloads = try Services.session.syncServer.objectsNeedingDownload(sharingGroupUUID: albumModel.sharingGroupUUID)
            needsDownload = downloads.count > 0
        }
        
        if needsDownload {
            try albumModel.update(setters:
                        AlbumModel.needsDownloadField.description <- true)
            albumModel.postNeedsDownloadUpdateNotification()
        }
    }
    
    // Call this after doing a generic (not album specific) sync.
    static func updateAlbumLastSyncDates(db: Connection) throws {
        let albums = try AlbumModel.fetch(db: db)
        let now = Date()
        
        for album in albums {
            guard !album.deleted else {
                return
            }
            
            try album.update(setters: AlbumModel.lastSyncDateField.description <- now)
        }
    }
}
