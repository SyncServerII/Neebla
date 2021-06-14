//
//  AlbumUnreadCount.swift
//  Neebla
//
//  Created by Christopher G Prince on 3/27/21.
//

import Foundation
import iOSShared
import SQLite

protocol AlbumUnreadCountDelegate: AnyObject {
    // Updates on main thread
    var albumUnreadCountBadgeText: String? { get set }
}

class AlbumUnreadCount {
    private var unreadCountUpdateObserver: AnyObject?
    let album:AlbumModel
    var delegate: AlbumUnreadCountDelegate!
    
    init(album:AlbumModel, delegate: AlbumUnreadCountDelegate) {
        self.album = album
        self.delegate = delegate
        
        unreadCountUpdateObserver = NotificationCenter.default.addObserver(forName: ServerFileModel.unreadCountUpdate, object: nil, queue: nil) { [weak self] notification in
            guard let self = self else { return }
            
            // History in this segment of code:
            // 1) I tried to use `backgroundAsssertable` to deal with crashes. See https://github.com/SyncServerII/Neebla/issues/7 and in particular see https://github.com/SyncServerII/Neebla/issues/7#issuecomment-802978539
            // i.e.,
            // try? Background.session.backgroundAsssertable.syncRun { [weak self] in
            // That didn't work. I wonder if this is just crashing if it happens purely in the background because `updateBadge` does a lot of work. I'm adding another fix: Not sending `unreadCountUpdate` notifications when the app is in the background.
            // 2) I removed this `backgroundAsssertable` because it had been causing another issue: When I reset unread counts in the Albums screen it caused the UI to hang. My guess is that despite the fact that `backgroundAsssertable` runs in background thread, these `backgroundAsssertable` do synchronous work on the main thread.
                
            guard let (_, sharingGroupUUID) = ServerFileModel.getUUIDs(from: notification), self.album.sharingGroupUUID == sharingGroupUUID else {
                return
            }
            
            self.updateBadge()
        }
        
        // Trying to deal with crashes. See https://github.com/SyncServerII/Neebla/issues/7 and in particular see https://github.com/SyncServerII/Neebla/issues/7#issuecomment-802978539
        if AppState.session.current == .foreground  {
            updateBadge()
        }
    }
    
    // This deals with calls from a non-main thread.
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
            
            if self.delegate?.albumUnreadCountBadgeText != newBadgeText {
                DispatchQueue.main.async {
                    self.delegate?.albumUnreadCountBadgeText = newBadgeText
                }
            }
        }
        catch let error {
            logger.error("\(error)")
        }
    }
    
    func unreadCountFor(album sharingGroupUUID: UUID) throws -> Int {
        // 1) Get the file groups for the album. Make sure those are not deleted.
        let objectModels = try ServerObjectModel.fetch(db: Services.session.db, where:
            ServerObjectModel.sharingGroupUUIDField.description == sharingGroupUUID &&
            ServerObjectModel.deletedField.description == false)
        let fileGroups = objectModels.map {$0.fileGroupUUID}

        // 2) Get the comment files for each file group and add their unread counts into tally
        var unreadCount = 0
        for fileGroup in fileGroups {
            let fileModel = try ServerFileModel.fetchSingleRow(db: Services.session.db, where:
                ServerFileModel.fileGroupUUIDField.description == fileGroup &&
                ServerFileModel.fileLabelField.description == FileLabels.comments)
            
            if let count = fileModel?.unreadCount {
                unreadCount += count
            }
        }
        
        return unreadCount
    }
}
