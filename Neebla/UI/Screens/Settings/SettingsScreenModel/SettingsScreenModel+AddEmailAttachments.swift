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

            if let serverFileModels = try ServerFileModel.debug(option: .onlyMissingFiles, db: Services.session.db) {
                logger.notice("Missing ServerFileModel's: \(String(describing: serverFileModels))")
            }
            else {
                logger.notice("No Missing ServerFileModel's")
            }
            
            let specificFileUUIDs:Set<UUID> = [
                UUID(uuidString: "5E0531A2-6E86-435E-859B-D4A13F3C7F54")!,
                UUID(uuidString: "B22449D3-BCAB-4E93-8B4A-74DCFC2E6C34")!,
                UUID(uuidString: "C0F990AD-8E46-46AE-A97B-3D3270F0EF78")!,
                UUID(uuidString: "75C95CC9-BF03-4B1D-AD2D-C5B1BE30AD11")!,
            ]
            
            // This is specific to a problem around 8/13/21 and can be removed later.
            if let specificServerFileModels = try ServerFileModel.debug(option: .specificFiles(fileUUIDs: specificFileUUIDs), db: Services.session.db) {
                logger.notice("SpecificServerFileModel's: \(String(describing: specificServerFileModels))")
            }
            else {
                logger.notice("No SpecificServerFileModel's")
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
