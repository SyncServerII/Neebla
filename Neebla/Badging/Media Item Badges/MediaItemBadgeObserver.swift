//
//  MediaItemBadgeObserver.swift
//  Neebla
//
//  Created by Christopher G Prince on 6/18/21.
//

import Foundation
import iOSShared

protocol MediaItemBadgeObserverDelegate: AnyObject {
    var mediaItemBadge: MediaItemBadge? { get set }
}

class MediaItemBadgeObserver {
    let object: ServerObjectModel
    private var observer: AnyObject?
    private var mediaItemAttributesFileUUID: UUID!
    var delegate: MediaItemBadgeObserverDelegate!
    
    init(object: ServerObjectModel, delegate: MediaItemBadgeObserverDelegate) {
        self.object = object
        self.delegate = delegate
        
        do {
            let fileModel = try ServerFileModel.getFileFor(fileLabel: FileLabels.mediaItemAttributes, withFileGroupUUID: object.fileGroupUUID)
            mediaItemAttributesFileUUID = fileModel.fileUUID
            delegate.mediaItemBadge = fileModel.badge
        }
        catch let error {
            logger.error("\(error)")
            return
        }
        
        observer = NotificationCenter.default.addObserver(forName: ServerFileModel.badgeUpdate, object: nil, queue: nil) { [weak self] notification in
            guard let self = self else { return }
            
            guard let (fileUUID, _) = ServerFileModel.getUUIDs(from: notification), self.mediaItemAttributesFileUUID == fileUUID else {
                return
            }
            
            do {
                let fileModel = try ServerFileModel.getFileFor(fileLabel: FileLabels.mediaItemAttributes, withFileGroupUUID: object.fileGroupUUID)
                self.updateBadge(fileModel.badge)
            } catch let error {
                logger.error("\(error)")
            }
        }
    }
    
    private func updateBadge(_ badge: MediaItemBadge?) {
        // Because `badgeUpdate` gets posted in some cases from a non-main thread.
        DispatchQueue.main.async {
            if badge != self.delegate?.mediaItemBadge {
                self.delegate?.mediaItemBadge = badge
            }
        }
    }
}
