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
    private var observer: AnyObject?
    @Published var badgeText:String?
    let sharingGroupUUID: UUID
    
    init(sharingGroupUUID: UUID) {
        self.sharingGroupUUID = sharingGroupUUID
        
        observer = NotificationCenter.default.addObserver(forName: ServerFileModel.unreadCountUpdate, object: nil, queue: nil) { [weak self] notification in
            guard let self = self else { return }
            
            guard let (_, sharingGroupUUID) = ServerFileModel.getUUIDs(from: notification), self.sharingGroupUUID == sharingGroupUUID else {
                return
            }
            
            self.updateBadge()
        }
        
        updateBadge()
    }
    
    private func updateBadge() {
        do {
            let count = try unreadCountFor(album: self.sharingGroupUUID)

            if count > 0 {
                badgeText = "\(count)"
            }
            else {
                badgeText = nil
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
