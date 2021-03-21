//
//  AnyIconModel.swift
//  Neebla
//
//  Created by Christopher G Prince on 2/7/21.
//

import Foundation
import iOSShared

class AnyIconModel: ObservableObject {
    let object: ServerObjectModel
    @Published var badgeText: String?
    private var observer: AnyObject?
    private var commentFileUUID: UUID!
    
    init(object: ServerObjectModel) {
        self.object = object
        
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
                
                // Because `unreadCountUpdate` gets posted in some cases from a non-main thread.
                DispatchQueue.main.async {
                    self.updateBadge(badgeCount)
                }
                
                logger.debug("Update badge: \(String(describing: badgeCount))")
            } catch let error {
                logger.error("\(error)")
            }
        }
    }
    
    private func updateBadge(_ count:Int?) {
        DispatchQueue.main.async {
            if let count = count, count > 0 {
                self.badgeText = "\(count)"
            }
            else {
                self.badgeText = nil
            }
        }
    }
}
