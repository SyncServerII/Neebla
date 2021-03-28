//
//  MediaItemUnreadCount.swift
//  Neebla
//
//  Created by Christopher G Prince on 3/27/21.
//

import Foundation
import iOSShared

protocol MediaItemUnreadCountDelegate: AnyObject {
    var mediaItemUnreadCountBadgeText: String? { get set }
}

class MediaItemUnreadCount {
    let object: ServerObjectModel
    private var observer: AnyObject?
    private var commentFileUUID: UUID!
    var delegate: MediaItemUnreadCountDelegate!
    
    init(object: ServerObjectModel, delegate: MediaItemUnreadCountDelegate) {
        self.object = object
        self.delegate = delegate
        
        do {
            let fileModel = try ServerFileModel.getFileFor(fileLabel: FileLabels.comments, withFileGroupUUID: object.fileGroupUUID)
            commentFileUUID = fileModel.fileUUID
            updateBadge(try object.getCommentsUnreadCount())
        }
        catch let error {
            logger.error("\(error)")
            return
        }
        
        observer = NotificationCenter.default.addObserver(forName: ServerFileModel.unreadCountUpdate, object: nil, queue: nil) { [weak self] notification in
            guard let self = self else { return }
            
            guard let (fileUUID, _) = ServerFileModel.getUUIDs(from: notification), self.commentFileUUID == fileUUID else {
                return
            }
            
            do {
                let badgeCount = try object.getCommentsUnreadCount()
                self.updateBadge(badgeCount)
                logger.debug("Update badge: \(String(describing: badgeCount))")
            } catch let error {
                logger.error("\(error)")
            }
        }
    }
    
    private func updateBadge(_ count:Int?) {
        // Because `unreadCountUpdate` gets posted in some cases from a non-main thread.
        DispatchQueue.main.async {
            if let count = count, count > 0 {
                self.delegate?.mediaItemUnreadCountBadgeText = "\(count)"
            }
            else {
                self.delegate?.mediaItemUnreadCountBadgeText = nil
            }
        }
    }
}

extension MediaItemUnreadCount {
    static func resetUnreadCounts(for objects: [ServerObjectModel]) {
        // Without doing this off the main thread, the UI can be delayed. This results in calls to `postUnreadCountUpdateNotification`, so listeners on those notifications should dispatch to the main queue if updating the UI.
        DispatchQueue.global().async {
            do {
                for object in objects {
                    let commentFileModel = try ServerFileModel.getFileFor(fileLabel: FileLabels.comments, withFileGroupUUID: object.fileGroupUUID)
                    try Comments.resetReadCounts(commentFileModel: commentFileModel)
                }
            } catch let error {
                logger.error("resetUnreadCount: \(error)")
            }
        }
    }
}
