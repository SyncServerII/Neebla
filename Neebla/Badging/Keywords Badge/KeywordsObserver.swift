//
//  KeywordsObserver.swift
//  Neebla
//
//  Created by Christopher G Prince on 7/2/21.
//

import Foundation
import iOSShared

protocol KeywordsObserverDelegate: AnyObject {
    var haveKeywords: Bool { get set }
}

class KeywordsObserver {
    let object: ServerObjectModel
    private var observer: AnyObject?
    weak var delegate: KeywordsObserverDelegate!
    
    init(object: ServerObjectModel, delegate: KeywordsObserverDelegate?) {
        self.object = object
        self.delegate = delegate
        
        delegate?.haveKeywords = haveKeywords(object.keywords)
        
        observer = NotificationCenter.default.addObserver(forName: ServerObjectModel.keywordsUpdate, object: nil, queue: nil) { [weak self] notification in
            guard let self = self else { return }
            
            guard let (fileGroupUUID, keywords) = ServerObjectModel.getKeywordInfo(from: notification) else {
                return
            }
            
            guard self.object.fileGroupUUID == fileGroupUUID else {
                return
            }
            
            DispatchQueue.main.async {
                delegate?.haveKeywords = self.haveKeywords(keywords)
            }
        }
    }
    
    func haveKeywords(_ keywords: String?) -> Bool {
        guard let keywords = keywords else {
            return false
        }
        
        return keywords.count > 0
    }
}
