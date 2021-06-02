//
//  AlbumDownloadIndicator.swift
//  Neebla
//
//  Created by Christopher G Prince on 3/27/21.
//

import Foundation
import iOSShared

protocol AlbumDownloadIndicatorDelegate: AnyObject {
    var albumNeedsDownload: Bool { get set }
}

class AlbumDownloadIndicator {
    private var needsDownloadUpdateObserver: AnyObject?
    private var album: AlbumModel
    private var delegate: AlbumDownloadIndicatorDelegate!
    
    init(album: AlbumModel, delegate: AlbumDownloadIndicatorDelegate) {
        self.album = album
        self.delegate = delegate
        
        needsDownloadUpdateObserver = NotificationCenter.default.addObserver(forName: AlbumModel.needsDownloadUpdate, object: nil, queue: nil) { [weak self] notification in
            guard let self = self else { return }
            
            do {
                if let album = try AlbumModel.getAlbumModel(db: Services.session.db, from: notification, expectingSharingGroupUUID: album.sharingGroupUUID) {
                    self.album = album
                    logger.debug("album.needsDownload: \(album.needsDownload)")
                    if self.delegate?.albumNeedsDownload != album.needsDownload {
                        self.delegate?.albumNeedsDownload = album.needsDownload
                    }
                }
            } catch let error {
                logger.error("\(error)")
            }
        }
        
        // Trying to deal with crashes. See https://github.com/SyncServerII/Neebla/issues/7 and in particular see https://github.com/SyncServerII/Neebla/issues/7#issuecomment-802978539
        if AppState.session.current == .foreground  {
            if self.delegate?.albumNeedsDownload != album.needsDownload {
                self.delegate?.albumNeedsDownload = album.needsDownload
            }
        }
    }
}

