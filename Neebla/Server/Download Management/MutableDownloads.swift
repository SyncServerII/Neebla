//
//  MutableDownloads.swift
//  Neebla
//
//  Created by Christopher G Prince on 2/27/21.
//

import Foundation
import iOSBasics
import iOSShared

class MutableDownloads {
    static func triggerMutableFileDownloadsIfNeeded(forSharingGroupUUID sharingGroupUUID: UUID) throws {
        let downloadables = try Services.session.syncServer.objectsNeedingDownload(sharingGroupUUID: sharingGroupUUID, includeGone: true)

        for downloadableObject in downloadables {
            // If a comment had been added, this would make the file version > 0. File version 0 is uploaded with initial empty comment file.
            let mutableUpdates = downloadableObject.downloads.filter {$0.fileVersion > 0}
            
            // Make sure there were no v0 files in the object. Don't want to do initial downloads of media objects with this. Just downloads of comments (or later perhaps, other mutable files-- if we add them to the app).
            if mutableUpdates.count != downloadableObject.downloads.count {
                continue
            }
            
            let files = downloadableObject.downloads.map { FileToDownload(uuid: $0.uuid, fileVersion: $0.fileVersion) }
            let downloadObject = ObjectToDownload(fileGroupUUID: downloadableObject.fileGroupUUID, downloads: files)
            
            try Services.session.syncServer.queue(download: downloadObject)
            logger.info("Started download for object: \(downloadObject.fileGroupUUID)")
        }
    }
}
