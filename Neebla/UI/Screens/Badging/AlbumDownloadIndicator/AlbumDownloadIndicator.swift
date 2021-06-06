//
//  AlbumDownloadIndicator.swift
//  Neebla
//
//  Created by Christopher G Prince on 3/27/21.
//

import Foundation
import iOSShared

protocol AlbumDownloadIndicatorDelegate: AnyObject {
    // These get updated when its `needsDownload` field changes.
    var album: AlbumModel? { get set }
    var albumNeedsDownload: Bool { get set }
}

class AlbumDownloadIndicator {
    private var needsDownloadUpdateObserver: AnyObject?
    private var delegate: AlbumDownloadIndicatorDelegate!
    
    init(delegate: AlbumDownloadIndicatorDelegate) {
        self.delegate = delegate
        
        needsDownloadUpdateObserver = NotificationCenter.default.addObserver(forName: AlbumModel.needsDownloadUpdate, object: nil, queue: nil) { [weak self] notification in
            guard let self = self else { return }
            
            guard let sharingGroupUUID = delegate.album?.sharingGroupUUID else {
                return
            }
            
            do {
                if let album = try AlbumModel.getAlbumModel(db: Services.session.db, from: notification, expectingSharingGroupUUID: sharingGroupUUID) {
                    
                    logger.debug("album.needsDownload: \(album.needsDownload)")
                    
                    if self.delegate.albumNeedsDownload != album.needsDownload {
                        self.delegate.album = album
                        self.delegate.albumNeedsDownload = album.needsDownload
                    }
                }
            } catch let error {
                logger.error("\(error)")
            }
        }
        
        // Trying to deal with crashes. See https://github.com/SyncServerII/Neebla/issues/7 and in particular see https://github.com/SyncServerII/Neebla/issues/7#issuecomment-802978539
        if AppState.session.current == .foreground  {
            guard let needsDownload = self.delegate.album?.needsDownload else {
                return
            }
            
            if self.delegate?.albumNeedsDownload != needsDownload {
                self.delegate?.albumNeedsDownload = needsDownload
            }
        }
    }
}

