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
            try AlbumModel.upsertSharingGroups(db: Services.session.db, sharingGroups: sharingGroups)
            
        case .index(sharingGroupUUID: _, index: let index):
            try index.upsert(db: Services.session.db)
            
            let sharingGroups:[iOSBasics.SharingGroup] = try self.syncServer.sharingGroups()
            try AlbumModel.upsertSharingGroups(db: Services.session.db, sharingGroups: sharingGroups)
        }
    }
    
    // Figure out if this file group needs downloading.
    func triggerDownloadIfNeeded(forFileGroupUUID fileGroupUUID: UUID) throws {
       guard let downloadable = try Services.session.syncServer.objectNeedsDownload(fileGroupUUID: fileGroupUUID, includeGone: true) else {
            logger.debug("No objectNeedsDownload")
            return
        }

        let files = downloadable.downloads.map { FileToDownload(uuid: $0.uuid, fileVersion: $0.fileVersion) }
        let downloadObject = ObjectToDownload(fileGroupUUID: downloadable.fileGroupUUID, downloads: files)
        
        try Services.session.syncServer.queue(download: downloadObject)
        logger.info("Started download for object: \(downloadObject.fileGroupUUID)")
    }
}
