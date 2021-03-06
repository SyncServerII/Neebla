//
//  ServerInterface+Helpers.swift
//  iOSIntegration
//
//  Created by Christopher G Prince on 10/3/20.
//

import Foundation
import iOSShared
import ServerShared
import iOSBasics

extension ServerInterface {
    func syncHelper(result: SyncResult) throws {
        switch result {
        case .noIndex(let sharingGroups):
            try AlbumModel.upsertSharingGroups(db: Services.session.db, sharingGroups: sharingGroups, updateOptions: .updateDownloadIndicator)
            try DownloadIndicator.updateAlbumLastSyncDates(db: Services.session.db)
            
        case .index(sharingGroupUUID: let sharingGroupUUID, index: let index):
            try index.upsert(db: Services.session.db)
            
            let sharingGroups:[iOSBasics.SharingGroup] = try self.syncServer.sharingGroups()
            
            // We can do an upsert for *all* sharing groups in case they have changed. However, I only want to `updateMostRecentDate` for the specific synced album.
            
            let otherSharingGroups = sharingGroups.filter {$0.sharingGroupUUID != sharingGroupUUID}
            try AlbumModel.upsertSharingGroups(db: Services.session.db, sharingGroups: otherSharingGroups, updateOptions: [])

            let thisSharingGroup = sharingGroups.filter {$0.sharingGroupUUID == sharingGroupUUID}
            try AlbumModel.upsertSharingGroups(db: Services.session.db, sharingGroups: thisSharingGroup, updateOptions: .updateMostRecentDate)

            // Always attempting *some* downloads here. Mutable file uploads have the property that we can't adjust the local version number of the file until we do a download. In user terms what we're trying to deal with is the situation where (a) a user locally added a comment and (b) when a sync occurs it looks like the album needs downloading just to bring that comment file up to date with *the users own comment*.
            try MutableDownloads.triggerMutableFileDownloadsIfNeeded(
                forSharingGroupUUID: sharingGroupUUID)
        }
    }
}
