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
            return
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
        
        let badge = mia.get(type: .badge, key: "\(userId)")
        switch badge {
        case .badge(userId: _, code: let badgeCode):
            if let badgeCode = badgeCode,
                let mediaItemBadge = MediaItemBadge(rawValue: badgeCode) {
                try mediaItemAttributesFileModel.update(setters: ServerFileModel.badgeField.description <- mediaItemBadge)
            }
        
        default:
            logger.debug("Could not get badge from media item attributess file")
        }
    }
}
