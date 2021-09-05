//
//  ObjectDownloadHandler+MediaItemBadges.swift
//  Neebla
//
//  Created by Christopher G Prince on 6/15/21.
//

import Foundation
import iOSBasics
import SQLite
import iOSShared
import ChangeResolvers

extension ObjectDownloadHandler {
    func updateMediaItemBadge(object: DownloadedObject, db: Connection) throws {
        guard let mediaItemAttributesFileModel = try ServerFileModel.getFileFor(fileLabel: FileLabels.mediaItemAttributes, from: object) else {
            logger.warning("No mediaItemAttributes ServerFileModel for object")
            return
        }

        // We have the file model. We *must* have the object model as well.
        guard let objectModel = try ServerObjectModel.fetchSingleRow(db: db, where: ServerObjectModel.fileGroupUUIDField.description == object.fileGroupUUID) else {
            throw DatabaseModelError.notExactlyOneRow
        }
        
        // Read the media item attributes file and update the model
        
        guard let url = mediaItemAttributesFileModel.url else {
            logger.debug("No URL in mediaItemAttributesFileModel")
            return
        }

        let data = try Data(contentsOf: url)
        let mia = try MediaItemAttributes(with: data)
        
        guard let userId = Services.session.userId else {
            logger.debug("No userId")
            return
        }
        
        // Currently ignoring badges other than `self`'s because only self's is visible in the UI-- see https://github.com/SyncServerII/Neebla/issues/19
        let badge = mia.get(type: .badge, key: "\(userId)")
        switch badge {
        case .badge(userId: _, code: let badgeCode):
            if let badgeCode = badgeCode,
                let mediaItemBadge = MediaItemBadge(rawValue: badgeCode) {
                try mediaItemAttributesFileModel.update(setters: ServerFileModel.badgeField.description <- mediaItemBadge)
                mediaItemAttributesFileModel.postBadgeUpdateNotification()
            }
        
        default:
            logger.debug("Could not get badge from media item attributess file")
        }
        
        let notNew = mia.get(type: .notNew, key: "\(userId)")
        switch notNew {
        case .notNew(userId: _, used: let used):
            if let used = used, used {
                if objectModel.new {
                    try objectModel.update(setters: ServerObjectModel.newField.description <- false)
                    objectModel.postNewUpdateNotification()
                }
            }
        
        default:
            logger.debug("Could not get notNew from media item attributess file")
        }
        
        try mia.addKeywordsToKeywordModelsIfNeeded(sharingGroupUUID: object.sharingGroupUUID, db: db)
        try mia.updateKeywords(objectModel: objectModel)
    }
}
