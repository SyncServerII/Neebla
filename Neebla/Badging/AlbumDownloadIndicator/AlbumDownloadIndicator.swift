//
//  AlbumDownloadIndicator.swift
//  Neebla
//
//  Created by Christopher G Prince on 3/27/21.
//

import Foundation
import iOSShared
import SQLite

protocol AlbumDownloadIndicatorDelegate: AnyObject {
    // Gets updated when the album `needsDownload` field changes.
    var albumNeedsDownload: Bool { get set }
}

class AlbumDownloadIndicator {
    private var needsDownloadUpdateObserver: AnyObject?
    private var delegate: AlbumDownloadIndicatorDelegate!
    private let album:AlbumModel
    init(album:AlbumModel, delegate: AlbumDownloadIndicatorDelegate) {
        self.delegate = delegate
        self.album = album
        
        needsDownloadUpdateObserver = NotificationCenter.default.addObserver(forName: AlbumModel.needsDownloadUpdate, object: nil, queue: nil) { [weak self] notification in
            guard let self = self else { return }
            
            do {
                let sharingGroupUUID = try AlbumModel.getSharingGroupUUID(db: Services.session.db, from: notification)
                guard sharingGroupUUID == album.sharingGroupUUID else {
                    return
                }

                self.updateBadge(sharingGroupUUID: album.sharingGroupUUID)
            } catch let error {
                logger.error("\(error)")
            }
        }
        
        // Trying to deal with crashes. See https://github.com/SyncServerII/Neebla/issues/7 and in particular see https://github.com/SyncServerII/Neebla/issues/7#issuecomment-802978539
        if AppState.session.current == .foreground  {
            updateBadge(sharingGroupUUID: album.sharingGroupUUID)
        }
    }
    
    // This deals with calls from a non-main thread.
    private func updateBadge(sharingGroupUUID: UUID) {
        do {
            guard let album = try AlbumModel.fetchSingleRow(db: Services.session.db, where: AlbumModel.sharingGroupUUIDField.description == sharingGroupUUID) else {
                logger.error("Could not find album model")
                return
            }
            
            if self.delegate.albumNeedsDownload != album.needsDownload {
                self.album.needsDownload = album.needsDownload

                // Needs to be on main queue-- updates UI.
                DispatchQueue.main.async {
                    self.delegate.albumNeedsDownload = album.needsDownload
                    logger.debug("self.delegate.albumNeedsDownload: \(self.delegate.albumNeedsDownload)")
                }
            }
        }
        catch let error {
            logger.error("\(error)")
        }
    }
}

