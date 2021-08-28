//
//  NewItemBadgeObserver.swift
//  Neebla
//
//  Created by Christopher G Prince on 8/27/21.
//

import Foundation
import iOSShared
import SQLite

protocol NewItemBadgeObserverDelegate: AnyObject {
    var newItem: Bool { get set }
}

class NewItemBadgeObserver {
    let object: ServerObjectModel
    private var observer: AnyObject?
    weak var delegate: NewItemBadgeObserverDelegate!
    
    init(object: ServerObjectModel, delegate: NewItemBadgeObserverDelegate) {
        self.object = object
        self.delegate = delegate
        
        delegate.newItem = object.new

        // Only need to add the observer if the object is not new
        guard !object.new else {
            return
        }
        
        observer = NotificationCenter.default.addObserver(forName: ServerObjectModel.newUpdate, object: nil, queue: nil) { [weak self] notification in
            guard let self = self else { return }
            
            guard let fileGroupUUID = ServerObjectModel.getFileGroupUUID(from: notification) else {
                return
            }
            
            guard fileGroupUUID == object.fileGroupUUID else {
                return
            }
            
            DispatchQueue.main.async {
                object.new = false
                if object.new != self.delegate?.newItem {
                    self.delegate?.newItem = object.new
                }
            }
        }
    }
}

