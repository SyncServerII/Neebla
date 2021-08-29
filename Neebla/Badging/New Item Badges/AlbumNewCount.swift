//
//  AlbumNewCount.swift
//  Neebla
//
//  Created by Christopher G Prince on 8/28/21.
//

import Foundation
import iOSShared
import SQLite

protocol AlbumNewCountDelegate: AnyObject {
    // Updates on main thread
    var albumNewCountBadgeText: String? { get set }
}

class AlbumNewCount {
    private var newCountUpdateObserver: AnyObject?
    let album:AlbumModel
    var delegate: AlbumNewCountDelegate!
    
    init(album:AlbumModel, delegate: AlbumNewCountDelegate) {
        self.album = album
        self.delegate = delegate
        
        newCountUpdateObserver = NotificationCenter.default.addObserver(forName: ServerObjectModel.newUpdate, object: nil, queue: nil) { [weak self] notification in
            guard let self = self else { return }
                
            guard let fileGroupUUID = ServerObjectModel.getFileGroupUUID(from: notification) else {
                return
            }
            
            guard let objectModel = try? ServerObjectModel.fetchSingleRow(db: album.db, where: ServerObjectModel.fileGroupUUIDField.description == fileGroupUUID) else {
                return
            }
            
            guard objectModel.sharingGroupUUID == album.sharingGroupUUID else {
                return
            }
            
            self.updateBadge()
        }
        
        if AppState.session.current == .foreground  {
            updateBadge()
        }
    }
    
    // This deals with calls from a non-main thread.
    private func updateBadge() {
        do {
            
            let count = try newCountFor(album: self.album.sharingGroupUUID)

            var newBadgeText: String?
            
            if count > 0 {
                newBadgeText = "\(count)"
            }
            else {
                newBadgeText = nil
            }
            
            if self.delegate?.albumNewCountBadgeText != newBadgeText {
                DispatchQueue.main.async {
                    self.delegate?.albumNewCountBadgeText = newBadgeText
                }
            }
        }
        catch let error {
            logger.error("\(error)")
        }
    }
    
    private func newCountFor(album sharingGroupUUID: UUID) throws -> Int {
        let newObjectModels = try ServerObjectModel.fetch(db: Services.session.db, where:
            ServerObjectModel.sharingGroupUUIDField.description == sharingGroupUUID &&
            ServerObjectModel.deletedField.description == false &&
            ServerObjectModel.newField.description)
        return newObjectModels.count
    }
}
