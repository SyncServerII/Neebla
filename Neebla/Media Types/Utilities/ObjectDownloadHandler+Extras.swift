//
//  ObjectDownloadHandler+Extras.swift
//  Neebla
//
//  Created by Christopher G Prince on 3/19/21.
//

import Foundation
import iOSBasics
import iOSShared

extension ObjectDownloadHandler {
    func objectWasDownloaded(object: DownloadedObject, itemType: ItemType.Type) throws {
    
        // `backgroundAsssertable` is trying to deal with crashes. See https://github.com/SyncServerII/Neebla/issues/7 and in particular see https://github.com/SyncServerII/Neebla/issues/7#issuecomment-802978539
        
        try Background.session.backgroundAsssertable.syncRun {
            try object.upsert(db: Services.session.db, itemType: itemType)
            
            let files = object.downloads.map { FileToDownload(uuid: $0.uuid, fileVersion: $0.fileVersion) }
            let downloadObject = ObjectToDownload(fileGroupUUID: object.fileGroupUUID, downloads: files)
            try Services.session.syncServer.markAsDownloaded(object: downloadObject)
            
            try object.downloads.update(db: Services.session.db, downloadStatus: .downloaded)
            
            try updateUnreadCount(object: object, db: Services.session.db)
            try updateMediaItemBadge(object: object, db: Services.session.db)
        } expiry: {
            logger.error("objectWasDownloaded: Expiry exceeded")
        }
    }
}
