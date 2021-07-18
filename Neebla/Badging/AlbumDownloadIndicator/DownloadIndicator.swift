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
    enum DownloadIndicatorError: Error {
        case albumNotFound
    }
    
    // Check to see if the download indicator should be set to true.
    // See https://github.com/SyncServerII/Neebla/issues/15#issuecomment-852567995
    static func seeIfNeedsDownload(albumModel: AlbumModel, sharingGroup: iOSBasics.SharingGroup) throws {
        guard !albumModel.needsDownload else {
            // The download indicator was already true. No need to do this work.
            return
        }
        
        guard !sharingGroup.deleted else {
            // The sharing group was deleted. We're not displaying that album to the user.
            return
        }
        
        let informUser:InformUserResult =
            try sharingGroup.contentsSummary?.informUserAboutSharingGroup()
                ?? .noInformRecords

        let needsDownload: Bool
        
        if informUser == .noInformRecords && albumModel.lastSyncDateHasExpired {
            /* Status:
                (a) We don't have `inform` records indicating that we should download. But, those may have just expired.
                (b) lastSyncDate has expired. (`lastSyncDate` reflects the generic sync last date-- when a sync with no specific sharing group UUID was given).
                
                Our goal is now to ensure that the user doesn't miss some update. We may show some false positives here, but don't want false negatives. i.e., don't want to user to not see a download indicator but have some update they need to see.
                This could cause false positives because we are planning to have files that never cause UI changes to users. Plus, I'm not taking into account empty albums here.
                See https://github.com/SyncServerII/Neebla/issues/15#issuecomment-850735201
            */

            // `mostRecentDate` reflects the most recent date at which files in the sharing group were last created and/or updated.
            if let localMostRecent = albumModel.mostRecentDate,
                let serverMostRecent = sharingGroup.mostRecentDate {
                
                // Set `needsDownload` to true if the `serverMostRecent` date comes *after* the `localMostRecent` date. I.e., if the server info is more up to date.
                needsDownload = serverMostRecent > localMostRecent
            }
            else {
                needsDownload = true
            }
        }
        else {
            needsDownload = informUser == .inform
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
                continue
            }
            
            try album.update(setters: AlbumModel.lastSyncDateField.description <- now)
        }
    }
    
    // Call this from a sync *with* sharing group UUID given to update the `mostRecentDate` field of a specific album. `mostRecentDate` reflects the date when the specific album was last synced.
    static func updateAlbumMostRecentDate(album:AlbumModel, sharingGroup: SharingGroup) throws {
        if let mostRecentDate = sharingGroup.mostRecentDate {
            try album.update(setters: AlbumModel.mostRecentDateField.description <- mostRecentDate)
        }
    }
    
    static func resetAfterSync(sharingGroupUUID: UUID) throws {
        guard let albumModel = try AlbumModel.fetchSingleRow(db: Services.session.db, where: AlbumModel.sharingGroupUUIDField.description == sharingGroupUUID) else {
            throw DownloadIndicatorError.albumNotFound
        }
        
        guard albumModel.needsDownload else {
            // Doesn't need reset if already false.
            return
        }
        
        try albumModel.update(setters: AlbumModel.needsDownloadField.description <- false)
        albumModel.postNeedsDownloadUpdateNotification()
    }
}
