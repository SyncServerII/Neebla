//
//  AlbumScreenRowModel.swift
//  Neebla
//
//  Created by Christopher G Prince on 2/7/21.
//

import Foundation
import SQLite
import iOSShared

class AlbumScreenRowModel: ObservableObject {
    private var unreadCountUpdateObserver: AnyObject?
    @Published var badgeText:String?
    @Published var needsDownload: Bool = false
    private var needsDownloadUpdateObserver: AnyObject?
    var album:AlbumModel!
    
    init(album:AlbumModel) {
        self.album = album
        
        unreadCountUpdateObserver = NotificationCenter.default.addObserver(forName: ServerFileModel.unreadCountUpdate, object: nil, queue: nil) { [weak self] notification in
            guard let self = self else { return }
            
            guard let (_, sharingGroupUUID) = ServerFileModel.getUUIDs(from: notification), self.album.sharingGroupUUID == sharingGroupUUID else {
                return
            }
            
            self.updateBadge()
        }
        
        needsDownloadUpdateObserver = NotificationCenter.default.addObserver(forName: AlbumModel.needsDownloadUpdate, object: nil, queue: nil) { [weak self] notification in
            guard let self = self else { return }
            
            do {
                if let album = try AlbumModel.getAlbumModel(db: Services.session.db, from: notification, expectingSharingGroupUUID: album.sharingGroupUUID) {
                    self.album = album
                    if self.needsDownload != album.needsDownload {
                        logger.debug("album.needsDownload: \(album.needsDownload)")
                        self.needsDownload = album.needsDownload
                    }
                }
            } catch let error {
                logger.error("\(error)")
            }
        }
        
        updateBadge()
        
        if needsDownload != album.needsDownload {
            needsDownload = album.needsDownload
        }
    }
    
    private func updateBadge() {
        do {
            let count = try unreadCountFor(album: self.album.sharingGroupUUID)

            var newBadgeText: String?
            
            if count > 0 {
                newBadgeText = "\(count)"
            }
            else {
                newBadgeText = nil
            }
            
            if self.badgeText != newBadgeText {
                DispatchQueue.main.async {
                    self.badgeText = newBadgeText
                }
            }
        }
        catch let error {
            logger.error("\(error)")
        }
    }
    
    func unreadCountFor(album sharingGroupUUID: UUID) throws -> Int {
        // 1) Get the file groups for the album.
        let objectModels = try ServerObjectModel.fetch(db: Services.session.db, where: ServerObjectModel.sharingGroupUUIDField.description == sharingGroupUUID)
        let fileGroups = objectModels.map {$0.fileGroupUUID}

        // 2) Get the comment files for each file group and add their unread counts into tally
        var unreadCount = 0
        for fileGroup in fileGroups {
            let fileModel = try ServerFileModel.fetchSingleRow(db: Services.session.db, where: ServerFileModel.fileGroupUUIDField.description == fileGroup && ServerFileModel.fileLabelField.description == FileLabels.comments)
            if let count = fileModel?.unreadCount {
                unreadCount += count
            }
        }
        
        return unreadCount
    }
}
