//
//  SettingsScreenModel+AddEmailAttachments.swift
//  Neebla
//
//  Created by Christopher G Prince on 8/10/21.
//

import Foundation
import MessageUI
import iOSShared

extension SettingsScreenModel: AddEmailAttachments {
    func addAttachments(vc: MFMailComposeViewController) {
        // Logging these as `notice` to make sure they hit the logs for production builds.
        logger.notice("Email attachments:")
        do {
            let number = try LocalFiles.numberOfFilesInObjectsDir()
            logger.notice("NumberOfFilesInObjectsDir: \(number)")

            if let pendingDownloads = try Services.session.syncServer.debugPendingDownloads() {
                logger.notice("Pending Downloads: \(pendingDownloads)")
            }
            else {
                logger.notice("No Pending Downloads.")
            }

            if let serverFileModels = try ServerFileModel.debug(option: .onlyUnreadableFiles, db: Services.session.db) {
                logger.notice("Missing ServerFileModel's: \(String(describing: serverFileModels))")
            }
            else {
                logger.notice("No Missing ServerFileModel's")
            }

            if let pendingDeletions = try Services.session.syncServer.debugPendingDeletions() {
                logger.notice("Pending Deletions: \(String(describing: pendingDeletions))")
            }
            else {
                logger.notice("No Pending Deletions")
            }
            
            if let pendingUploads = try Services.session.syncServer.debugPendingUploads() {
                logger.notice("Pending Uploads: \(String(describing: pendingUploads))")
            }
            else {
                logger.notice("No Pending Uploads")
            }
            
            logger.notice("Albums:")
            let albums = try AlbumModel.fetch(db: Services.session.db)
            for album in albums {
                logger.notice("Album: sharingGroupUUID: \(album.sharingGroupUUID); name: \(String(describing: album.albumName)); deleted: \(album.deleted)")
            }
        } catch let error {
            logger.error("\(error)")
        }
        
        let archivedFileURLs = sharedLogging.archivedFileURLs
        guard archivedFileURLs.count > 0 else {
            return
        }
        
        for logFileURL in archivedFileURLs {
            guard let logFileData = try? Data(contentsOf: logFileURL, options: NSData.ReadingOptions()) else {
                continue
            }
            
            let fileName = logFileURL.lastPathComponent
            vc.addAttachmentData(logFileData, mimeType: "text/plain", fileName: fileName)
        }
    }
}
