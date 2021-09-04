//
//  AlbumDownloadIndicator.swift
//  Neebla
//
//  Created by Christopher G Prince on 3/27/21.
//

import Foundation
import iOSShared

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
            
            let sharingGroupUUID = album.sharingGroupUUID
            
            do {
                if let album = try AlbumModel.getAlbumModel(db: Services.session.db, from: notification, expectingSharingGroupUUID: sharingGroupUUID) {
                    
                    logger.debug("album.needsDownload: \(album.needsDownload)")
                    
                    if self.delegate.albumNeedsDownload != album.needsDownload {
                        self.album.needsDownload = album.needsDownload
                        self.delegate.albumNeedsDownload = album.needsDownload
                    }
                }
            } catch let error {
                logger.error("\(error)")
            }
        }
        
        // Trying to deal with crashes. See https://github.com/SyncServerII/Neebla/issues/7 and in particular see https://github.com/SyncServerII/Neebla/issues/7#issuecomment-802978539
        if AppState.session.current == .foreground  {
            let needsDownload = self.album.needsDownload
            
            if self.delegate?.albumNeedsDownload != needsDownload {
                self.delegate?.albumNeedsDownload = needsDownload
            }
        }
    }
}

